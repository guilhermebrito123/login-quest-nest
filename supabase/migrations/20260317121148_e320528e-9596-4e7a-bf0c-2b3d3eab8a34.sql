
CREATE POLICY "horas_extras_delete_cancelada_reprovada"
ON public.horas_extras
FOR DELETE
TO authenticated
USING (status IN ('cancelada', 'reprovada'));
