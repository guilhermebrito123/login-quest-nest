
-- Create or replace the function to enforce superior = null and remove internal_profiles
CREATE OR REPLACE FUNCTION public.enforce_superior_null_for_non_internal()
RETURNS TRIGGER AS $$
BEGIN
  -- If role is candidato or colaborador, set superior to null
  IF NEW.role IN ('candidato', 'colaborador') THEN
    NEW.superior := NULL;
    
    -- If role changed FROM perfil_interno TO candidato/colaborador, delete internal_profiles record
    IF TG_OP = 'UPDATE' AND OLD.role = 'perfil_interno' THEN
      DELETE FROM public.internal_profiles WHERE user_id = NEW.id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS enforce_superior_null_trigger ON public.usuarios;

-- Create the trigger (must run BEFORE validate_superior_update_trigger)
CREATE TRIGGER enforce_superior_null_trigger
BEFORE INSERT OR UPDATE ON public.usuarios
FOR EACH ROW
EXECUTE FUNCTION public.enforce_superior_null_for_non_internal();

-- Temporarily disable the validate_superior_update_trigger to allow cleanup
ALTER TABLE public.usuarios DISABLE TRIGGER validate_superior_update_trigger;

-- Clean up existing data: set superior to null for candidato/colaborador
UPDATE public.usuarios
SET superior = NULL
WHERE role IN ('candidato', 'colaborador') AND superior IS NOT NULL;

-- Re-enable the trigger
ALTER TABLE public.usuarios ENABLE TRIGGER validate_superior_update_trigger;

-- Clean up existing data: remove internal_profiles for non perfil_interno users
DELETE FROM public.internal_profiles
WHERE user_id IN (
  SELECT id FROM public.usuarios WHERE role IN ('candidato', 'colaborador')
);
