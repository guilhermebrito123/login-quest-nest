
-- 1. Função PL/pgSQL atualizada
CREATE OR REPLACE FUNCTION public.validar_duplicidade_diaria_temporaria()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.diarias_temporarias
    WHERE diarista_id = NEW.diarista_id
      AND data_diaria = NEW.data_diaria
      AND id <> COALESCE(NEW.id, -1)
      AND status NOT IN ('Cancelada', 'Reprovada')
  ) THEN
    RAISE EXCEPTION 'Este diarista já possui uma diária ativa para esta data';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Trigger (INSERT + UPDATE)
DROP TRIGGER IF EXISTS validar_duplicidade_diaria_temporaria_trigger
ON public.diarias_temporarias;

CREATE TRIGGER validar_duplicidade_diaria_temporaria_trigger
BEFORE INSERT OR UPDATE
ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.validar_duplicidade_diaria_temporaria();

-- 3. Índice único parcial para garantia absoluta de integridade
CREATE UNIQUE INDEX IF NOT EXISTS uniq_diaria_ativa_por_diarista_data
ON public.diarias_temporarias (diarista_id, data_diaria)
WHERE status NOT IN ('Cancelada', 'Reprovada');
