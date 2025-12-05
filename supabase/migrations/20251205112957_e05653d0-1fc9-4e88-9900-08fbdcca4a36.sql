-- Alterar jornada_diaria para calcular em horas ao invés de minutos
ALTER TABLE public.diarias_temporarias
DROP COLUMN jornada_diaria;

ALTER TABLE public.diarias_temporarias
ADD COLUMN jornada_diaria INTEGER GENERATED ALWAYS AS (
  EXTRACT(EPOCH FROM (horario_fim - horario_inicio))::INTEGER / 3600
) STORED;

COMMENT ON COLUMN public.diarias_temporarias.jornada_diaria IS 'Jornada diária em horas, calculada automaticamente (horario_fim - horario_inicio)';