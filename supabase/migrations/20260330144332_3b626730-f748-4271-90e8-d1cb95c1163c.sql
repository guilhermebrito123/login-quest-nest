
-- Atualizar política de UPDATE para incluir assistente_operacoes
DROP POLICY IF EXISTS "Usuarios autorizados podem atualizar diaristas" ON public.diaristas;
CREATE POLICY "Usuarios autorizados podem atualizar diaristas"
ON public.diaristas
FOR UPDATE
TO authenticated
USING (
  has_role(auth.uid(), 'admin'::internal_access_level)
  OR has_role(auth.uid(), 'gestor_operacoes'::internal_access_level)
  OR has_role(auth.uid(), 'supervisor'::internal_access_level)
  OR has_role(auth.uid(), 'assistente_operacoes'::internal_access_level)
);

-- Atualizar política de DELETE para incluir assistente_operacoes
DROP POLICY IF EXISTS "Usuarios autorizados podem deletar diaristas" ON public.diaristas;
CREATE POLICY "Usuarios autorizados podem deletar diaristas"
ON public.diaristas
FOR DELETE
TO authenticated
USING (
  has_role(auth.uid(), 'admin'::internal_access_level)
  OR has_role(auth.uid(), 'gestor_operacoes'::internal_access_level)
  OR has_role(auth.uid(), 'assistente_operacoes'::internal_access_level)
);

-- Atualizar política de INSERT para incluir assistente_operacoes (mantendo regra de antecedente)
DROP POLICY IF EXISTS "Usuarios autorizados podem inserir diaristas" ON public.diaristas;
CREATE POLICY "Usuarios autorizados podem inserir diaristas"
ON public.diaristas
FOR INSERT
TO authenticated
WITH CHECK (
  (possui_antecedente = false)
  AND (
    has_role(auth.uid(), 'admin'::internal_access_level)
    OR has_role(auth.uid(), 'gestor_operacoes'::internal_access_level)
    OR has_role(auth.uid(), 'supervisor'::internal_access_level)
    OR has_role(auth.uid(), 'assistente_operacoes'::internal_access_level)
  )
);
