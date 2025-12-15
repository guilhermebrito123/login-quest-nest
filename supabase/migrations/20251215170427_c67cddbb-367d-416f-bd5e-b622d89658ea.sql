
-- Renomear tabela profiles para perfil_interno
ALTER TABLE public.profiles RENAME TO perfil_interno;

-- Atualizar as políticas RLS (recriar com novos nomes)
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.perfil_interno;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.perfil_interno;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.perfil_interno;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.perfil_interno;

CREATE POLICY "Admins podem atualizar todos os perfis internos"
ON public.perfil_interno FOR UPDATE
USING (is_admin(auth.uid()));

CREATE POLICY "Admins podem ver todos os perfis internos"
ON public.perfil_interno FOR SELECT
USING (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Usuarios podem atualizar seu proprio perfil interno"
ON public.perfil_interno FOR UPDATE
USING (auth.uid() = id);

CREATE POLICY "Usuarios podem ver seu proprio perfil interno"
ON public.perfil_interno FOR SELECT
USING (auth.uid() = id);
