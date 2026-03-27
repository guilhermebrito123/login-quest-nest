
-- Atualizar política de INSERT para incluir assistente_operacoes
DROP POLICY IF EXISTS "Usuarios autorizados podem inserir faltas_convenia" ON public.faltas_colaboradores_convenia;
CREATE POLICY "Usuarios autorizados podem inserir faltas_convenia"
ON public.faltas_colaboradores_convenia
FOR INSERT
TO authenticated
WITH CHECK (
  has_role(auth.uid(), 'admin'::internal_access_level)
  OR has_role(auth.uid(), 'gestor_operacoes'::internal_access_level)
  OR has_role(auth.uid(), 'supervisor'::internal_access_level)
  OR has_role(auth.uid(), 'assistente_operacoes'::internal_access_level)
);

-- Atualizar política de UPDATE para incluir assistente_operacoes
DROP POLICY IF EXISTS "Usuarios autorizados podem atualizar faltas_convenia" ON public.faltas_colaboradores_convenia;
CREATE POLICY "Usuarios autorizados podem atualizar faltas_convenia"
ON public.faltas_colaboradores_convenia
FOR UPDATE
TO authenticated
USING (
  has_role(auth.uid(), 'admin'::internal_access_level)
  OR has_role(auth.uid(), 'gestor_operacoes'::internal_access_level)
  OR has_role(auth.uid(), 'supervisor'::internal_access_level)
  OR has_role(auth.uid(), 'assistente_operacoes'::internal_access_level)
);

-- Atualizar política de DELETE para incluir assistente_operacoes
DROP POLICY IF EXISTS "Usuarios autorizados podem deletar faltas_convenia" ON public.faltas_colaboradores_convenia;
CREATE POLICY "Usuarios autorizados podem deletar faltas_convenia"
ON public.faltas_colaboradores_convenia
FOR DELETE
TO authenticated
USING (
  has_role(auth.uid(), 'admin'::internal_access_level)
  OR has_role(auth.uid(), 'gestor_operacoes'::internal_access_level)
  OR has_role(auth.uid(), 'supervisor'::internal_access_level)
  OR has_role(auth.uid(), 'assistente_operacoes'::internal_access_level)
);
