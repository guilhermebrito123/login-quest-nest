-- Create trigger function to sync candidatos changes to usuarios
CREATE OR REPLACE FUNCTION public.sync_candidato_to_usuario()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- Update usuarios when candidatos is modified
  UPDATE public.usuarios
  SET 
    email = NEW.email,
    full_name = NEW.nome_completo,
    phone = NEW.telefone,
    updated_at = now()
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$function$;

-- Create trigger on candidatos table
CREATE TRIGGER on_candidato_update_sync_usuario
  AFTER UPDATE ON public.candidatos
  FOR EACH ROW
  WHEN (
    OLD.email IS DISTINCT FROM NEW.email OR
    OLD.nome_completo IS DISTINCT FROM NEW.nome_completo OR
    OLD.telefone IS DISTINCT FROM NEW.telefone
  )
  EXECUTE FUNCTION public.sync_candidato_to_usuario();