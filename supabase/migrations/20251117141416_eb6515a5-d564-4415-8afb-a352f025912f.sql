-- Remove colunas ordem e ativo_id da tabela checklist_item
ALTER TABLE public.checklist_item 
  DROP COLUMN IF EXISTS ordem,
  DROP COLUMN IF EXISTS ativo_id;

-- Adiciona coluna item_id com referência a itens_estoque
ALTER TABLE public.checklist_item 
  ADD COLUMN item_id UUID REFERENCES public.itens_estoque(id) ON DELETE SET NULL;