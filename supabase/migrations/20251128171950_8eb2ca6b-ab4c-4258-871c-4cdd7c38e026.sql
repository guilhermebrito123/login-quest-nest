-- Adicionar coluna nome_fantasia à tabela clientes
ALTER TABLE public.clientes 
ADD COLUMN nome_fantasia TEXT;

-- Remover coluna status da tabela clientes
ALTER TABLE public.clientes 
DROP COLUMN status;