-- Adicionar campos pix_alternativo e beneficiario_alternativo à tabela diarias_temporarias
ALTER TABLE public.diarias_temporarias 
ADD COLUMN IF NOT EXISTS pix_alternativo text,
ADD COLUMN IF NOT EXISTS beneficiario_alternativo text;