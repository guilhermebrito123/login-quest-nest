-- Disable the validate_superior_update_trigger
ALTER TABLE public.usuarios DISABLE TRIGGER validate_superior_update_trigger;

-- Update existing records to enforce the rule
UPDATE public.usuarios
SET superior = NULL
WHERE role IN ('candidato', 'colaborador') AND superior IS NOT NULL;

-- Re-enable the trigger
ALTER TABLE public.usuarios ENABLE TRIGGER validate_superior_update_trigger;