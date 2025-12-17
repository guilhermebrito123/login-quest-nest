
-- Fix RLS policy: allow users to update their own candidato record
DROP POLICY IF EXISTS "Usuarios autorizados podem atualizar candidatos" ON public.candidatos;

CREATE POLICY "Usuarios podem atualizar seu proprio candidato" 
ON public.candidatos 
FOR UPDATE 
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);
