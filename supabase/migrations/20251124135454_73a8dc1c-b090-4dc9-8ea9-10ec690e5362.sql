-- Criar índice único parcial para garantir apenas um colaborador ativo por posto
-- O índice só se aplica a colaboradores ativos e que têm posto_servico_id definido
CREATE UNIQUE INDEX colaboradores_unique_posto_ativo_idx
ON public.colaboradores (posto_servico_id)
WHERE status = 'ativo' AND posto_servico_id IS NOT NULL;