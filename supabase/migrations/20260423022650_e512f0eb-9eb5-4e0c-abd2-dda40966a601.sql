-- =========================================================
-- 1) BUCKET PRIVADO PARA ANEXOS DE CHECKLIST
-- =========================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('checklist-anexos', 'checklist-anexos', false)
ON CONFLICT (id) DO NOTHING;

-- =========================================================
-- 2) TABELA DE METADADOS
-- =========================================================
CREATE TABLE IF NOT EXISTS public.checklist_resposta_anexos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_tarefa_resposta_id uuid NOT NULL
    REFERENCES public.checklist_tarefa_respostas(id) ON DELETE CASCADE,
  checklist_instancia_tarefa_id uuid NOT NULL
    REFERENCES public.checklist_instancia_tarefas(id) ON DELETE CASCADE,
  caminho_storage text NOT NULL,
  nome_arquivo text NOT NULL,
  tipo_arquivo text,
  tamanho_bytes bigint,
  uploaded_by uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_checklist_resposta_anexos_resposta
  ON public.checklist_resposta_anexos (checklist_tarefa_resposta_id);

CREATE INDEX IF NOT EXISTS idx_checklist_resposta_anexos_tarefa
  ON public.checklist_resposta_anexos (checklist_instancia_tarefa_id);

ALTER TABLE public.checklist_resposta_anexos ENABLE ROW LEVEL SECURITY;

-- =========================================================
-- 3) HELPER: usuário pode VER os anexos de uma tarefa de instância?
-- (admin do módulo, supervisor do cost center da instância,
--  ou responsável ativo pela tarefa)
-- =========================================================
CREATE OR REPLACE FUNCTION public.can_view_checklist_tarefa(_user_id uuid, _tarefa_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.checklist_instancia_tarefas t
    JOIN public.checklist_instancias i ON i.id = t.checklist_instancia_id
    WHERE t.id = _tarefa_id
      AND (
        public.module_is_admin(_user_id)
        OR public.module_supervisor_has_cost_center(_user_id, i.cost_center_id)
        OR EXISTS (
          SELECT 1
          FROM public.checklist_tarefa_responsaveis r
          WHERE r.checklist_instancia_tarefa_id = t.id
            AND r.assigned_user_id = _user_id
            AND r.ativo = true
        )
      )
  )
$$;

-- =========================================================
-- 4) HELPER: usuário pode ENVIAR anexos para uma tarefa?
-- (gestor da instância, OU responsável ativo da tarefa)
-- =========================================================
CREATE OR REPLACE FUNCTION public.can_upload_checklist_anexo(_user_id uuid, _tarefa_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.checklist_instancia_tarefas t
    JOIN public.checklist_instancias i ON i.id = t.checklist_instancia_id
    WHERE t.id = _tarefa_id
      AND t.permite_anexo = true
      AND (
        public.can_manage_checklist_cc(_user_id, i.cost_center_id)
        OR EXISTS (
          SELECT 1
          FROM public.checklist_tarefa_responsaveis r
          WHERE r.checklist_instancia_tarefa_id = t.id
            AND r.assigned_user_id = _user_id
            AND r.ativo = true
        )
      )
  )
$$;

-- =========================================================
-- 5) HELPER: usuário pode GERENCIAR a instância da tarefa?
-- (usado para delete por admin/supervisor)
-- =========================================================
CREATE OR REPLACE FUNCTION public.can_manage_checklist_tarefa(_user_id uuid, _tarefa_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.checklist_instancia_tarefas t
    JOIN public.checklist_instancias i ON i.id = t.checklist_instancia_id
    WHERE t.id = _tarefa_id
      AND public.can_manage_checklist_cc(_user_id, i.cost_center_id)
  )
$$;

-- =========================================================
-- 6) RLS POLICIES — checklist_resposta_anexos
-- =========================================================
DROP POLICY IF EXISTS "anexos_resposta_select" ON public.checklist_resposta_anexos;
CREATE POLICY "anexos_resposta_select"
ON public.checklist_resposta_anexos
FOR SELECT
TO authenticated
USING (public.can_view_checklist_tarefa(auth.uid(), checklist_instancia_tarefa_id));

DROP POLICY IF EXISTS "anexos_resposta_insert" ON public.checklist_resposta_anexos;
CREATE POLICY "anexos_resposta_insert"
ON public.checklist_resposta_anexos
FOR INSERT
TO authenticated
WITH CHECK (
  uploaded_by = auth.uid()
  AND public.can_upload_checklist_anexo(auth.uid(), checklist_instancia_tarefa_id)
);

DROP POLICY IF EXISTS "anexos_resposta_delete" ON public.checklist_resposta_anexos;
CREATE POLICY "anexos_resposta_delete"
ON public.checklist_resposta_anexos
FOR DELETE
TO authenticated
USING (
  uploaded_by = auth.uid()
  OR public.can_manage_checklist_tarefa(auth.uid(), checklist_instancia_tarefa_id)
);

-- =========================================================
-- 7) TRIGGER DE VALIDAÇÃO:
-- - permite_anexo = true na tarefa
-- - tarefa do anexo bate com tarefa da resposta
-- =========================================================
CREATE OR REPLACE FUNCTION public.validate_checklist_resposta_anexo()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tarefa_da_resposta uuid;
  v_permite_anexo boolean;
BEGIN
  SELECT checklist_instancia_tarefa_id
    INTO v_tarefa_da_resposta
    FROM public.checklist_tarefa_respostas
   WHERE id = NEW.checklist_tarefa_resposta_id;

  IF v_tarefa_da_resposta IS NULL THEN
    RAISE EXCEPTION 'Resposta de tarefa não encontrada (%).',
      NEW.checklist_tarefa_resposta_id;
  END IF;

  IF v_tarefa_da_resposta <> NEW.checklist_instancia_tarefa_id THEN
    RAISE EXCEPTION 'O anexo deve pertencer à mesma tarefa de instância da resposta.';
  END IF;

  SELECT permite_anexo
    INTO v_permite_anexo
    FROM public.checklist_instancia_tarefas
   WHERE id = NEW.checklist_instancia_tarefa_id;

  IF v_permite_anexo IS NOT TRUE THEN
    RAISE EXCEPTION 'Esta tarefa não permite anexos.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_checklist_resposta_anexo
  ON public.checklist_resposta_anexos;

CREATE TRIGGER trg_validate_checklist_resposta_anexo
BEFORE INSERT ON public.checklist_resposta_anexos
FOR EACH ROW
EXECUTE FUNCTION public.validate_checklist_resposta_anexo();

-- =========================================================
-- 8) STORAGE POLICIES no bucket 'checklist-anexos'
-- Estrutura esperada das chaves:
--   {checklist_instancia_id}/{checklist_instancia_tarefa_id}/{arquivo}
-- A 1ª pasta é a instância, a 2ª pasta é a tarefa.
-- =========================================================

-- Ler arquivos: quem pode ver a tarefa correspondente
DROP POLICY IF EXISTS "checklist_anexos_storage_select"
  ON storage.objects;
CREATE POLICY "checklist_anexos_storage_select"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'checklist-anexos'
  AND public.can_view_checklist_tarefa(
        auth.uid(),
        NULLIF((storage.foldername(name))[2], '')::uuid
      )
);

-- Subir arquivos: quem pode enviar anexos para aquela tarefa
DROP POLICY IF EXISTS "checklist_anexos_storage_insert"
  ON storage.objects;
CREATE POLICY "checklist_anexos_storage_insert"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'checklist-anexos'
  AND public.can_upload_checklist_anexo(
        auth.uid(),
        NULLIF((storage.foldername(name))[2], '')::uuid
      )
);

-- Deletar arquivos: gestor da instância (o owner adicional é tratado pela tabela
-- de metadados — quem inseriu pode remover via app deletando primeiro a linha)
DROP POLICY IF EXISTS "checklist_anexos_storage_delete"
  ON storage.objects;
CREATE POLICY "checklist_anexos_storage_delete"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'checklist-anexos'
  AND (
    owner = auth.uid()
    OR public.can_manage_checklist_tarefa(
         auth.uid(),
         NULLIF((storage.foldername(name))[2], '')::uuid
       )
  )
);