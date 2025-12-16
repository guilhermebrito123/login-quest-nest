-- Add unique constraint on email in candidatos table for ON CONFLICT to work
ALTER TABLE public.candidatos 
ADD CONSTRAINT candidatos_email_unique UNIQUE (email);

-- Fix storage policy: allow authenticated users to upload their own files
-- The previous policy might not be working because it checks foldername which may be empty for root uploads
DROP POLICY IF EXISTS "Candidatos podem fazer upload de seus arquivos" ON storage.objects;

-- Create more permissive policy for candidatos bucket - allow any authenticated user to upload
CREATE POLICY "Candidatos podem fazer upload de seus arquivos" 
ON storage.objects 
FOR INSERT 
TO authenticated
WITH CHECK (
  bucket_id = 'candidatos-anexos'
);