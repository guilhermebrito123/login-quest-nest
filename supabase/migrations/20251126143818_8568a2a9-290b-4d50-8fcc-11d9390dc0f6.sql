-- Criar trigger para limpar motivos ao mudar status
CREATE OR REPLACE FUNCTION public.limpar_motivos_diaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  -- Se o status mudou de "Cancelada" para outro status, limpar motivo_cancelamento
  IF OLD.status = 'Cancelada'::status_diaria AND NEW.status != 'Cancelada'::status_diaria THEN
    NEW.motivo_cancelamento := NULL;
  END IF;
  
  -- Se o status mudou de "Reprovada" para outro status, limpar motivo_reprovacao
  IF OLD.status = 'Reprovada'::status_diaria AND NEW.status != 'Reprovada'::status_diaria THEN
    NEW.motivo_reprovacao := NULL;
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Criar trigger para executar antes de update
DROP TRIGGER IF EXISTS limpar_motivos_diaria_trigger ON public.diarias;
CREATE TRIGGER limpar_motivos_diaria_trigger
  BEFORE UPDATE ON public.diarias
  FOR EACH ROW
  EXECUTE FUNCTION public.limpar_motivos_diaria();