
-- Fix RLS policy: allow any authenticated user to insert candidatos (for self-registration)
DROP POLICY IF EXISTS "Usuarios autorizados podem inserir candidatos" ON public.candidatos;

CREATE POLICY "Usuarios autenticados podem inserir candidatos" 
ON public.candidatos 
FOR INSERT 
TO authenticated
WITH CHECK (true);
