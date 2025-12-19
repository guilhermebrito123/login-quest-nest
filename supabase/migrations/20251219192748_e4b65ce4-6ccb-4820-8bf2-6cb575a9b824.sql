-- Add cliente_id column to postos_servico
ALTER TABLE public.postos_servico 
ADD COLUMN cliente_id INTEGER REFERENCES public.clientes(id) ON DELETE SET NULL;