-- Corrigir cálculo de jornada_diaria para turnos noturnos (quando horario_fim < horario_inicio)
-- Primeiro, remover a coluna gerada existente
ALTER TABLE public.diarias_temporarias
DROP COLUMN jornada_diaria;

-- Recriar a coluna com a fórmula correta que considera turnos noturnos
-- Se horario_fim < horario_inicio, adiciona 24 horas (1440 minutos) ao cálculo
ALTER TABLE public.diarias_temporarias
ADD COLUMN jornada_diaria NUMERIC(5,2) GENERATED ALWAYS AS (
  CASE 
    WHEN horario_inicio IS NULL OR horario_fim IS NULL THEN NULL
    ELSE (
      (
        EXTRACT(EPOCH FROM (horario_fim - horario_inicio))::INTEGER / 60 
        + CASE WHEN horario_fim < horario_inicio THEN 1440 ELSE 0 END
      ) 
      - COALESCE(intervalo, 0)
    ) / 60.0
  END
) STORED;

COMMENT ON COLUMN public.diarias_temporarias.jornada_diaria IS 'Jornada diária em horas, calculada automaticamente considerando turnos noturnos: (horario_fim - horario_inicio + 24h se overnight) - intervalo';