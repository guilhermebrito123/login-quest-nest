-- Índices para acelerar listagens paginadas de diarias_temporarias por status
CREATE INDEX IF NOT EXISTS idx_diarias_temp_status_data_diaria_desc
  ON public.diarias_temporarias (status, data_diaria DESC);

CREATE INDEX IF NOT EXISTS idx_diarias_temp_status_created_at_desc
  ON public.diarias_temporarias (status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_diarias_temp_status_diarista_data
  ON public.diarias_temporarias (status, diarista_id, data_diaria DESC);

CREATE INDEX IF NOT EXISTS idx_diarias_temp_status_centro_data
  ON public.diarias_temporarias (status, centro_custo_id, data_diaria DESC);

ANALYZE public.diarias_temporarias;