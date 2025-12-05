-- Remover jornada_diaria atual
ALTER TABLE public.diarias_temporarias
DROP COLUMN jornada_diaria;

-- Adicionar coluna intervalo (em minutos)
ALTER TABLE public.diarias_temporarias
ADD COLUMN intervalo INTEGER DEFAULT 0;

COMMENT ON COLUMN public.diarias_temporarias.intervalo IS 'Intervalo de refeição em minutos';

-- Adicionar jornada_diaria calculada: (horario_fim - horario_inicio em minutos) - intervalo, convertido para horas
ALTER TABLE public.diarias_temporarias
ADD COLUMN jornada_diaria NUMERIC(5,2) GENERATED ALWAYS AS (
  (EXTRACT(EPOCH FROM (horario_fim - horario_inicio))::INTEGER / 60 - COALESCE(intervalo, 0)) / 60.0
) STORED;

COMMENT ON COLUMN public.diarias_temporarias.jornada_diaria IS 'Jornada diária em horas, calculada automaticamente: (horario_fim - horario_inicio - intervalo)';