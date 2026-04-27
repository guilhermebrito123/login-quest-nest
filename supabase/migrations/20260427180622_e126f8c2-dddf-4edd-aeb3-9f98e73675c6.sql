-- =============================================================
-- SOFT-DELETE DE USUÁRIOS + BLOQUEIO UNIVERSAL DE CRUD
-- =============================================================

-- 1. Colunas de soft-delete em usuarios -----------------------------------
ALTER TABLE public.usuarios
  ADD COLUMN IF NOT EXISTS ativo boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS deactivated_at timestamptz NULL,
  ADD COLUMN IF NOT EXISTS deactivated_by uuid NULL,
  ADD COLUMN IF NOT EXISTS deactivation_reason text NULL;

-- FK auto-referenciada para deactivated_by
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'usuarios_deactivated_by_fkey'
  ) THEN
    ALTER TABLE public.usuarios
      ADD CONSTRAINT usuarios_deactivated_by_fkey
      FOREIGN KEY (deactivated_by) REFERENCES public.usuarios(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_usuarios_ativo ON public.usuarios(id) WHERE ativo = true;

-- 2. Função-guard central -------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_user_is_active()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT ativo FROM public.usuarios WHERE id = auth.uid()),
    false
  );
$$;

-- Defesa em profundidade: nivel_acesso vira NULL se inativo
CREATE OR REPLACE FUNCTION public.current_internal_access_level()
RETURNS internal_access_level
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT ip.nivel_acesso
  FROM public.internal_profiles ip
  JOIN public.usuarios u ON u.id = ip.user_id
  WHERE ip.user_id = auth.uid()
    AND u.ativo = true
  LIMIT 1;
$$;

-- 3. Policy RESTRICTIVE em todas as tabelas de public --------------------
-- Aplica somente ao role authenticated (não interfere em chamadas anon
-- legítimas como candidatos públicos). usuarios é tratada à parte.
DO $$
DECLARE
  r record;
  excluded_tables text[] := ARRAY[
    'usuarios',           -- tratada separadamente
    'candidatos',         -- registro anônimo
    'candidatos_anexos',  -- anexos do registro anônimo
    'sync_logs',          -- logs de jobs/edge functions
    'webhook_logs'        -- logs de webhooks externos
  ];
BEGIN
  FOR r IN
    SELECT c.relname
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind = 'r'
      AND NOT (c.relname = ANY(excluded_tables))
  LOOP
    EXECUTE format($f$
      DROP POLICY IF EXISTS "require_active_user" ON public.%I;
      CREATE POLICY "require_active_user" ON public.%I
        AS RESTRICTIVE
        FOR ALL
        TO authenticated
        USING (public.current_user_is_active())
        WITH CHECK (public.current_user_is_active());
    $f$, r.relname, r.relname);
  END LOOP;
END $$;

-- 4. Policy especial em usuarios -----------------------------------------
-- O usuário inativo PODE ler o próprio registro (para o frontend mostrar
-- "conta desativada"), mas não pode fazer nenhum DML nem ler outros.
DROP POLICY IF EXISTS "require_active_user_dml" ON public.usuarios;
CREATE POLICY "require_active_user_dml" ON public.usuarios
  AS RESTRICTIVE
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_user_is_active());

DROP POLICY IF EXISTS "require_active_user_update" ON public.usuarios;
CREATE POLICY "require_active_user_update" ON public.usuarios
  AS RESTRICTIVE
  FOR UPDATE
  TO authenticated
  USING (public.current_user_is_active())
  WITH CHECK (public.current_user_is_active());

DROP POLICY IF EXISTS "require_active_user_delete" ON public.usuarios;
CREATE POLICY "require_active_user_delete" ON public.usuarios
  AS RESTRICTIVE
  FOR DELETE
  TO authenticated
  USING (public.current_user_is_active());

DROP POLICY IF EXISTS "require_active_or_self_select" ON public.usuarios;
CREATE POLICY "require_active_or_self_select" ON public.usuarios
  AS RESTRICTIVE
  FOR SELECT
  TO authenticated
  USING (public.current_user_is_active() OR id = auth.uid());

-- 5. Trigger de auditoria automática quando ativo muda -------------------
CREATE OR REPLACE FUNCTION public.handle_usuario_ativo_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.ativo IS DISTINCT FROM OLD.ativo THEN
    IF NEW.ativo = false THEN
      NEW.deactivated_at := COALESCE(NEW.deactivated_at, now());
      NEW.deactivated_by := COALESCE(NEW.deactivated_by, auth.uid());
    ELSE
      -- reativação: limpa marcadores
      NEW.deactivated_at := NULL;
      NEW.deactivated_by := NULL;
      NEW.deactivation_reason := NULL;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_usuarios_ativo_change ON public.usuarios;
CREATE TRIGGER trg_usuarios_ativo_change
  BEFORE UPDATE OF ativo ON public.usuarios
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_usuario_ativo_change();

COMMENT ON COLUMN public.usuarios.ativo IS
  'Soft-delete flag. Quando false, RLS bloqueia todo CRUD em todas as tabelas e o login deve ser banido via Auth admin (edge function deactivate-user).';