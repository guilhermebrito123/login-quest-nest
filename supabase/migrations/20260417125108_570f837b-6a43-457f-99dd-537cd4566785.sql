CREATE OR REPLACE FUNCTION public.get_visible_internal_users_public()
RETURNS TABLE (
  id uuid,
  full_name text,
  cargo text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
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
        public.current_internal_access_level() IS NOT NULL
        AND public.current_internal_access_level() <> 'cliente_view'::internal_access_level
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
$$;

REVOKE ALL ON FUNCTION public.get_visible_internal_users_public() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_visible_internal_users_public() TO authenticated;

CREATE OR REPLACE VIEW public.usuarios_public
WITH (security_invoker = on) AS
SELECT *
FROM public.get_visible_internal_users_public();

REVOKE ALL ON public.usuarios_public FROM anon;
GRANT SELECT ON public.usuarios_public TO authenticated;