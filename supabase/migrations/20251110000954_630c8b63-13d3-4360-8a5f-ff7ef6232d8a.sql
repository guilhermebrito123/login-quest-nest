-- Add nome column to itens_estoque table
ALTER TABLE public.itens_estoque 
ADD COLUMN nome text NOT NULL DEFAULT '';