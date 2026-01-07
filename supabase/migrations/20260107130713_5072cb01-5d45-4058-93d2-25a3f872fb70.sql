-- Drop existing triggers and functions if they exist
DROP TRIGGER IF EXISTS validar_diarista_restrito_diarias_trigger ON public.diarias;
DROP TRIGGER IF EXISTS validar_diarista_restrito_diarias_temporarias_trigger ON public.diarias_temporarias;
DROP FUNCTION IF EXISTS public.validar_diarista_restrito_diarias();
DROP FUNCTION IF EXISTS public.validar_diarista_restrito_diarias_temporarias();

-- Function to validate diarista status for diarias table
CREATE OR REPLACE FUNCTION public.validar_diarista_restrito_diarias()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.diarista_id IS NOT NULL THEN
    IF EXISTS (
      SELECT 1 FROM public.diaristas 
      WHERE id = NEW.diarista_id AND status = 'restrito'
    ) THEN
      RAISE EXCEPTION 'Não é possível vincular um diarista com status "restrito" a uma diária';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Function to validate diarista status for diarias_temporarias table
CREATE OR REPLACE FUNCTION public.validar_diarista_restrito_diarias_temporarias()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.diarista_id IS NOT NULL THEN
    IF EXISTS (
      SELECT 1 FROM public.diaristas 
      WHERE id = NEW.diarista_id AND status = 'restrito'
    ) THEN
      RAISE EXCEPTION 'Não é possível vincular um diarista com status "restrito" a uma diária';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Trigger for diarias table
CREATE TRIGGER validar_diarista_restrito_diarias_trigger
BEFORE INSERT OR UPDATE OF diarista_id ON public.diarias
FOR EACH ROW
EXECUTE FUNCTION public.validar_diarista_restrito_diarias();

-- Trigger for diarias_temporarias table
CREATE TRIGGER validar_diarista_restrito_diarias_temporarias_trigger
BEFORE INSERT OR UPDATE OF diarista_id ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.validar_diarista_restrito_diarias_temporarias();