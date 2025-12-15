-- Adicionar coluna observacoes_especificas na tabela postos_servico
ALTER TABLE public.postos_servico
ADD COLUMN observacoes_especificas text;