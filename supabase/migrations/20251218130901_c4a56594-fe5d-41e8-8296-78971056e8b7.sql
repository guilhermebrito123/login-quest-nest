
-- Trigger function to sync usuarios changes to the corresponding subclass table
CREATE OR REPLACE FUNCTION public.sync_usuario_to_subclass()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only sync if common fields have changed
  IF OLD.full_name IS DISTINCT FROM NEW.full_name 
     OR OLD.email IS DISTINCT FROM NEW.email 
     OR OLD.phone IS DISTINCT FROM NEW.phone THEN
    
    -- Sync based on user role
    IF NEW.role = 'candidato' THEN
      UPDATE public.candidatos
      SET 
        nome_completo = NEW.full_name,
        email = NEW.email,
        telefone = NEW.phone,
        updated_at = now()
      WHERE id = NEW.id;
      
    ELSIF NEW.role = 'colaborador' THEN
      UPDATE public.colaboradores
      SET 
        nome_completo = NEW.full_name,
        email = NEW.email,
        telefone = NEW.phone,
        updated_at = now()
      WHERE id = NEW.id;
      
    ELSIF NEW.role = 'perfil_interno' THEN
      UPDATE public.internal_profiles
      SET 
        nome_completo = NEW.full_name,
        email = NEW.email,
        phone = NEW.phone,
        updated_at = now()
      WHERE user_id = NEW.id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger for usuarios (sync to subclass tables)
DROP TRIGGER IF EXISTS sync_usuario_to_subclass_trigger ON public.usuarios;
CREATE TRIGGER sync_usuario_to_subclass_trigger
  AFTER UPDATE ON public.usuarios
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_usuario_to_subclass();
