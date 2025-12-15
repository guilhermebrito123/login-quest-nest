-- Adicionar coluna superior como FK auto-referencial na tabela profiles
ALTER TABLE public.profiles
ADD COLUMN superior uuid REFERENCES public.profiles(id) ON DELETE SET NULL;