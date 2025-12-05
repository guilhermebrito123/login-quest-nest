-- Remover o valor default de intervalo para torná-lo verdadeiramente opcional
ALTER TABLE public.diarias_temporarias
ALTER COLUMN intervalo DROP DEFAULT;

COMMENT ON COLUMN public.diarias_temporarias.intervalo IS 'Intervalo de refeição em minutos (opcional)';