
-- Trigger function to sync colaboradores changes to usuarios
CREATE OR REPLACE FUNCTION public.sync_colaborador_to_usuario()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only sync if common fields have changed
  IF OLD.nome_completo IS DISTINCT FROM NEW.nome_completo 
     OR OLD.email IS DISTINCT FROM NEW.email 
     OR OLD.telefone IS DISTINCT FROM NEW.telefone THEN
    
    UPDATE public.usuarios
    SET 
      full_name = NEW.nome_completo,
      email = NEW.email,
      phone = NEW.telefone,
      updated_at = now()
    WHERE id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger for colaboradores
DROP TRIGGER IF EXISTS sync_colaborador_to_usuario_trigger ON public.colaboradores;
CREATE TRIGGER sync_colaborador_to_usuario_trigger
  AFTER UPDATE ON public.colaboradores
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_colaborador_to_usuario();

-- Trigger function to sync internal_profiles changes to usuarios
CREATE OR REPLACE FUNCTION public.sync_internal_profile_to_usuario()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only sync if common fields have changed
  IF OLD.nome_completo IS DISTINCT FROM NEW.nome_completo 
     OR OLD.email IS DISTINCT FROM NEW.email 
     OR OLD.phone IS DISTINCT FROM NEW.phone THEN
    
    UPDATE public.usuarios
    SET 
      full_name = NEW.nome_completo,
      email = NEW.email,
      phone = NEW.phone,
      updated_at = now()
    WHERE id = NEW.user_id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger for internal_profiles
DROP TRIGGER IF EXISTS sync_internal_profile_to_usuario_trigger ON public.internal_profiles;
CREATE TRIGGER sync_internal_profile_to_usuario_trigger
  AFTER UPDATE ON public.internal_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_internal_profile_to_usuario();

-- Update existing sync_candidato_to_usuario function to ensure consistency
CREATE OR REPLACE FUNCTION public.sync_candidato_to_usuario()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only sync if common fields have changed
  IF OLD.nome_completo IS DISTINCT FROM NEW.nome_completo 
     OR OLD.email IS DISTINCT FROM NEW.email 
     OR OLD.telefone IS DISTINCT FROM NEW.telefone THEN
    
    UPDATE public.usuarios
    SET 
      full_name = NEW.nome_completo,
      email = NEW.email,
      phone = NEW.telefone,
      updated_at = now()
    WHERE id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Ensure trigger exists for candidatos
DROP TRIGGER IF EXISTS sync_candidato_to_usuario_trigger ON public.candidatos;
CREATE TRIGGER sync_candidato_to_usuario_trigger
  AFTER UPDATE ON public.candidatos
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_candidato_to_usuario();
