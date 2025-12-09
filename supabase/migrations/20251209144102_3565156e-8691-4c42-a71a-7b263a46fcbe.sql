-- Tornar o atributo cpf opcional na tabela diaristas
ALTER TABLE public.diaristas
ALTER COLUMN cpf DROP NOT NULL;