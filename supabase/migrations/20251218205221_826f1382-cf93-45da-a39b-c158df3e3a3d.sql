-- Adicionar campo efetivo_planejado na tabela postos_servico
ALTER TABLE public.postos_servico
ADD COLUMN efetivo_planejado INTEGER DEFAULT 1;