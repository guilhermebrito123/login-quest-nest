
-- Atualizar política de upload de atestados para incluir assistente_operacoes
DROP POLICY IF EXISTS "Usuarios autorizados podem fazer upload de atestados" ON storage.objects;

CREATE POLICY "Usuarios autorizados podem fazer upload de atestados"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'atestados'
  AND (
    has_role(auth.uid(), 'admin'::internal_access_level)
    OR has_role(auth.uid(), 'gestor_operacoes'::internal_access_level)
    OR has_role(auth.uid(), 'supervisor'::internal_access_level)
    OR has_role(auth.uid(), 'assistente_operacoes'::internal_access_level)
  )
);
