-- Add 'restrito' to status_diarista enum
ALTER TYPE status_diarista ADD VALUE IF NOT EXISTS 'restrito';

-- Add motivo_restricao column to diaristas table
ALTER TABLE public.diaristas 
ADD COLUMN IF NOT EXISTS motivo_restricao text DEFAULT NULL;

-- Create trigger function to clear motivo_restricao when status changes from 'restrito'
CREATE OR REPLACE FUNCTION public.clear_motivo_restricao()
RETURNS TRIGGER AS $$
BEGIN
  -- If status is changing to something other than 'restrito', clear motivo_restricao
  IF NEW.status IS DISTINCT FROM 'restrito'::status_diarista THEN
    NEW.motivo_restricao := NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS clear_motivo_restricao_trigger ON public.diaristas;
CREATE TRIGGER clear_motivo_restricao_trigger
  BEFORE UPDATE ON public.diaristas
  FOR EACH ROW
  EXECUTE FUNCTION public.clear_motivo_restricao();