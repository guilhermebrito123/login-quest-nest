-- Tornar pix opcional (permitir null)
ALTER TABLE public.diaristas ALTER COLUMN pix DROP NOT NULL;

-- Tornar telefone opcional (permitir null)
ALTER TABLE public.diaristas ALTER COLUMN telefone DROP NOT NULL;

-- Tornar cpf obrigatório (não permitir null)
ALTER TABLE public.diaristas ALTER COLUMN cpf SET NOT NULL;