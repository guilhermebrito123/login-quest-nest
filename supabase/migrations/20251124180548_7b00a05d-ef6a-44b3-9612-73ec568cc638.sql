-- Adicionar foreign keys com CASCADE DELETE para colaborador_movimentacoes_posto
-- Isso permite deletar postos_servico que têm movimentações relacionadas

-- Foreign key para posto_servico_id_origem
ALTER TABLE public.colaborador_movimentacoes_posto
ADD CONSTRAINT fk_movimentacoes_posto_origem
FOREIGN KEY (posto_servico_id_origem)
REFERENCES public.postos_servico(id)
ON DELETE CASCADE;

-- Foreign key para posto_servico_id_destino
ALTER TABLE public.colaborador_movimentacoes_posto
ADD CONSTRAINT fk_movimentacoes_posto_destino
FOREIGN KEY (posto_servico_id_destino)
REFERENCES public.postos_servico(id)
ON DELETE CASCADE;

-- Foreign key para colaborador_id
ALTER TABLE public.colaborador_movimentacoes_posto
ADD CONSTRAINT fk_movimentacoes_colaborador
FOREIGN KEY (colaborador_id)
REFERENCES public.colaboradores(id)
ON DELETE CASCADE;

-- Foreign key para created_by
ALTER TABLE public.colaborador_movimentacoes_posto
ADD CONSTRAINT fk_movimentacoes_created_by
FOREIGN KEY (created_by)
REFERENCES auth.users(id)
ON DELETE CASCADE;