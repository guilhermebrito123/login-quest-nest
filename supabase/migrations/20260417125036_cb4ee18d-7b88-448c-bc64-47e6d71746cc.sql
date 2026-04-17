DROP POLICY IF EXISTS "Autenticados podem ler usuarios internos nao cliente_view" ON public.usuarios;

CREATE OR REPLACE VIEW public.usuarios_public AS
SELECT
  u.id,
  u.full_name,
  ip.cargo
FROM public.usuarios u
JOIN public.internal_profiles ip ON ip.user_id = u.id
WHERE u.role = 'perfil_interno'::user_type
  AND ip.nivel_acesso IS NOT NULL
  AND ip.nivel_acesso <> 'cliente_view'::internal_access_level
  AND (
    (
      current_internal_access_level() IS NOT NULL
      AND current_internal_access_level() <> 'cliente_view'::internal_access_level
    )
    OR EXISTS (
      SELECT 1
      FROM public.chamados c
      JOIN public.usuarios viewer ON viewer.id = auth.uid()
      WHERE viewer.role = 'colaborador'::user_type
        AND c.solicitante_id = auth.uid()
        AND c.responsavel_id = u.id
    )
  );

ALTER VIEW public.usuarios_public SET (security_invoker = false);
REVOKE ALL ON public.usuarios_public FROM anon;
GRANT SELECT ON public.usuarios_public TO authenticated;