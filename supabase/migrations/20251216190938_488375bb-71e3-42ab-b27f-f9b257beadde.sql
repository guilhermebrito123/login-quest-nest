
-- Fix handle_new_user trigger to use correct enum type
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.usuarios (id, email, full_name, phone)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    NULLIF(NEW.raw_user_meta_data->>'phone', '')
  );
  
  -- Novos usuários começam com role "cliente_view"
  INSERT INTO public.user_roles (user_id, role)
  VALUES (NEW.id, 'cliente_view'::internal_access_level);
  
  RETURN NEW;
END;
$function$;
