
-- 1) Garantir que a equipe da instância seja herdada do template, se não informada
CREATE OR REPLACE FUNCTION public.fn_checklist_instancia_default_equipe()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.equipe_responsavel_id IS NULL THEN
    SELECT t.equipe_responsavel_id
      INTO NEW.equipe_responsavel_id
    FROM public.checklist_templates t
    WHERE t.id = NEW.checklist_template_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_checklist_instancia_default_equipe ON public.checklist_instancias;
CREATE TRIGGER trg_checklist_instancia_default_equipe
BEFORE INSERT ON public.checklist_instancias
FOR EACH ROW
EXECUTE FUNCTION public.fn_checklist_instancia_default_equipe();

-- 2) Auto-atribuir tarefas aos membros ativos da equipe responsável da instância
CREATE OR REPLACE FUNCTION public.fn_auto_assign_checklist_tarefa_to_equipe()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _equipe_id UUID;
  _criador UUID;
BEGIN
  SELECT i.equipe_responsavel_id, i.criado_por_user_id
    INTO _equipe_id, _criador
  FROM public.checklist_instancias i
  WHERE i.id = NEW.checklist_instancia_id;

  IF _equipe_id IS NULL THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.checklist_tarefa_responsaveis (
    checklist_instancia_tarefa_id,
    assigned_user_id,
    assigned_by_user_id,
    status_kanban,
    pode_alterar_status,
    ativo,
    atribuida_em
  )
  SELECT
    NEW.id,
    em.user_id,
    COALESCE(_criador, em.user_id),
    'a_fazer'::status_kanban_tarefa,
    TRUE,
    TRUE,
    now()
  FROM public.equipe_membros em
  WHERE em.equipe_id = _equipe_id
    AND em.ativo = TRUE
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_assign_checklist_tarefa_to_equipe ON public.checklist_instancia_tarefas;
CREATE TRIGGER trg_auto_assign_checklist_tarefa_to_equipe
AFTER INSERT ON public.checklist_instancia_tarefas
FOR EACH ROW
EXECUTE FUNCTION public.fn_auto_assign_checklist_tarefa_to_equipe();

-- 3) Validar que apenas membros ativos da equipe responsável da instância podem ser atribuídos
CREATE OR REPLACE FUNCTION public.fn_validate_checklist_tarefa_responsavel()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _equipe_id UUID;
  _is_member BOOLEAN;
BEGIN
  SELECT i.equipe_responsavel_id
    INTO _equipe_id
  FROM public.checklist_instancia_tarefas it
  JOIN public.checklist_instancias i ON i.id = it.checklist_instancia_id
  WHERE it.id = NEW.checklist_instancia_tarefa_id;

  IF _equipe_id IS NULL THEN
    RAISE EXCEPTION 'Instância da tarefa não possui equipe responsável definida';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.equipe_membros em
    WHERE em.equipe_id = _equipe_id
      AND em.user_id = NEW.assigned_user_id
      AND em.ativo = TRUE
  ) INTO _is_member;

  IF NOT _is_member THEN
    RAISE EXCEPTION 'Apenas membros ativos da equipe responsável (%) podem ser atribuídos como responsáveis pela tarefa', _equipe_id
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_checklist_tarefa_responsavel ON public.checklist_tarefa_responsaveis;
CREATE TRIGGER trg_validate_checklist_tarefa_responsavel
BEFORE INSERT OR UPDATE OF assigned_user_id ON public.checklist_tarefa_responsaveis
FOR EACH ROW
EXECUTE FUNCTION public.fn_validate_checklist_tarefa_responsavel();
