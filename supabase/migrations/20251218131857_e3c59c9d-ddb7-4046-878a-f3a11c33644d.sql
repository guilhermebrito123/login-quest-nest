-- Add policy for users to update their own internal_profile
CREATE POLICY "Usuarios podem atualizar seu proprio internal_profile"
ON public.internal_profiles
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);