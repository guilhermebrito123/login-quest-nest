-- Add demissao and colaborador_demitido columns to diarias_temporarias
ALTER TABLE public.diarias_temporarias
ADD COLUMN demissao boolean DEFAULT NULL,
ADD COLUMN colaborador_demitido uuid DEFAULT NULL REFERENCES public.colaboradores(id) ON DELETE SET NULL;

-- Create trigger function to validate diarias_temporarias logic
CREATE OR REPLACE FUNCTION public.validar_diarias_temporarias_motivo_vago()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- Se motivo_vago é 'VAGA EM ABERTO (COBERTURA SALÁRIO)'
  IF NEW.motivo_vago = 'VAGA EM ABERTO (COBERTURA SALÁRIO)'::motivo_vago_type THEN
    -- colaborador_ausente deve ser NULL
    NEW.colaborador_ausente := NULL;
    
    -- Se demissao é false ou null, colaborador_demitido deve ser NULL
    IF NEW.demissao IS NULL OR NEW.demissao = false THEN
      NEW.colaborador_demitido := NULL;
    END IF;
  ELSE
    -- Para outros valores de motivo_vago, demissao e colaborador_demitido devem ser NULL
    NEW.demissao := NULL;
    NEW.colaborador_demitido := NULL;
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Create trigger
DROP TRIGGER IF EXISTS validar_diarias_temporarias_motivo_vago_trigger ON public.diarias_temporarias;
CREATE TRIGGER validar_diarias_temporarias_motivo_vago_trigger
BEFORE INSERT OR UPDATE ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.validar_diarias_temporarias_motivo_vago();