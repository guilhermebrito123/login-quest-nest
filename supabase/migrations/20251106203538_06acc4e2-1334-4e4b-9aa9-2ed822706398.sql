-- Adicionar coluna ativo_id na tabela ordens_servico
ALTER TABLE public.ordens_servico
ADD COLUMN ativo_id uuid REFERENCES public.ativos(id) ON DELETE SET NULL;