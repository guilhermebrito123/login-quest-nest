-- Update created_at default to use Brazilian timezone
ALTER TABLE public.diarias_temporarias 
ALTER COLUMN created_at SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo');

-- Update updated_at default to use Brazilian timezone
ALTER TABLE public.diarias_temporarias 
ALTER COLUMN updated_at SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo');