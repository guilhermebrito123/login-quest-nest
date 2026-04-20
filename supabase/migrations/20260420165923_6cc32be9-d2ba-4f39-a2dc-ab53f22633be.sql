-- =============================================================
-- MEMBROS DE EQUIPE + AUTO-ATRIBUIÇÃO EM CHECKLISTS
-- =============================================================

-- 1) Tabela de membros da equipe -------------------------------
CREATE TABLE public.module_equipe_membros (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  equipe_id uuid NOT NULL REFERENCES public.module_equipes(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  cost_center_id uuid NOT NULL REFERENCES public.cost_center(id),
  added_by_user_id uuid NOT NULL REFERENCES public.usuarios(id),
  ativo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (equipe_id, user_id)
);

CREATE INDEX idx_module_equipe_membros_equipe ON public.module_equipe_membros(equipe_id) WHERE ativo;
CREATE INDEX idx_module_equipe_membros_user ON public.module_equipe_membros(user_id) WHERE ativo;
CREATE INDEX idx_module_equipe_membros_cc ON public.module_equipe_membros(cost_center_id);

CREATE TRIGGER trg_module_equipe_membros_updated
  BEFORE UPDATE ON public.module_equipe_membros
  FOR EACH ROW EXECUTE FUNCTION public.module_set_updated_at();

-- 2) Validação: membro DEVE ser colaborador e do cost_center vinculado à equipe
CREATE OR REPLACE FUNCTION public.validar_membro_equipe()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _user_role public.user_type;
  _colab_cc uuid;
  _equipe_tem_cc boolean;
BEGIN
  -- 2.1 Usuário precisa ter role = colaborador
  SELECT role INTO _user_role FROM public.usuarios WHERE id = NEW.user_id;
  IF _user_role IS DISTINCT FROM 'colaborador'::public.user_type THEN
    RAISE EXCEPTION 'Apenas usuários com role colaborador podem ser membros de equipe (user_id=%)', NEW.user_id
      USING ERRCODE = '23514';
  END IF;

  -- 2.2 Cost center do colaborador deve bater com o NEW.cost_center_id
  SELECT cost_center_id INTO _colab_cc
  FROM public.colaborador_profiles
  WHERE user_id = NEW.user_id AND ativo = true;

  IF _colab_cc IS NULL THEN
    RAISE EXCEPTION 'Colaborador % não possui colaborador_profile ativo', NEW.user_id
      USING ERRCODE = '23514';
  END IF;

  IF _colab_cc <> NEW.cost_center_id THEN
    RAISE EXCEPTION 'Cost center informado (%) não corresponde ao cost center do colaborador (%)',
      NEW.cost_center_id, _colab_cc
      USING ERRCODE = '23514';
  END IF;

  -- 2.3 A equipe precisa estar vinculada a esse cost_center
  SELECT EXISTS (
    SELECT 1 FROM public.module_equipe_cost_centers
    WHERE equipe_id = NEW.equipe_id AND cost_center_id = NEW.cost_center_id
  ) INTO _equipe_tem_cc;

  IF NOT _equipe_tem_cc THEN
    RAISE EXCEPTION 'Equipe % não está vinculada ao cost center %', NEW.equipe_id, NEW.cost_center_id
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validar_membro_equipe
  BEFORE INSERT OR UPDATE OF user_id, cost_center_id, equipe_id
  ON public.module_equipe_membros
  FOR EACH ROW EXECUTE FUNCTION public.validar_membro_equipe();

-- 3) RLS ------------------------------------------------------
ALTER TABLE public.module_equipe_membros ENABLE ROW LEVEL SECURITY;

CREATE POLICY equipe_membros_select ON public.module_equipe_membros
  FOR SELECT TO authenticated
  USING (public.module_user_allowed(auth.uid()));

CREATE POLICY equipe_membros_insert ON public.module_equipe_membros
  FOR INSERT TO authenticated
  WITH CHECK (
    added_by_user_id = auth.uid() AND (
      public.module_is_admin(auth.uid())
      OR public.module_supervisor_has_cost_center(auth.uid(), cost_center_id)
    )
  );

CREATE POLICY equipe_membros_update ON public.module_equipe_membros
  FOR UPDATE TO authenticated
  USING (
    public.module_is_admin(auth.uid())
    OR public.module_supervisor_has_cost_center(auth.uid(), cost_center_id)
  )
  WITH CHECK (
    public.module_is_admin(auth.uid())
    OR public.module_supervisor_has_cost_center(auth.uid(), cost_center_id)
  );

CREATE POLICY equipe_membros_delete ON public.module_equipe_membros
  FOR DELETE TO authenticated
  USING (
    public.module_is_admin(auth.uid())
    OR public.module_supervisor_has_cost_center(auth.uid(), cost_center_id)
  );

-- 4) Auto-atribuir membros da equipe como responsáveis ao criar instância
CREATE OR REPLACE FUNCTION public.auto_atribuir_membros_equipe_checklist()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _actor uuid := COALESCE(auth.uid(), NEW.criado_por_user_id);
BEGIN
  -- Para cada tarefa da nova instância, atribui todos os membros ativos da equipe
  INSERT INTO public.checklist_tarefa_responsaveis (
    checklist_instancia_tarefa_id,
    assigned_user_id,
    assigned_by_user_id,
    pode_alterar_status,
    ativo,
    status_kanban
  )
  SELECT
    cit.id,
    mem.user_id,
    _actor,
    true,
    true,
    'pending'::public.checklist_task_kanban_status
  FROM public.checklist_instancia_tarefas cit
  CROSS JOIN public.module_equipe_membros mem
  WHERE cit.checklist_instancia_id = NEW.id
    AND mem.equipe_id = NEW.equipe_responsavel_id
    AND mem.ativo = true
  ON CONFLICT (checklist_instancia_tarefa_id, assigned_user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Dispara DEPOIS que as tarefas da instância já foram criadas (assumindo trigger separado).
-- Se o fluxo cria instância → tarefas no mesmo statement, atribuição roda manualmente
-- após inserção de tarefas; aqui usamos AFTER INSERT na instância e também AFTER INSERT
-- nas tarefas (para o caso comum em que tarefas vêm depois).
CREATE TRIGGER trg_auto_atribuir_membros_apos_instancia
  AFTER INSERT ON public.checklist_instancias
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_atribuir_membros_equipe_checklist();

-- Garantir cobertura mesmo quando tarefas são criadas após a instância:
CREATE OR REPLACE FUNCTION public.auto_atribuir_membros_em_nova_tarefa()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _equipe uuid;
  _criador uuid;
BEGIN
  SELECT equipe_responsavel_id, criado_por_user_id
    INTO _equipe, _criador
  FROM public.checklist_instancias
  WHERE id = NEW.checklist_instancia_id;

  IF _equipe IS NULL THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.checklist_tarefa_responsaveis (
    checklist_instancia_tarefa_id,
    assigned_user_id,
    assigned_by_user_id,
    pode_alterar_status,
    ativo,
    status_kanban
  )
  SELECT
    NEW.id,
    mem.user_id,
    COALESCE(auth.uid(), _criador),
    true,
    true,
    'pending'::public.checklist_task_kanban_status
  FROM public.module_equipe_membros mem
  WHERE mem.equipe_id = _equipe
    AND mem.ativo = true
  ON CONFLICT (checklist_instancia_tarefa_id, assigned_user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_auto_atribuir_membros_nova_tarefa
  AFTER INSERT ON public.checklist_instancia_tarefas
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_atribuir_membros_em_nova_tarefa();

-- 5) Substituir responsáveis quando equipe da INSTÂNCIA muda
-- Regra: remove (soft-delete: ativo=false) responsáveis que vieram da equipe ANTIGA
-- e que NÃO estejam na nova; insere os novos membros.
-- Atribuições manuais (responsáveis que nunca foram membros da equipe antiga) são preservadas.
CREATE OR REPLACE FUNCTION public.sincronizar_responsaveis_em_troca_equipe()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _actor uuid := COALESCE(auth.uid(), NEW.criado_por_user_id);
BEGIN
  IF NEW.equipe_responsavel_id IS NOT DISTINCT FROM OLD.equipe_responsavel_id THEN
    RETURN NEW;
  END IF;

  -- 5.1 Soft-delete: desativar responsáveis ATIVOS desta instância cujo user_id
  -- pertencia à equipe antiga (e não pertence à nova)
  UPDATE public.checklist_tarefa_responsaveis r
     SET ativo = false
   WHERE r.ativo = true
     AND r.checklist_instancia_tarefa_id IN (
       SELECT id FROM public.checklist_instancia_tarefas
       WHERE checklist_instancia_id = NEW.id
     )
     AND r.assigned_user_id IN (
       SELECT user_id FROM public.module_equipe_membros
       WHERE equipe_id = OLD.equipe_responsavel_id AND ativo = true
     )
     AND r.assigned_user_id NOT IN (
       SELECT user_id FROM public.module_equipe_membros
       WHERE equipe_id = NEW.equipe_responsavel_id AND ativo = true
     );

  -- 5.2 Inserir novos membros como responsáveis em todas as tarefas
  INSERT INTO public.checklist_tarefa_responsaveis (
    checklist_instancia_tarefa_id,
    assigned_user_id,
    assigned_by_user_id,
    pode_alterar_status,
    ativo,
    status_kanban
  )
  SELECT
    cit.id,
    mem.user_id,
    _actor,
    true,
    true,
    'pending'::public.checklist_task_kanban_status
  FROM public.checklist_instancia_tarefas cit
  CROSS JOIN public.module_equipe_membros mem
  WHERE cit.checklist_instancia_id = NEW.id
    AND mem.equipe_id = NEW.equipe_responsavel_id
    AND mem.ativo = true
  ON CONFLICT (checklist_instancia_tarefa_id, assigned_user_id)
  DO UPDATE SET ativo = true,  -- reativa caso já existisse desativado
                assigned_by_user_id = EXCLUDED.assigned_by_user_id;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sincronizar_responsaveis_troca_equipe
  AFTER UPDATE OF equipe_responsavel_id ON public.checklist_instancias
  FOR EACH ROW
  EXECUTE FUNCTION public.sincronizar_responsaveis_em_troca_equipe();

-- 6) Remover campo `recorrencia_intervalo`?  →  MANTIDO conforme escolha do usuário.
-- Nada a alterar aqui.
