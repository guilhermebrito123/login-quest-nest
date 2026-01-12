-- Criar trigger para validar que motivo_restricao é obrigatório quando status = 'restrito'
CREATE OR REPLACE FUNCTION public.validar_motivo_restricao_diarista()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'restrito' AND (NEW.motivo_restricao IS NULL OR TRIM(NEW.motivo_restricao) = '') THEN
    RAISE EXCEPTION 'O campo motivo_restricao é obrigatório quando o status é "restrito"';
  END IF;
  
  -- Limpar motivo_restricao se status mudar para outro valor diferente de 'restrito'
  IF NEW.status IS DISTINCT FROM 'restrito' THEN
    NEW.motivo_restricao := NULL;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Remover trigger existente se houver
DROP TRIGGER IF EXISTS validar_motivo_restricao_diarista_trigger ON public.diaristas;

-- Criar trigger
CREATE TRIGGER validar_motivo_restricao_diarista_trigger
BEFORE INSERT OR UPDATE ON public.diaristas
FOR EACH ROW
EXECUTE FUNCTION public.validar_motivo_restricao_diarista();