
-- Drop the existing insert policy
DROP POLICY IF EXISTS "Admins, gestores e supervisores podem inserir colaboradores" ON public.colaboradores;

-- Create new insert policy that also allows users to insert their own record
CREATE POLICY "Colaboradores podem inserir seus proprios dados ou admins podem inserir todos"
ON public.colaboradores
FOR INSERT
WITH CHECK (
  user_id = auth.uid() OR
  has_role(auth.uid(), 'admin'::internal_access_level) OR 
  has_role(auth.uid(), 'gestor_operacoes'::internal_access_level) OR 
  has_role(auth.uid(), 'supervisor'::internal_access_level)
);
