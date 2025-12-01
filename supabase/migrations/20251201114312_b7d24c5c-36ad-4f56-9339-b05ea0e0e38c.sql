-- Remove status, codigo, and criticidade columns from unidades table
ALTER TABLE public.unidades
  DROP COLUMN IF EXISTS status,
  DROP COLUMN IF EXISTS codigo,
  DROP COLUMN IF EXISTS criticidade;