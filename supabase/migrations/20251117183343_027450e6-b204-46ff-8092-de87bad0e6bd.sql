-- Adicionar nova role "cliente_view" ao enum app_role
ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'cliente_view';

-- Atualizar a função handle_new_user para criar novos usuários com role "cliente_view"
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name'
  );
  
  -- Novos usuários começam com role "cliente_view"
  INSERT INTO public.user_roles (user_id, role)
  VALUES (NEW.id, 'cliente_view'::app_role);
  
  RETURN NEW;
END;
$function$;