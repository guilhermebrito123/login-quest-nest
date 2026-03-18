
DROP INDEX IF EXISTS diaristas_cpf_normalizado_unique;
ALTER TABLE public.diaristas DROP COLUMN IF EXISTS cpf_normalizado;
