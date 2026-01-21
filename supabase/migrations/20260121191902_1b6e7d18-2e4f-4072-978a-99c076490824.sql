-- Adicionar coluna para vincular clientes ao cost_center do Convenia
ALTER TABLE public.clientes 
ADD COLUMN IF NOT EXISTS convenia_cost_center_id TEXT UNIQUE;

-- Criar índice para buscas rápidas
CREATE INDEX IF NOT EXISTS idx_clientes_convenia_cost_center_id 
ON public.clientes(convenia_cost_center_id);

-- Comentário para documentação
COMMENT ON COLUMN public.clientes.convenia_cost_center_id IS 'ID do cost_center no Convenia para sincronização automática';