-- Make posto_servico_id optional
ALTER TABLE public.diarias_temporarias
ALTER COLUMN posto_servico_id DROP NOT NULL;

-- Add new optional string attributes
ALTER TABLE public.diarias_temporarias
ADD COLUMN colaborador_ausente_nome text,
ADD COLUMN posto_servico text,
ADD COLUMN cliente_nome text;