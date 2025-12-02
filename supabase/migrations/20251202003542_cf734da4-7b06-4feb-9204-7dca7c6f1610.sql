-- Adicionar coluna motivo_vago à tabela diarias_temporarias
ALTER TABLE public.diarias_temporarias
ADD COLUMN motivo_vago motivo_vago_type;