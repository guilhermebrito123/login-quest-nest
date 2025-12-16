
-- Fix remaining functions referencing non-existent public.app_role enum

CREATE OR REPLACE FUNCTION public.handle_new_user_role()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.user_roles (user_id, role)
  VALUES (NEW.id, 'admin'::internal_access_level)
  ON CONFLICT (user_id, role) DO NOTHING;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.is_admin(_user_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.internal_profiles
    WHERE user_id = _user_id
      AND nivel_acesso = 'admin'::internal_access_level
  )
$function$;

CREATE OR REPLACE FUNCTION public.validate_superior_update()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- If superior is being changed and user is not admin, reject
  IF (OLD.superior IS DISTINCT FROM NEW.superior) THEN
    IF NOT has_role(auth.uid(), 'admin'::internal_access_level) THEN
      RAISE EXCEPTION 'Apenas administradores podem definir o superior de um usuário';
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.handle_new_internal_profile()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.internal_profiles (user_id, nivel_acesso)
  VALUES (NEW.id, 'cliente_view'::internal_access_level)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$function$;
