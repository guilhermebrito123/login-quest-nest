-- Store full Convenia payload for each employee
ALTER TABLE public.colaboradores_convenia
ADD COLUMN IF NOT EXISTS raw_data JSONB;