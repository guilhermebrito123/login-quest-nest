-- Tornar o campo CPF opcional na tabela colaboradores
ALTER TABLE public.colaboradores ALTER COLUMN cpf DROP NOT NULL;