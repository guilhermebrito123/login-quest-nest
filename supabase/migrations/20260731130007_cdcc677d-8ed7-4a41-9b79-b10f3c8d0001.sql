-- Guard: usuarios column-level permissions
CREATE OR REPLACE FUNCTION public.enforce_usuarios_update_permissions()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_is_admin boolean;
BEGIN
  -- Bypass: server-side / service role (no JWT), cascatas de triggers e bypass explícito de RPC
  IF v_uid IS NULL
     OR pg_trigger_depth() > 1
     OR coalesce(current_setting('app.rpc_call', true), '') IN ('on', 'true')
  THEN
    RETURN NEW;
  END IF;

  v_is_admin := public.is_admin(v_uid);

  IF NEW.id = v_uid THEN
    -- Próprio usuário: apenas dados pessoais
    IF NEW.role IS DISTINCT FROM OLD.role THEN
      RAISE EXCEPTION 'Você não pode alterar seu próprio perfil de acesso (role)';
    END IF;
    IF NEW.ativo IS DISTINCT FROM OLD.ativo
       OR NEW.deactivated_at IS DISTINCT FROM OLD.deactivated_at
       OR NEW.deactivated_by IS DISTINCT FROM OLD.deactivated_by
       OR NEW.deactivation_reason IS DISTINCT FROM OLD.deactivation_reason THEN
      RAISE EXCEPTION 'Você não pode alterar sua própria situação de ativação';
    END IF;
    IF NEW.superior IS DISTINCT FROM OLD.superior THEN
      RAISE EXCEPTION 'Você não pode alterar seu superior';
    END IF;
    IF NEW.id IS DISTINCT FROM OLD.id THEN
      RAISE EXCEPTION 'Identificador do usuário é imutável';
    END IF;
    RETURN NEW;
  END IF;

  -- Alterando outro usuário
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Apenas administradores podem alterar outros usuários';
  END IF;

  IF NEW.id IS DISTINCT FROM OLD.id
     OR NEW.email IS DISTINCT FROM OLD.email
     OR NEW.full_name IS DISTINCT FROM OLD.full_name
     OR NEW.phone IS DISTINCT FROM OLD.phone
     OR NEW.superior IS DISTINCT FROM OLD.superior
     OR NEW.ativo IS DISTINCT FROM OLD.ativo
     OR NEW.deactivated_at IS DISTINCT FROM OLD.deactivated_at
     OR NEW.deactivated_by IS DISTINCT FROM OLD.deactivated_by
     OR NEW.deactivation_reason IS DISTINCT FROM OLD.deactivation_reason
     OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'Administradores só podem alterar o perfil de acesso (role) de outros usuários';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_usuarios_update_permissions ON public.usuarios;
CREATE TRIGGER trg_enforce_usuarios_update_permissions
BEFORE UPDATE ON public.usuarios
FOR EACH ROW EXECUTE FUNCTION public.enforce_usuarios_update_permissions();

-- Guard: internal_profiles column-level permissions
CREATE OR REPLACE FUNCTION public.enforce_internal_profiles_update_permissions()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_is_admin boolean;
BEGIN
  IF v_uid IS NULL
     OR pg_trigger_depth() > 1
     OR coalesce(current_setting('app.rpc_call', true), '') IN ('on', 'true')
  THEN
    RETURN NEW;
  END IF;

  v_is_admin := public.has_role(v_uid, 'admin'::internal_access_level);

  IF NEW.user_id = v_uid THEN
    IF NEW.nivel_acesso IS DISTINCT FROM OLD.nivel_acesso THEN
      RAISE EXCEPTION 'Você não pode alterar seu próprio nível de acesso';
    END IF;
    IF NEW.user_id IS DISTINCT FROM OLD.user_id THEN
      RAISE EXCEPTION 'Identificador do perfil é imutável';
    END IF;
    RETURN NEW;
  END IF;

  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Apenas administradores podem alterar perfis internos de outros usuários';
  END IF;

  IF NEW.user_id IS DISTINCT FROM OLD.user_id
     OR NEW.nome_completo IS DISTINCT FROM OLD.nome_completo
     OR NEW.email IS DISTINCT FROM OLD.email
     OR NEW.phone IS DISTINCT FROM OLD.phone
     OR NEW.cpf IS DISTINCT FROM OLD.cpf
     OR NEW.cargo IS DISTINCT FROM OLD.cargo
     OR NEW.departamento IS DISTINCT FROM OLD.departamento
     OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'Administradores só podem alterar o nível de acesso de outros perfis internos';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_internal_profiles_update_permissions ON public.internal_profiles;
CREATE TRIGGER trg_enforce_internal_profiles_update_permissions
BEFORE UPDATE ON public.internal_profiles
FOR EACH ROW EXECUTE FUNCTION public.enforce_internal_profiles_update_permissions();

-- Policies: restringe UPDATE de outros usuários a admins (mantendo self-update)
DROP POLICY IF EXISTS "Admins podem atualizar todos os usuarios" ON public.usuarios;
CREATE POLICY "Admins podem atualizar todos os usuarios"
ON public.usuarios FOR UPDATE TO authenticated
USING (public.is_admin(auth.uid()))
WITH CHECK (public.is_admin(auth.uid()));

DROP POLICY IF EXISTS "Usuarios podem atualizar seu proprio usuario" ON public.usuarios;
CREATE POLICY "Usuarios podem atualizar seu proprio usuario"
ON public.usuarios FOR UPDATE TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Admins podem atualizar internal_profiles" ON public.internal_profiles;
CREATE POLICY "Admins podem atualizar internal_profiles"
ON public.internal_profiles FOR UPDATE TO authenticated
USING (public.has_role(auth.uid(), 'admin'::internal_access_level))
WITH CHECK (public.has_role(auth.uid(), 'admin'::internal_access_level));

DROP POLICY IF EXISTS "Usuarios podem atualizar seu proprio internal_profile" ON public.internal_profiles;
CREATE POLICY "Usuarios podem atualizar seu proprio internal_profile"
ON public.internal_profiles FOR UPDATE TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);