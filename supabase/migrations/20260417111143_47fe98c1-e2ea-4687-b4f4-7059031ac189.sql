-- chamado_anexos: delete por interno (≠ cliente_view) ou pelo próprio colaborador autor
DROP POLICY IF EXISTS anexos_delete ON public.chamado_anexos;
CREATE POLICY anexos_delete ON public.chamado_anexos
FOR DELETE
USING (
  (current_internal_access_level() IS NOT NULL
   AND current_internal_access_level() <> 'cliente_view'::internal_access_level)
  OR (
    uploaded_by = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.role = 'colaborador'::user_type
    )
  )
);

-- chamado_interacoes: delete por interno (≠ cliente_view) ou pelo próprio colaborador autor
DROP POLICY IF EXISTS interacoes_delete ON public.chamado_interacoes;
CREATE POLICY interacoes_delete ON public.chamado_interacoes
FOR DELETE
USING (
  (current_internal_access_level() IS NOT NULL
   AND current_internal_access_level() <> 'cliente_view'::internal_access_level)
  OR (
    autor_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.role = 'colaborador'::user_type
    )
  )
);