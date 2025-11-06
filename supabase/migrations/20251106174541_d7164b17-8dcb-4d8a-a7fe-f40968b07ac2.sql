-- Atualizar enum de perfis para incluir os novos tipos
ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'gestor_operacoes';
ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'supervisor';
ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'analista_centro_controle';
ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'tecnico';
ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'cliente_view';

-- Atualizar todos os usuários existentes para admin
UPDATE public.user_roles 
SET role = 'admin'::app_role 
WHERE role != 'admin'::app_role;

-- Criar trigger para novos usuários serem admin por padrão
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
  
  -- Todos os novos usuários começam como admin
  INSERT INTO public.user_roles (user_id, role)
  VALUES (NEW.id, 'admin'::app_role);
  
  RETURN NEW;
END;
$function$;