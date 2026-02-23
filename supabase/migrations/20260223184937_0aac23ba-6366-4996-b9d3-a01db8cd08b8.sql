
-- Tornar diaria_temporaria_id nullable
ALTER TABLE public.faltas_colaboradores_convenia
  ALTER COLUMN diaria_temporaria_id DROP NOT NULL;

-- Remover constraint unique antiga se existir
ALTER TABLE public.faltas_colaboradores_convenia
  DROP CONSTRAINT IF EXISTS faltas_colaboradores_convenia_diaria_temporaria_id_key;

-- Criar índice único parcial (permite múltiplos NULLs)
CREATE UNIQUE INDEX IF NOT EXISTS ux_faltas_diaria_not_null
  ON public.faltas_colaboradores_convenia(diaria_temporaria_id)
  WHERE diaria_temporaria_id IS NOT NULL;
