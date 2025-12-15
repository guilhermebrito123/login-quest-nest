
-- 1. Criar tabela internal_profiles
CREATE TABLE public.internal_profiles (
  user_id UUID PRIMARY KEY REFERENCES public.usuarios(id) ON DELETE CASCADE,
  nivel_acesso public.app_role NOT NULL DEFAULT 'cliente_view'::public.app_role,
  cargo TEXT,
  departamento TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- 2. Habilitar RLS
ALTER TABLE public.internal_profiles ENABLE ROW LEVEL SECURITY;

-- 3. Políticas RLS
CREATE POLICY "Admins podem ver todos os internal_profiles"
ON public.internal_profiles
FOR SELECT
USING (public.has_role(auth.uid(), 'admin'::public.app_role));

CREATE POLICY "Usuarios podem ver seu proprio internal_profile"
ON public.internal_profiles
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Admins podem inserir internal_profiles"
ON public.internal_profiles
FOR INSERT
WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));

CREATE POLICY "Admins podem atualizar internal_profiles"
ON public.internal_profiles
FOR UPDATE
USING (public.has_role(auth.uid(), 'admin'::public.app_role));

CREATE POLICY "Admins podem deletar internal_profiles"
ON public.internal_profiles
FOR DELETE
USING (public.has_role(auth.uid(), 'admin'::public.app_role));

-- 4. Trigger para atualizar updated_at
CREATE TRIGGER update_internal_profiles_updated_at
BEFORE UPDATE ON public.internal_profiles
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- 5. Migrar TODOS os usuarios existentes para internal_profiles com nivel_acesso = admin
INSERT INTO public.internal_profiles (user_id, nivel_acesso, created_at, updated_at)
SELECT id, 'admin'::public.app_role, now(), now()
FROM public.usuarios
ON CONFLICT (user_id) DO NOTHING;

-- 6. Atualizar função has_role para verificar internal_profiles.nivel_acesso
CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.internal_profiles
    WHERE user_id = _user_id
      AND nivel_acesso = _role
  )
$$;

-- 7. Atualizar função is_admin para verificar internal_profiles
CREATE OR REPLACE FUNCTION public.is_admin(_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.internal_profiles
    WHERE user_id = _user_id
      AND nivel_acesso = 'admin'::public.app_role
  )
$$;

-- 8. Trigger para criar internal_profile automaticamente quando usuarios com role='perfil_interno' é criado
CREATE OR REPLACE FUNCTION public.handle_new_internal_profile()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.internal_profiles (user_id, nivel_acesso)
  VALUES (NEW.id, 'cliente_view'::public.app_role)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_usuario_created_internal_profile
AFTER INSERT ON public.usuarios
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_internal_profile();
