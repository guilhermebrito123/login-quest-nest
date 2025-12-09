-- Add SELECT policy for admins to read all diarias_temporarias
CREATE POLICY "Admins podem ler todas diarias temporarias" 
ON public.diarias_temporarias 
FOR SELECT 
USING (has_role(auth.uid(), 'admin'::app_role));