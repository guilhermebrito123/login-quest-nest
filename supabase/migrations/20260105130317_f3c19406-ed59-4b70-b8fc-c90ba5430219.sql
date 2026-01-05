-- Atualizar função para validar motivos, compatível com enum motivo_reprovacao
CREATE OR REPLACE FUNCTION public.validar_motivos_diaria_temporaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- Validar motivo_reprovacao quando status é Reprovada (agora é ENUM, não precisa de TRIM)
  IF NEW.status = 'Reprovada'::status_diaria AND NEW.motivo_reprovacao IS NULL THEN
    RAISE EXCEPTION 'O campo motivo_reprovacao é obrigatório quando o status é Reprovada';
  END IF;
  
  -- Validar motivo_cancelamento quando status é Cancelada
  IF NEW.status = 'Cancelada'::status_diaria AND (NEW.motivo_cancelamento IS NULL OR TRIM(NEW.motivo_cancelamento) = '') THEN
    RAISE EXCEPTION 'O campo motivo_cancelamento é obrigatório quando o status é Cancelada';
  END IF;
  
  RETURN NEW;
END;
$function$;