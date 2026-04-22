-- Reverter: assigned_by_user_id volta a ser NOT NULL
-- E os triggers passam a EXIGIR auth.uid(), bloqueando se não houver

-- 1) Recriar trigger de auto-atribuição ao criar tarefa-instância
CREATE OR REPLACE FUNCTION public.auto_assign_checklist_tarefa_to_equipe()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _equipe_id UUID;
  _actor UUID;
BEGIN
  _actor := auth.uid();
  IF _actor IS NULL THEN
    RAISE EXCEPTION 'auth.uid() é obrigatório para atribuir responsáveis a tarefas de checklist (assigned_by_user_id NOT NULL).';
  END IF;

  SELECT t.equipe_responsavel_id
    INTO _equipe_id
  FROM public.checklist_instancias ci
  JOIN public.checklist_templates t ON t.id = ci.template_id
  WHERE ci.id = NEW.checklist_instancia_id;

  IF _equipe_id IS NULL THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.checklist_tarefa_responsaveis (
    checklist_instancia_tarefa_id,
    assigned_user_id,
    assigned_by_user_id
  )
  SELECT NEW.id, em.user_id, _actor
  FROM public.module_equipe_membros em
  WHERE em.equipe_id = _equipe_id
    AND em.ativo = TRUE
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$;

-- 2) Recriar trigger de sincronização de membros da equipe
CREATE OR REPLACE FUNCTION public.sync_equipe_membros_to_checklist_assignments()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _actor UUID;
  _equipe_id UUID;
  _user_id UUID;
  _became_active BOOLEAN := FALSE;
  _became_inactive BOOLEAN := FALSE;
  _is_delete BOOLEAN := (TG_OP = 'DELETE');
BEGIN
  _actor := auth.uid();

  IF TG_OP = 'DELETE' THEN
    _equipe_id := OLD.equipe_id;
    _user_id := OLD.user_id;
    _became_inactive := TRUE;
  ELSIF TG_OP = 'INSERT' THEN
    _equipe_id := NEW.equipe_id;
    _user_id := NEW.user_id;
    _became_active := NEW.ativo;
  ELSE
    _equipe_id := NEW.equipe_id;
    _user_id := NEW.user_id;
    _became_active := (NEW.ativo = TRUE AND COALESCE(OLD.ativo, FALSE) = FALSE);
    _became_inactive := (NEW.ativo = FALSE AND COALESCE(OLD.ativo, FALSE) = TRUE);
  END IF;

  -- Remover atribuições em instâncias abertas se ficou inativo/foi removido
  IF _became_inactive THEN
    DELETE FROM public.checklist_tarefa_responsaveis r
    USING public.checklist_instancia_tarefas it
    JOIN public.checklist_instancias ci ON ci.id = it.checklist_instancia_id
    JOIN public.checklist_templates t ON t.id = ci.template_id
    WHERE r.checklist_instancia_tarefa_id = it.id
      AND r.assigned_user_id = _user_id
      AND ci.status = 'open'
      AND t.equipe_responsavel_id = _equipe_id;
  END IF;

  -- Adicionar atribuições em instâncias abertas se ficou ativo
  IF _became_active THEN
    IF _actor IS NULL THEN
      RAISE EXCEPTION 'auth.uid() é obrigatório para sincronizar atribuições de checklist (assigned_by_user_id NOT NULL).';
    END IF;

    INSERT INTO public.checklist_tarefa_responsaveis (
      checklist_instancia_tarefa_id,
      assigned_user_id,
      assigned_by_user_id
    )
    SELECT it.id, _user_id, _actor
    FROM public.checklist_instancia_tarefas it
    JOIN public.checklist_instancias ci ON ci.id = it.checklist_instancia_id
    JOIN public.checklist_templates t ON t.id = ci.template_id
    WHERE ci.status = 'open'
      AND t.equipe_responsavel_id = _equipe_id
    ON CONFLICT DO NOTHING;
  END IF;

  IF _is_delete THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

-- 3) Recriar trigger de sincronização quando a equipe do template muda
CREATE OR REPLACE FUNCTION public.sync_template_equipe_to_checklist_assignments()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _actor UUID;
BEGIN
  IF NEW.equipe_responsavel_id IS NOT DISTINCT FROM OLD.equipe_responsavel_id THEN
    RETURN NEW;
  END IF;

  _actor := auth.uid();

  -- Remover atribuições antigas (sempre permitido)
  DELETE FROM public.checklist_tarefa_responsaveis r
  USING public.checklist_instancia_tarefas it
  JOIN public.checklist_instancias ci ON ci.id = it.checklist_instancia_id
  WHERE r.checklist_instancia_tarefa_id = it.id
    AND ci.template_id = NEW.id
    AND ci.status = 'open';

  -- Adicionar novas, somente se houver actor
  IF NEW.equipe_responsavel_id IS NOT NULL THEN
    IF _actor IS NULL THEN
      RAISE EXCEPTION 'auth.uid() é obrigatório para reatribuir responsáveis ao alterar a equipe do template (assigned_by_user_id NOT NULL).';
    END IF;

    INSERT INTO public.checklist_tarefa_responsaveis (
      checklist_instancia_tarefa_id,
      assigned_user_id,
      assigned_by_user_id
    )
    SELECT it.id, em.user_id, _actor
    FROM public.checklist_instancia_tarefas it
    JOIN public.checklist_instancias ci ON ci.id = it.checklist_instancia_id
    JOIN public.module_equipe_membros em ON em.equipe_id = NEW.equipe_responsavel_id
    WHERE ci.template_id = NEW.id
      AND ci.status = 'open'
      AND em.ativo = TRUE
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;

-- 4) Restaurar NOT NULL na coluna
ALTER TABLE public.checklist_tarefa_responsaveis
  ALTER COLUMN assigned_by_user_id SET NOT NULL;