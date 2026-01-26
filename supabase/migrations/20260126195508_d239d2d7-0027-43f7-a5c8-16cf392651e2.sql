-- Adicionar coluna cost_center_id na tabela postos_servico
ALTER TABLE public.postos_servico 
ADD COLUMN IF NOT EXISTS cost_center_id UUID REFERENCES public.cost_center(id) ON DELETE SET NULL;

-- Popular cost_center_id baseado no match entre cliente.nome_fantasia e cost_center.name
UPDATE public.postos_servico ps
SET cost_center_id = cc.id
FROM public.clientes c
JOIN public.cost_center cc ON UPPER(TRIM(c.nome_fantasia)) = UPPER(TRIM(cc.name))
WHERE ps.cliente_id = c.id
  AND ps.cost_center_id IS NULL;

-- Criar índice para melhorar performance de queries
CREATE INDEX IF NOT EXISTS idx_postos_servico_cost_center_id ON public.postos_servico(cost_center_id);