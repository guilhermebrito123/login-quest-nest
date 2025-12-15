-- Rename table from perfil_interno to usuarios
ALTER TABLE public.perfil_interno RENAME TO usuarios;

-- Update RLS policies with new table name
DROP POLICY IF EXISTS "Usuarios podem ver seu proprio perfil interno" ON public.usuarios;
DROP POLICY IF EXISTS "Usuarios podem atualizar seu proprio perfil interno" ON public.usuarios;
DROP POLICY IF EXISTS "Admins podem ver todos os perfis internos" ON public.usuarios;
DROP POLICY IF EXISTS "Admins podem atualizar todos os perfis internos" ON public.usuarios;

CREATE POLICY "Usuarios podem ver seu proprio usuario"
ON public.usuarios
FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Usuarios podem atualizar seu proprio usuario"
ON public.usuarios
FOR UPDATE
USING (auth.uid() = id);

CREATE POLICY "Admins podem ver todos os usuarios"
ON public.usuarios
FOR SELECT
USING (has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Admins podem atualizar todos os usuarios"
ON public.usuarios
FOR UPDATE
USING (is_admin(auth.uid()));