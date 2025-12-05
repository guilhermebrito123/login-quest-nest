-- Adicionar colunas de horário na tabela diarias_temporarias
-- Usando TIME WITHOUT TIME ZONE (a aplicação deve tratar como fuso brasileiro)
-- jornada_diaria é calculada automaticamente em minutos

ALTER TABLE public.diarias_temporarias
ADD COLUMN horario_inicio TIME WITHOUT TIME ZONE,
ADD COLUMN horario_fim TIME WITHOUT TIME ZONE,
ADD COLUMN jornada_diaria INTEGER GENERATED ALWAYS AS (
  EXTRACT(EPOCH FROM (horario_fim - horario_inicio))::INTEGER / 60
) STORED;

COMMENT ON COLUMN public.diarias_temporarias.horario_inicio IS 'Horário de início - usar fuso horário brasileiro (America/Sao_Paulo)';
COMMENT ON COLUMN public.diarias_temporarias.horario_fim IS 'Horário de fim - usar fuso horário brasileiro (America/Sao_Paulo)';
COMMENT ON COLUMN public.diarias_temporarias.jornada_diaria IS 'Jornada diária em minutos, calculada automaticamente (horario_fim - horario_inicio)';