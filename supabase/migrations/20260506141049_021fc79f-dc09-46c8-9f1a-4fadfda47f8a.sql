CREATE OR REPLACE FUNCTION public.get_profiles_names(p_ids uuid[])
RETURNS TABLE (
  id uuid,
  full_name text,
  email text,
  display_name text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    u.id,
    u.full_name,
    u.email,
    COALESCE(NULLIF(u.full_name, ''), NULLIF(u.email, ''), u.id::text) AS display_name
  FROM public.usuarios u
  WHERE u.id = ANY(p_ids);
$$;

GRANT EXECUTE ON FUNCTION public.get_profiles_names(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_profiles_names(uuid[]) TO anon;

NOTIFY pgrst, 'reload schema';