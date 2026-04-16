
-- Chamados: colaborador vê os próprios
DROP POLICY IF EXISTS chamados_select ON public.chamados;
CREATE POLICY chamados_select ON public.chamados
FOR SELECT
USING (
  is_internal_user()
  OR solicitante_id = auth.uid()
);

-- Anexos: colaborador vê anexos de chamados que abriu
DROP POLICY IF EXISTS anexos_select ON public.chamado_anexos;
CREATE POLICY anexos_select ON public.chamado_anexos
FOR SELECT
USING (
  is_internal_user()
  OR EXISTS (
    SELECT 1 FROM public.chamados c
    WHERE c.id = chamado_anexos.chamado_id
      AND c.solicitante_id = auth.uid()
  )
);

-- Interações: colaborador vê interações NÃO internas dos próprios chamados
DROP POLICY IF EXISTS interacoes_select ON public.chamado_interacoes;
CREATE POLICY interacoes_select ON public.chamado_interacoes
FOR SELECT
USING (
  is_internal_user()
  OR (
    interno = false
    AND EXISTS (
      SELECT 1 FROM public.chamados c
      WHERE c.id = chamado_interacoes.chamado_id
        AND c.solicitante_id = auth.uid()
    )
  )
);

-- Histórico: colaborador vê histórico dos próprios chamados
DROP POLICY IF EXISTS historico_select ON public.chamado_historico;
CREATE POLICY historico_select ON public.chamado_historico
FOR SELECT
USING (
  is_internal_user()
  OR EXISTS (
    SELECT 1 FROM public.chamados c
    WHERE c.id = chamado_historico.chamado_id
      AND c.solicitante_id = auth.uid()
  )
);
