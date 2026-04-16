-- chamados: interno (≠ cliente_view) OU solicitante
DROP POLICY IF EXISTS chamados_select ON public.chamados;
CREATE POLICY chamados_select ON public.chamados
FOR SELECT
USING (
  (current_internal_access_level() IS NOT NULL
   AND current_internal_access_level() <> 'cliente_view'::internal_access_level)
  OR solicitante_id = auth.uid()
);

-- chamado_anexos
DROP POLICY IF EXISTS anexos_select ON public.chamado_anexos;
CREATE POLICY anexos_select ON public.chamado_anexos
FOR SELECT
USING (
  (current_internal_access_level() IS NOT NULL
   AND current_internal_access_level() <> 'cliente_view'::internal_access_level)
  OR EXISTS (
    SELECT 1 FROM public.chamados c
    WHERE c.id = chamado_anexos.chamado_id
      AND c.solicitante_id = auth.uid()
  )
);

-- chamado_interacoes
DROP POLICY IF EXISTS interacoes_select ON public.chamado_interacoes;
CREATE POLICY interacoes_select ON public.chamado_interacoes
FOR SELECT
USING (
  (current_internal_access_level() IS NOT NULL
   AND current_internal_access_level() <> 'cliente_view'::internal_access_level)
  OR (
    interno = false
    AND EXISTS (
      SELECT 1 FROM public.chamados c
      WHERE c.id = chamado_interacoes.chamado_id
        AND c.solicitante_id = auth.uid()
    )
  )
);

-- chamado_historico
DROP POLICY IF EXISTS historico_select ON public.chamado_historico;
CREATE POLICY historico_select ON public.chamado_historico
FOR SELECT
USING (
  (current_internal_access_level() IS NOT NULL
   AND current_internal_access_level() <> 'cliente_view'::internal_access_level)
  OR EXISTS (
    SELECT 1 FROM public.chamados c
    WHERE c.id = chamado_historico.chamado_id
      AND c.solicitante_id = auth.uid()
  )
);