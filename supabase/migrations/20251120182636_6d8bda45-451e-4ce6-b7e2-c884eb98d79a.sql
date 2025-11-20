-- Adicionar CHECK constraint para status de postos_servico aceitar apenas 'vago' ou 'ocupado'
ALTER TABLE public.postos_servico
DROP CONSTRAINT IF EXISTS postos_servico_status_check;

ALTER TABLE public.postos_servico
ADD CONSTRAINT postos_servico_status_check 
CHECK (status IN ('vago', 'ocupado'));