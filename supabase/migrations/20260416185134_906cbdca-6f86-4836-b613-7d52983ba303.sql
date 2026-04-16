-- 1. Criar tabela colaborador_profiles
CREATE TABLE IF NOT EXISTS public.colaborador_profiles (
  user_id uuid PRIMARY KEY REFERENCES public.usuarios(id) ON DELETE CASCADE,
  cost_center_id uuid NOT NULL REFERENCES public.cost_center(id),
  ativo boolean NOT NULL DEFAULT true,
  observacoes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL REFERENCES public.usuarios(id),
  updated_by uuid REFERENCES public.usuarios(id)
);

CREATE INDEX IF NOT EXISTS idx_colaborador_profiles_cost_center 
  ON public.colaborador_profiles(cost_center_id);

-- 2. Trigger updated_at
CREATE TRIGGER trg_colaborador_profiles_updated_at
  BEFORE UPDATE ON public.colaborador_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- 3. Habilitar RLS
ALTER TABLE public.colaborador_profiles ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
CREATE POLICY "Internos e proprio colaborador podem ler colaborador_profiles"
  ON public.colaborador_profiles
  FOR SELECT
  TO authenticated
  USING (is_internal_user() OR user_id = auth.uid());

CREATE POLICY "Apenas admins podem inserir colaborador_profiles"
  ON public.colaborador_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (has_role(auth.uid(), 'admin'::internal_access_level));

CREATE POLICY "Apenas admins podem atualizar colaborador_profiles"
  ON public.colaborador_profiles
  FOR UPDATE
  TO authenticated
  USING (has_role(auth.uid(), 'admin'::internal_access_level))
  WITH CHECK (has_role(auth.uid(), 'admin'::internal_access_level));

CREATE POLICY "Apenas admins podem deletar colaborador_profiles"
  ON public.colaborador_profiles
  FOR DELETE
  TO authenticated
  USING (has_role(auth.uid(), 'admin'::internal_access_level));

-- 5. Trigger de validação: só permite colaborador_profiles se usuario.role = 'colaborador'
CREATE OR REPLACE FUNCTION public.validar_colaborador_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.user_type;
BEGIN
  SELECT role INTO v_role
  FROM public.usuarios
  WHERE id = NEW.user_id;

  IF v_role <> 'colaborador' THEN
    RAISE EXCEPTION 'O usuário precisa ter role = colaborador para possuir colaborador_profiles (role atual: %)', v_role;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validar_colaborador_profile
  BEFORE INSERT OR UPDATE ON public.colaborador_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.validar_colaborador_profile();

-- 6. Função RPC transacional para promover usuário a colaborador
CREATE OR REPLACE FUNCTION public.definir_usuario_como_colaborador(
  p_user_id uuid,
  p_cost_center_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id uuid;
BEGIN
  v_admin_id := auth.uid();

  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Não autenticado';
  END IF;

  IF NOT has_role(v_admin_id, 'admin'::internal_access_level) THEN
    RAISE EXCEPTION 'Apenas administradores podem definir usuários como colaborador';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.cost_center WHERE id = p_cost_center_id) THEN
    RAISE EXCEPTION 'Cost center inválido';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.usuarios WHERE id = p_user_id) THEN
    RAISE EXCEPTION 'Usuário não encontrado';
  END IF;

  -- Sinaliza para o trigger handle_usuario_role_transition pular a inserção em colaboradores
  PERFORM set_config('app.skip_colaborador_insert', 'true', true);

  UPDATE public.usuarios
  SET role = 'colaborador'::user_type,
      updated_at = now()
  WHERE id = p_user_id;

  INSERT INTO public.colaborador_profiles (
    user_id, cost_center_id, created_by, updated_by
  ) VALUES (
    p_user_id, p_cost_center_id, v_admin_id, v_admin_id
  )
  ON CONFLICT (user_id) DO UPDATE SET
    cost_center_id = EXCLUDED.cost_center_id,
    ativo = true,
    updated_by = v_admin_id,
    updated_at = now();
END;
$$;

-- 7. Atualizar trigger handle_usuario_role_transition para respeitar o flag de skip
CREATE OR REPLACE FUNCTION public.handle_usuario_role_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_skip text;
BEGIN
  -- Permite que a função definir_usuario_como_colaborador pule a criação automática em colaboradores
  v_skip := current_setting('app.skip_colaborador_insert', true);
  IF v_skip = 'true' THEN
    RETURN NEW;
  END IF;

  -- Lógica original: ao virar colaborador, criar registro em colaboradores se não existir
  IF NEW.role = 'colaborador'::user_type AND (OLD.role IS NULL OR OLD.role <> 'colaborador'::user_type) THEN
    INSERT INTO public.colaboradores (user_id, nome_completo, cpf, email, telefone)
    VALUES (
      NEW.id,
      COALESCE(NEW.full_name, NEW.email, 'Sem nome'),
      '',
      NEW.email,
      NEW.phone
    )
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;

-- 8. Trigger de validação na abertura de chamados
CREATE OR REPLACE FUNCTION public.validar_abertura_chamado()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_role public.user_type;
  v_colaborador_cost_center uuid;
  v_local_cost_center uuid;
BEGIN
  SELECT role INTO v_user_role
  FROM public.usuarios
  WHERE id = NEW.solicitante_id;

  IF v_user_role = 'colaborador'::user_type THEN
    SELECT cost_center_id INTO v_colaborador_cost_center
    FROM public.colaborador_profiles
    WHERE user_id = NEW.solicitante_id AND ativo = true;

    IF v_colaborador_cost_center IS NULL THEN
      RAISE EXCEPTION 'Colaborador sem cost_center vinculado não pode abrir chamado';
    END IF;

    SELECT cost_center_id INTO v_local_cost_center
    FROM public.cost_center_locais
    WHERE id = NEW.local_id AND ativo = true;

    IF v_local_cost_center IS NULL THEN
      RAISE EXCEPTION 'Local inválido ou inativo';
    END IF;

    IF v_colaborador_cost_center <> v_local_cost_center THEN
      RAISE EXCEPTION 'Colaborador só pode abrir chamado para locais do seu próprio cost_center';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validar_abertura_chamado
  BEFORE INSERT ON public.chamados
  FOR EACH ROW
  EXECUTE FUNCTION public.validar_abertura_chamado();