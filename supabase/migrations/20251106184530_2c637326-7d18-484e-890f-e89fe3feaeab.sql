-- Drop triggers first
DROP TRIGGER IF EXISTS trigger_notificar_cargo_lideranca_insert ON public.colaboradores;
DROP TRIGGER IF EXISTS trigger_notificar_cargo_lideranca_update ON public.colaboradores;
DROP FUNCTION IF EXISTS public.notificar_cargo_lideranca();

-- Now remove cargo_id column and add cargo as text field
ALTER TABLE public.colaboradores 
DROP COLUMN IF EXISTS cargo_id CASCADE;

ALTER TABLE public.colaboradores 
ADD COLUMN cargo TEXT;

-- Drop the cargos table
DROP TABLE IF EXISTS public.cargos CASCADE;