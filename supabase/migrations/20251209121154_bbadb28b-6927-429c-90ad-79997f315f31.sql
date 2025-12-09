-- Drop existing restrictive policies on diarias_temporarias
DROP POLICY IF EXISTS "Usuarios autenticados podem criar diarias temporarias" ON public.diarias_temporarias;
DROP POLICY IF EXISTS "Usuarios autorizados podem atualizar diarias temporarias" ON public.diarias_temporarias;
DROP POLICY IF EXISTS "Usuarios podem criar diarias temporarias" ON public.diarias_temporarias;
DROP POLICY IF EXISTS "Usuarios podem atualizar diarias temporarias" ON public.diarias_temporarias;

-- Create permissive policies for any authenticated user
CREATE POLICY "Usuarios autenticados podem criar diarias temporarias" 
ON public.diarias_temporarias 
FOR INSERT 
WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Usuarios autenticados podem atualizar diarias temporarias" 
ON public.diarias_temporarias 
FOR UPDATE 
USING (auth.uid() IS NOT NULL);