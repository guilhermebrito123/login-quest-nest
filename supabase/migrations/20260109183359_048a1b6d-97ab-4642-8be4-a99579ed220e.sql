-- Remove pix_alternativo and beneficiario_alternativo columns
ALTER TABLE public.diarias_temporarias 
DROP COLUMN IF EXISTS pix_alternativo,
DROP COLUMN IF EXISTS beneficiario_alternativo;