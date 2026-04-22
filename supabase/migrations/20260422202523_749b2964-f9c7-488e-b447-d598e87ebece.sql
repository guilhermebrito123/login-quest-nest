-- =========================================================================
-- Refatoração: equipe responsável vive APENAS no checklist_templates.
-- =========================================================================

-- 1) Remover triggers antigos explicitamente
DROP TRIGGER IF EXISTS trg_auto_atribuir_membros_apos_instancia    ON public.checklist_instancias;
DROP TRIGGER IF EXISTS trg_checklist_instancia_default_equipe      ON public.checklist_instancias;
DROP TRIGGER IF EXISTS trg_sincronizar_responsaveis_troca_equipe   ON public.checklist_instancias;
DROP TRIGGER IF EXISTS trg_snapshot_template_tarefas               ON public.checklist_instancias;
DROP TRIGGER IF EXISTS trg_snapshot_template_tarefas_on_instancia  ON public.checklist_instancias;
DROP TRIGGER IF EXISTS trg_set_checklist_instancia_defaults        ON public.checklist_instancias;

DROP TRIGGER IF EXISTS trg_auto_atribuir_membros_nova_tarefa       ON public.checklist_instancia_tarefas;
DROP TRIGGER IF EXISTS trg_auto_assign_checklist_tarefa_to_equipe  ON public.checklist_instancia_tarefas;

DROP TRIGGER IF EXISTS trg_validate_checklist_tarefa_responsavel   ON public.checklist_tarefa_responsaveis;

-- 2) Remover funções legadas (CASCADE para garantir)
DROP FUNCTION IF EXISTS public.fn_checklist_instancia_default_equipe()       CASCADE;
DROP FUNCTION IF EXISTS public.auto_atribuir_membros_equipe_checklist()      CASCADE;
DROP FUNCTION IF EXISTS public.sincronizar_responsaveis_em_troca_equipe()    CASCADE;
DROP FUNCTION IF EXISTS public.snapshot_template_tarefas()                   CASCADE;
DROP FUNCTION IF EXISTS public.auto_atribuir_membros_nova_tarefa()           CASCADE;
DROP FUNCTION IF EXISTS public.auto_assign_checklist_tarefa_to_equipe()      CASCADE;
DROP FUNCTION IF EXISTS public.validate_checklist_tarefa_responsavel()       CASCADE;
DROP FUNCTION IF EXISTS public.set_checklist_instancia_defaults()            CASCADE;
DROP FUNCTION IF EXISTS public.snapshot_template_tarefas_on_instancia()      CASCADE;
DROP FUNCTION IF EXISTS public.checklist_instancia_default_equipe()          CASCADE;
DROP FUNCTION IF EXISTS public.sync_new_equipe_member_to_open_instancias()   CASCADE;

-- 3) Remover coluna equipe_responsavel_id de checklist_instancias
ALTER TABLE public.checklist_instancias
  DROP CONSTRAINT IF EXISTS checklist_instancias_equipe_responsavel_id_fkey;
ALTER TABLE public.checklist_instancias
  DROP COLUMN IF EXISTS equipe_responsavel_id;

-- 4) Helper: equipe responsável a partir de uma instância
CREATE OR REPLACE FUNCTION public.get_equipe_id_for_instancia(_instancia_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT t.equipe_responsavel_id
  FROM public.checklist_instancias i
  JOIN public.checklist_templates t ON t.id = i.checklist_template_id
  WHERE i.id = _instancia_id
$$;

-- 5) Snapshot de tarefas do template ao criar uma instância
CREATE OR REPLACE FUNCTION public.snapshot_template_tarefas_on_instancia()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.checklist_instancia_tarefas (
    checklist_instancia_id,
    checklist_template_tarefa_id,
    titulo_snapshot,
    descricao_snapshot,
    ajuda_snapshot,
    ordem,
    tipo_resposta_snapshot,
    obrigatoria,
    permite_comentario,
    permite_anexo,
    nota_min,
    nota_max,
    config_json_snapshot
  )
  SELECT
    NEW.id, tt.id, tt.titulo, tt.descricao, tt.ajuda, tt.ordem,
    tt.tipo_resposta, tt.obrigatoria, tt.permite_comentario, tt.permite_anexo,
    tt.nota_min, tt.nota_max, tt.config_json
  FROM public.checklist_template_tarefas tt
  WHERE tt.checklist_template_id = NEW.checklist_template_id
  ORDER BY tt.ordem;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_snapshot_template_tarefas_on_instancia
AFTER INSERT ON public.checklist_instancias
FOR EACH ROW
EXECUTE FUNCTION public.snapshot_template_tarefas_on_instancia();

-- 6) Atribuição automática aos membros ativos da equipe do template
CREATE OR REPLACE FUNCTION public.auto_assign_checklist_tarefa_to_equipe()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _equipe_id uuid;
BEGIN
  SELECT public.get_equipe_id_for_instancia(NEW.checklist_instancia_id) INTO _equipe_id;
  IF _equipe_id IS NULL THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.checklist_tarefa_responsaveis (checklist_instancia_tarefa_id, assigned_user_id)
  SELECT NEW.id, em.user_id
  FROM public.module_equipe_membros em
  WHERE em.equipe_id = _equipe_id
    AND em.ativo = TRUE
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_auto_assign_checklist_tarefa_to_equipe
AFTER INSERT ON public.checklist_instancia_tarefas
FOR EACH ROW
EXECUTE FUNCTION public.auto_assign_checklist_tarefa_to_equipe();

-- 7) Validação: só membros ativos da equipe do template podem ser responsáveis
CREATE OR REPLACE FUNCTION public.validate_checklist_tarefa_responsavel()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _equipe_id uuid;
  _is_member boolean;
BEGIN
  SELECT t.equipe_responsavel_id INTO _equipe_id
  FROM public.checklist_instancia_tarefas it
  JOIN public.checklist_instancias i ON i.id = it.checklist_instancia_id
  JOIN public.checklist_templates t  ON t.id = i.checklist_template_id
  WHERE it.id = NEW.checklist_instancia_tarefa_id;

  IF _equipe_id IS NULL THEN
    RAISE EXCEPTION 'Não foi possível determinar a equipe responsável do template para essa tarefa.';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.module_equipe_membros em
    WHERE em.equipe_id = _equipe_id
      AND em.user_id = NEW.assigned_user_id
      AND em.ativo = TRUE
  ) INTO _is_member;

  IF NOT _is_member THEN
    RAISE EXCEPTION 'Usuário % não é membro ativo da equipe % responsável pelo template.',
      NEW.assigned_user_id, _equipe_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validate_checklist_tarefa_responsavel
BEFORE INSERT OR UPDATE ON public.checklist_tarefa_responsaveis
FOR EACH ROW
EXECUTE FUNCTION public.validate_checklist_tarefa_responsavel();

-- 8) Sincronização total (add/remove) ao mudar membros da equipe
CREATE OR REPLACE FUNCTION public.sync_equipe_membros_to_checklist_assignments()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _old_equipe uuid; _old_user uuid; _old_ativo boolean;
  _new_equipe uuid; _new_user uuid; _new_ativo boolean;
BEGIN
  IF TG_OP IN ('UPDATE','DELETE') THEN
    _old_equipe := OLD.equipe_id; _old_user := OLD.user_id; _old_ativo := OLD.ativo;
  END IF;
  IF TG_OP IN ('INSERT','UPDATE') THEN
    _new_equipe := NEW.equipe_id; _new_user := NEW.user_id; _new_ativo := NEW.ativo;
  END IF;

  IF TG_OP = 'DELETE'
     OR (TG_OP = 'UPDATE' AND (
           _old_equipe IS DISTINCT FROM _new_equipe
        OR _old_user   IS DISTINCT FROM _new_user
        OR (_old_ativo = TRUE AND _new_ativo = FALSE)
     ))
  THEN
    DELETE FROM public.checklist_tarefa_responsaveis r
    USING public.checklist_instancia_tarefas it,
          public.checklist_instancias i,
          public.checklist_templates t
    WHERE r.checklist_instancia_tarefa_id = it.id
      AND it.checklist_instancia_id = i.id
      AND i.checklist_template_id = t.id
      AND i.status = 'open'
      AND t.equipe_responsavel_id = _old_equipe
      AND r.assigned_user_id = _old_user;
  END IF;

  IF (TG_OP = 'INSERT' AND _new_ativo = TRUE)
     OR (TG_OP = 'UPDATE' AND _new_ativo = TRUE AND (
           _old_ativo = FALSE
        OR _old_equipe IS DISTINCT FROM _new_equipe
        OR _old_user   IS DISTINCT FROM _new_user
     ))
  THEN
    INSERT INTO public.checklist_tarefa_responsaveis (checklist_instancia_tarefa_id, assigned_user_id)
    SELECT it.id, _new_user
    FROM public.checklist_instancia_tarefas it
    JOIN public.checklist_instancias i ON i.id = it.checklist_instancia_id
    JOIN public.checklist_templates t  ON t.id = i.checklist_template_id
    WHERE i.status = 'open'
      AND t.equipe_responsavel_id = _new_equipe
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN NULL;
END;
$$;

CREATE TRIGGER trg_sync_equipe_membros_to_checklist_assignments
AFTER INSERT OR UPDATE OR DELETE ON public.module_equipe_membros
FOR EACH ROW
EXECUTE FUNCTION public.sync_equipe_membros_to_checklist_assignments();

-- 9) Sincronização ao mudar a equipe responsável do template
CREATE OR REPLACE FUNCTION public.sync_template_equipe_to_checklist_assignments()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.equipe_responsavel_id IS DISTINCT FROM OLD.equipe_responsavel_id THEN
    DELETE FROM public.checklist_tarefa_responsaveis r
    USING public.checklist_instancia_tarefas it,
          public.checklist_instancias i
    WHERE r.checklist_instancia_tarefa_id = it.id
      AND it.checklist_instancia_id = i.id
      AND i.checklist_template_id = NEW.id
      AND i.status = 'open';

    INSERT INTO public.checklist_tarefa_responsaveis (checklist_instancia_tarefa_id, assigned_user_id)
    SELECT it.id, em.user_id
    FROM public.checklist_instancia_tarefas it
    JOIN public.checklist_instancias i ON i.id = it.checklist_instancia_id
    JOIN public.module_equipe_membros em ON em.equipe_id = NEW.equipe_responsavel_id
    WHERE i.checklist_template_id = NEW.id
      AND i.status = 'open'
      AND em.ativo = TRUE
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sync_template_equipe_to_checklist_assignments
AFTER UPDATE OF equipe_responsavel_id ON public.checklist_templates
FOR EACH ROW
EXECUTE FUNCTION public.sync_template_equipe_to_checklist_assignments();
