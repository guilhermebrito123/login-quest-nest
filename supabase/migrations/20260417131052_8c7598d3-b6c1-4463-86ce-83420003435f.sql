DROP POLICY IF EXISTS chamados_delete ON public.chamados;

CREATE POLICY chamados_delete ON public.chamados
FOR DELETE
USING (
  (
    current_internal_access_level() IS NOT NULL
    AND current_internal_access_level() <> 'cliente_view'::internal_access_level
  )
  OR (
    solicitante_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid() AND u.role = 'colaborador'::user_type
    )
  )
);