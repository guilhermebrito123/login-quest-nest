CREATE OR REPLACE VIEW public.usuarios_public
WITH (security_invoker = on) AS
SELECT
  u.id,
  u.full_name,
  ip.cargo
FROM public.usuarios u
JOIN public.internal_profiles ip ON ip.user_id = u.id
WHERE u.role = 'perfil_interno'::user_type
  AND ip.nivel_acesso IS NOT NULL
  AND ip.nivel_acesso <> 'cliente_view'::internal_access_level;

DROP POLICY IF EXISTS "Autenticados podem ler usuarios internos nao cliente_view" ON public.usuarios;
CREATE POLICY "Autenticados podem ler usuarios internos nao cliente_view"
ON public.usuarios
FOR SELECT
TO authenticated
USING (
  role = 'perfil_interno'::user_type
  AND EXISTS (
    SELECT 1 FROM public.internal_profiles ip
    WHERE ip.user_id = usuarios.id
      AND ip.nivel_acesso IS NOT NULL
      AND ip.nivel_acesso <> 'cliente_view'::internal_access_level
  )
);

GRANT SELECT ON public.usuarios_public TO authenticated, anon;