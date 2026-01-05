-- Adicionar coluna unidade à tabela diarias_temporarias
ALTER TABLE public.diarias_temporarias 
ADD COLUMN unidade text DEFAULT NULL;