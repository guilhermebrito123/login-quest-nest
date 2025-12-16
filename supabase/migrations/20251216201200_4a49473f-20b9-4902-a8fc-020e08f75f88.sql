-- Drop the restrictive INSERT policy for candidatos-anexos
DROP POLICY IF EXISTS "Usuarios autorizados podem fazer upload de arquivos de candidat" ON storage.objects;

-- Create new INSERT policy that allows authenticated users to upload to their own folder
CREATE POLICY "Candidatos podem fazer upload de seus arquivos" 
ON storage.objects 
FOR INSERT 
TO authenticated
WITH CHECK (
  bucket_id = 'candidatos-anexos' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Also allow admins to upload to any folder
CREATE POLICY "Admins podem fazer upload de arquivos de candidatos" 
ON storage.objects 
FOR INSERT 
TO public
WITH CHECK (
  bucket_id = 'candidatos-anexos' 
  AND (
    has_role(auth.uid(), 'admin'::internal_access_level) 
    OR has_role(auth.uid(), 'gestor_operacoes'::internal_access_level)
  )
);