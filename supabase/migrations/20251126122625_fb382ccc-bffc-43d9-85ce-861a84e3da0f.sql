-- Adicionar coluna CEP à tabela diaristas com valor padrão temporário
ALTER TABLE public.diaristas 
  ADD COLUMN cep text DEFAULT '' NOT NULL;

-- Remover default após criação (para não aplicar em novos inserts)
ALTER TABLE public.diaristas 
  ALTER COLUMN cep DROP DEFAULT;