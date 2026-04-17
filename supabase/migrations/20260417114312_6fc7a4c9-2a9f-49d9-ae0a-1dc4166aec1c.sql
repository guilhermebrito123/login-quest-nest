-- 1) chamados_update: colaborador solicitante também pode atualizar o próprio chamado
DROP POLICY IF EXISTS chamados_update ON public.chamados;
CREATE POLICY chamados_update ON public.chamados
FOR UPDATE
USING (
  (current_internal_access_level() IS NOT NULL
   AND current_internal_access_level() <> 'cliente_view'::internal_access_level)
  OR (
    solicitante_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.role = 'colaborador'::user_type
    )
  )
)
WITH CHECK (
  (current_internal_access_level() IS NOT NULL
   AND current_internal_access_level() <> 'cliente_view'::internal_access_level)
  OR (
    solicitante_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.role = 'colaborador'::user_type
    )
  )
);

-- 2) chamados_insert: colaborador só pode abrir chamado para LOCAL pertencente ao cost_center atual dele
DROP POLICY IF EXISTS chamados_insert ON public.chamados;
CREATE POLICY chamados_insert ON public.chamados
FOR INSERT
WITH CHECK (
  -- Internos (qualquer nível, inclusive cliente_view mantém comportamento prévio) podem abrir
  current_internal_access_level() IS NOT NULL
  OR (
    -- Colaborador: precisa ser solicitante = auth.uid() e local pertencer ao cost_center atual ativo
    solicitante_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM public.usuarios u
      JOIN public.colaborador_profiles cp ON cp.user_id = u.id
      JOIN public.cost_center_locais l ON l.cost_center_id = cp.cost_center_id
      WHERE u.id = auth.uid()
        AND u.role = 'colaborador'::user_type
        AND cp.ativo = true
        AND l.id = chamados.local_id
    )
  )
);