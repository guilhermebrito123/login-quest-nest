-- Adicionar valor "Reprovada" ao enum status_diaria
ALTER TYPE status_diaria ADD VALUE IF NOT EXISTS 'Reprovada';

-- Adicionar colunas motivo_reprovacao e motivo_cancelamento à tabela diarias
ALTER TABLE public.diarias 
  ADD COLUMN motivo_reprovacao text,
  ADD COLUMN motivo_cancelamento text;

-- Criar função de validação para motivos
CREATE OR REPLACE FUNCTION public.validar_motivos_diaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  -- Validar motivo_reprovacao quando status é "Reprovada"
  IF NEW.status = 'Reprovada'::status_diaria AND (NEW.motivo_reprovacao IS NULL OR TRIM(NEW.motivo_reprovacao) = '') THEN
    RAISE EXCEPTION 'O campo motivo_reprovacao é obrigatório quando o status é "Reprovada"';
  END IF;
  
  -- Validar motivo_cancelamento quando status é "Cancelada"
  IF NEW.status = 'Cancelada'::status_diaria AND (NEW.motivo_cancelamento IS NULL OR TRIM(NEW.motivo_cancelamento) = '') THEN
    RAISE EXCEPTION 'O campo motivo_cancelamento é obrigatório quando o status é "Cancelada"';
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Criar trigger para validar motivos antes de insert ou update
CREATE TRIGGER validar_motivos_diaria_trigger
  BEFORE INSERT OR UPDATE ON public.diarias
  FOR EACH ROW
  EXECUTE FUNCTION public.validar_motivos_diaria();