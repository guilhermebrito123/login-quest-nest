-- Adicionar coluna faturamento_vendido à tabela unidades
-- Primeiro adiciona com default temporário para preencher registros existentes
ALTER TABLE public.unidades
ADD COLUMN faturamento_vendido numeric NOT NULL DEFAULT 5000.00;

-- Remove o default para que novos registros precisem informar o valor
ALTER TABLE public.unidades
ALTER COLUMN faturamento_vendido DROP DEFAULT;