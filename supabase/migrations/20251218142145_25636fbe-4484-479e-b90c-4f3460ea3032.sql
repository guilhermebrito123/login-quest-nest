
-- Drop the existing update policy
DROP POLICY IF EXISTS "Admins, gestores e supervisores podem atualizar colaboradores" ON public.colaboradores;

-- Create new update policy that also allows users to update their own record
CREATE POLICY "Colaboradores podem atualizar seus proprios dados ou admins podem atualizar todos"
ON public.colaboradores
FOR UPDATE
USING (
  user_id = auth.uid() OR
  has_role(auth.uid(), 'admin'::internal_access_level) OR 
  has_role(auth.uid(), 'gestor_operacoes'::internal_access_level) OR 
  has_role(auth.uid(), 'supervisor'::internal_access_level)
)
WITH CHECK (
  user_id = auth.uid() OR
  has_role(auth.uid(), 'admin'::internal_access_level) OR 
  has_role(auth.uid(), 'gestor_operacoes'::internal_access_level) OR 
  has_role(auth.uid(), 'supervisor'::internal_access_level)
);
