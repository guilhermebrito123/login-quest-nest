
-- Permitir NULL em assigned_by_user_id quando a atribuição é automática (feita pelo sistema via triggers)
ALTER TABLE public.checklist_tarefa_responsaveis
  ALTER COLUMN assigned_by_user_id DROP NOT NULL;

-- Atualizar trigger de auto-atribuição para usar auth.uid() quando disponível, NULL caso contrário
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
  -- Pega a equipe responsavel via template da instancia
  SELECT ct.equipe_responsavel_id
    INTO _equipe_id
  FROM public.checklist_instancias ci
  JOIN public.checklist_templates ct ON ct.id = ci.template_id
  WHERE ci.id = NEW.checklist_instancia_id;

  IF _equipe_id IS NULL THEN
    RETURN NEW;
  END IF;

  BEGIN
    _actor := auth.uid();
  EXCEPTION WHEN OTHERS THEN
    _actor := NULL;
  END;

  INSERT INTO public.checklist_tarefa_responsaveis (
    checklist_instancia_tarefa_id,
    assigned_user_id,
    assigned_by_user_id
  )
  SELECT NEW.id, em.user_id, _actor
  FROM public.module_equipe_membros em
  WHERE em.equipe_id = _equipe_id AND em.ativo = TRUE
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$;

-- Atualizar trigger de sincronizacao de membros da equipe
CREATE OR REPLACE FUNCTION public.sync_equipe_membros_to_checklist_assignments()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _user_id UUID;
  _equipe_id UUID;
  _ativo BOOLEAN;
  _actor UUID;
BEGIN
  IF TG_OP = 'DELETE' THEN
    _user_id := OLD.user_id;
    _equipe_id := OLD.equipe_id;
    _ativo := FALSE;
  ELSE
    _user_id := NEW.user_id;
    _equipe_id := NEW.equipe_id;
    _ativo := NEW.ativo;
  END IF;

  BEGIN
    _actor := auth.uid();
  EXCEPTION WHEN OTHERS THEN
    _actor := NULL;
  END;

  IF _ativo = FALSE OR TG_OP = 'DELETE' THEN
    -- Remover atribuicoes em instancias abertas
    DELETE FROM public.checklist_tarefa_responsaveis ctr
    USING public.checklist_instancia_tarefas cit
    JOIN public.checklist_instancias ci ON ci.id = cit.checklist_instancia_id
    JOIN public.checklist_templates ct ON ct.id = ci.template_id
    WHERE ctr.checklist_instancia_tarefa_id = cit.id
      AND ctr.assigned_user_id = _user_id
      AND ct.equipe_responsavel_id = _equipe_id
      AND ci.status = 'open';
  ELSE
    -- Adicionar atribuicoes para o novo membro em instancias abertas
    INSERT INTO public.checklist_tarefa_responsaveis (
      checklist_instancia_tarefa_id,
      assigned_user_id,
      assigned_by_user_id
    )
    SELECT cit.id, _user_id, _actor
    FROM public.checklist_instancia_tarefas cit
    JOIN public.checklist_instancias ci ON ci.id = cit.checklist_instancia_id
    JOIN public.checklist_templates ct ON ct.id = ci.template_id
    WHERE ct.equipe_responsavel_id = _equipe_id
      AND ci.status = 'open'
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Atualizar trigger de mudanca de equipe no template
CREATE OR REPLACE FUNCTION public.sync_template_equipe_to_checklist_assignments()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _actor UUID;
BEGIN
  IF NEW.equipe_responsavel_id IS DISTINCT FROM OLD.equipe_responsavel_id THEN
    BEGIN
      _actor := auth.uid();
    EXCEPTION WHEN OTHERS THEN
      _actor := NULL;
    END;

    -- Remove atribuicoes da equipe antiga em instancias abertas
    DELETE FROM public.checklist_tarefa_responsaveis ctr
    USING public.checklist_instancia_tarefas cit
    JOIN public.checklist_instancias ci ON ci.id = cit.checklist_instancia_id
    WHERE ctr.checklist_instancia_tarefa_id = cit.id
      AND ci.template_id = NEW.id
      AND ci.status = 'open';

    -- Adiciona atribuicoes para todos os membros ativos da nova equipe
    IF NEW.equipe_responsavel_id IS NOT NULL THEN
      INSERT INTO public.checklist_tarefa_responsaveis (
        checklist_instancia_tarefa_id,
        assigned_user_id,
        assigned_by_user_id
      )
      SELECT cit.id, em.user_id, _actor
      FROM public.checklist_instancia_tarefas cit
      JOIN public.checklist_instancias ci ON ci.id = cit.checklist_instancia_id
      JOIN public.module_equipe_membros em ON em.equipe_id = NEW.equipe_responsavel_id
      WHERE ci.template_id = NEW.id
        AND ci.status = 'open'
        AND em.ativo = TRUE
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;
