-- Função para validar que um diarista não tenha duas diárias na mesma data
CREATE OR REPLACE FUNCTION public.validar_duplicidade_diaria_temporaria()
RETURNS TRIGGER AS $$
BEGIN
  -- Verificar se já existe uma diária para este diarista na mesma data
  IF EXISTS (
    SELECT 1 FROM public.diarias_temporarias
    WHERE diarista_id = NEW.diarista_id
      AND data_diaria = NEW.data_diaria
      AND id != COALESCE(NEW.id, -1)
  ) THEN
    RAISE EXCEPTION 'Este diarista já possui uma diária para esta data';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para executar a validação antes de insert ou update
DROP TRIGGER IF EXISTS validar_duplicidade_diaria_temporaria_trigger ON public.diarias_temporarias;
CREATE TRIGGER validar_duplicidade_diaria_temporaria_trigger
  BEFORE INSERT OR UPDATE ON public.diarias_temporarias
  FOR EACH ROW
  EXECUTE FUNCTION public.validar_duplicidade_diaria_temporaria();