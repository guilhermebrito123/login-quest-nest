-- Adicionar campo cliente_id opcional na tabela colaboradores
ALTER TABLE public.colaboradores 
ADD COLUMN cliente_id integer REFERENCES public.clientes(id) ON DELETE SET NULL;