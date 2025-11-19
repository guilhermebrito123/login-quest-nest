-- Atualizar status existentes para o novo formato
UPDATE public.postos_servico 
SET status = 'vago' 
WHERE status IS NULL OR status NOT IN ('vago', 'ocupado');

-- Adicionar constraint para permitir apenas 'vago' ou 'ocupado'
ALTER TABLE public.postos_servico 
DROP CONSTRAINT IF EXISTS postos_servico_status_check;

ALTER TABLE public.postos_servico 
ADD CONSTRAINT postos_servico_status_check 
CHECK (status IN ('vago', 'ocupado'));

-- Alterar default para 'vago'
ALTER TABLE public.postos_servico 
ALTER COLUMN status SET DEFAULT 'vago';