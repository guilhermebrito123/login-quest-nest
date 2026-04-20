-- ============================================================
-- 1. Função: status do checklist permite o RESPONSÁVEL alterar?
-- ============================================================
CREATE OR REPLACE FUNCTION public.checklist_instance_allows_kanban_edit(
  _instance_status public.checklist_instance_status
)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  SELECT _instance_status IN ('open', 'in_progress')
$$;

-- ============================================================
-- 2. Função: usuário pode alterar status kanban da tarefa?
--    - responsável ativo (pode_alterar_status=true) com checklist em open/in_progress
--    - supervisor do cost_center do checklist (qualquer status)
--    - admin (qualquer status)
-- ============================================================
CREATE OR REPLACE FUNCTION public.can_change_checklist_task_kanban(
  _user_id uuid,
  _instancia_tarefa_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_instance_status public.checklist_instance_status;
  v_cost_center_id uuid;
  v_is_responsavel boolean := false;
BEGIN
  SELECT ci.status, ci.cost_center_id
    INTO v_instance_status, v_cost_center_id
  FROM public.checklist_instancia_tarefas cit
  JOIN public.checklist_instancias ci ON ci.id = cit.checklist_instancia_id
  WHERE cit.id = _instancia_tarefa_id;

  IF v_instance_status IS NULL THEN
    RETURN false;
  END IF;

  -- admin: sempre
  IF public.module_is_admin(_user_id) THEN
    RETURN true;
  END IF;

  -- supervisor do cost_center: sempre
  IF public.module_supervisor_has_cost_center(_user_id, v_cost_center_id) THEN
    RETURN true;
  END IF;

  -- responsável ativo: somente se checklist permite edição
  SELECT EXISTS (
    SELECT 1
    FROM public.checklist_tarefa_responsaveis r
    WHERE r.checklist_instancia_tarefa_id = _instancia_tarefa_id
      AND r.assigned_user_id = _user_id
      AND r.ativo = true
      AND r.pode_alterar_status = true
  ) INTO v_is_responsavel;

  IF v_is_responsavel AND public.checklist_instance_allows_kanban_edit(v_instance_status) THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$;

-- ============================================================
-- 3. RLS para checklist_tarefa_responsaveis (UPDATE de status_kanban)
-- ============================================================

-- Remove policies antigas que possam interferir
DROP POLICY IF EXISTS "responsaveis_update_kanban" ON public.checklist_tarefa_responsaveis;

CREATE POLICY "responsaveis_update_kanban"
ON public.checklist_tarefa_responsaveis
FOR UPDATE
USING (
  public.can_change_checklist_task_kanban(auth.uid(), checklist_instancia_tarefa_id)
)
WITH CHECK (
  public.can_change_checklist_task_kanban(auth.uid(), checklist_instancia_tarefa_id)
);

-- ============================================================
-- 4. RLS para checklist_tarefa_status_historico (INSERT)
-- ============================================================
DROP POLICY IF EXISTS "historico_kanban_insert" ON public.checklist_tarefa_status_historico;

CREATE POLICY "historico_kanban_insert"
ON public.checklist_tarefa_status_historico
FOR INSERT
WITH CHECK (
  changed_by_user_id = auth.uid()
  AND public.can_change_checklist_task_kanban(auth.uid(), checklist_instancia_tarefa_id)
);

-- ============================================================
-- 5. Trigger: validar mudança de status_kanban no UPDATE
--    (defesa adicional além do RLS) + registrar histórico automaticamente
-- ============================================================
CREATE OR REPLACE FUNCTION public.trg_validate_kanban_status_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor uuid := auth.uid();
BEGIN
  IF NEW.status_kanban IS DISTINCT FROM OLD.status_kanban THEN
    -- bypass quando vier de processo do sistema (cron, função interna)
    IF current_setting('app.rpc_call', true) IS DISTINCT FROM 'system' THEN
      IF v_actor IS NULL OR NOT public.can_change_checklist_task_kanban(v_actor, NEW.checklist_instancia_tarefa_id) THEN
        RAISE EXCEPTION 'Usuário não autorizado a alterar o status kanban desta tarefa (checklist precisa estar em andamento)';
      END IF;
    END IF;

    -- registra histórico
    INSERT INTO public.checklist_tarefa_status_historico (
      checklist_instancia_tarefa_id,
      assigned_user_id,
      changed_by_user_id,
      status_anterior,
      status_novo,
      motivo
    ) VALUES (
      NEW.checklist_instancia_tarefa_id,
      NEW.assigned_user_id,
      COALESCE(v_actor, NEW.assigned_by_user_id),
      OLD.status_kanban,
      NEW.status_kanban,
      CASE WHEN current_setting('app.rpc_call', true) = 'system'
        THEN 'Atualização automática pelo sistema'
        ELSE NULL
      END
    );

    -- timestamps de conclusão
    IF NEW.status_kanban = 'done' AND OLD.status_kanban <> 'done' THEN
      NEW.concluida_em := now();
    ELSIF NEW.status_kanban <> 'done' AND OLD.status_kanban = 'done' THEN
      NEW.concluida_em := NULL;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_kanban_status_change ON public.checklist_tarefa_responsaveis;
CREATE TRIGGER trg_validate_kanban_status_change
BEFORE UPDATE ON public.checklist_tarefa_responsaveis
FOR EACH ROW
EXECUTE FUNCTION public.trg_validate_kanban_status_change();

-- ============================================================
-- 6. Trigger: ao mudar status do checklist para "não editável",
--    fechar tarefas pendentes/em andamento/bloqueadas
-- ============================================================
CREATE OR REPLACE FUNCTION public.trg_close_kanban_on_instance_lock()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_was_editable boolean;
  v_is_editable boolean;
BEGIN
  v_was_editable := public.checklist_instance_allows_kanban_edit(OLD.status);
  v_is_editable  := public.checklist_instance_allows_kanban_edit(NEW.status);

  IF v_was_editable AND NOT v_is_editable THEN
    -- marca tudo que ainda não está concluído como 'closed'
    PERFORM set_config('app.rpc_call', 'system', true);

    UPDATE public.checklist_tarefa_responsaveis r
    SET status_kanban = 'closed'::public.checklist_task_kanban_status
    WHERE r.checklist_instancia_tarefa_id IN (
      SELECT cit.id
      FROM public.checklist_instancia_tarefas cit
      WHERE cit.checklist_instancia_id = NEW.id
    )
    AND r.status_kanban IN ('pending', 'doing', 'blocked');

    PERFORM set_config('app.rpc_call', '', true);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_close_kanban_on_instance_lock ON public.checklist_instancias;
CREATE TRIGGER trg_close_kanban_on_instance_lock
AFTER UPDATE OF status ON public.checklist_instancias
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION public.trg_close_kanban_on_instance_lock();

-- ============================================================
-- 7. Trigger: avaliação por tarefa gera feedback automático
--    para cada responsável ativo (mensagem com decisão/nota)
-- ============================================================
CREATE OR REPLACE FUNCTION public.trg_feedback_on_avaliacao_item()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_avaliador uuid;
  v_titulo_tarefa text;
  v_decisao_label text;
  v_mensagem text;
BEGIN
  SELECT a.avaliado_por_user_id
    INTO v_avaliador
  FROM public.checklist_avaliacoes a
  WHERE a.id = NEW.checklist_avaliacao_id;

  SELECT cit.titulo_snapshot
    INTO v_titulo_tarefa
  FROM public.checklist_instancia_tarefas cit
  WHERE cit.id = NEW.checklist_instancia_tarefa_id;

  v_decisao_label := CASE NEW.resultado_conformidade
    WHEN 'conforme' THEN 'Conforme'
    WHEN 'nao_conforme' THEN 'Não conforme'
    WHEN 'nao_aplicavel' THEN 'Não aplicável'
    ELSE NEW.resultado_conformidade
  END;

  v_mensagem := format(
    'Avaliação da tarefa "%s": %s%s%s',
    v_titulo_tarefa,
    v_decisao_label,
    CASE WHEN NEW.nota IS NOT NULL THEN format(E'\nNota: %s', NEW.nota::text) ELSE '' END,
    CASE WHEN NEW.feedback IS NOT NULL AND length(trim(NEW.feedback)) > 0
         THEN format(E'\nFeedback: %s', NEW.feedback)
         ELSE ''
    END
  );

  -- cria um feedback para cada responsável ativo da tarefa
  INSERT INTO public.checklist_feedbacks (
    checklist_instancia_tarefa_id,
    checklist_avaliacao_item_id,
    autor_user_id,
    destinatario_user_id,
    mensagem
  )
  SELECT
    NEW.checklist_instancia_tarefa_id,
    NEW.id,
    COALESCE(v_avaliador, NEW.checklist_avaliacao_id),
    r.assigned_user_id,
    v_mensagem
  FROM public.checklist_tarefa_responsaveis r
  WHERE r.checklist_instancia_tarefa_id = NEW.checklist_instancia_tarefa_id
    AND r.ativo = true;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_feedback_on_avaliacao_item ON public.checklist_avaliacao_itens;
CREATE TRIGGER trg_feedback_on_avaliacao_item
AFTER INSERT ON public.checklist_avaliacao_itens
FOR EACH ROW
EXECUTE FUNCTION public.trg_feedback_on_avaliacao_item();

-- ============================================================
-- 8. Índice de apoio para feedback (não-cientes por destinatário)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_checklist_feedbacks_destinatario_ciente
  ON public.checklist_feedbacks(destinatario_user_id, ciente);