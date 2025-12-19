-- Make cliente_id NOT NULL in postos_servico
ALTER TABLE public.postos_servico 
ALTER COLUMN cliente_id SET NOT NULL;