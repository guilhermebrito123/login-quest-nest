-- Atualizar registros existentes com valor padrão
UPDATE public.diarias_temporarias
SET motivo_vago = 'falta injustificada'::motivo_vago_type
WHERE motivo_vago IS NULL;

-- Tornar motivo_vago NOT NULL com valor padrão
ALTER TABLE public.diarias_temporarias
ALTER COLUMN motivo_vago SET DEFAULT 'falta injustificada'::motivo_vago_type,
ALTER COLUMN motivo_vago SET NOT NULL;