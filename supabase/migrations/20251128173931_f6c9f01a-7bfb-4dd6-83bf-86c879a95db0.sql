-- Atualizar valores NULL antes de adicionar constraints
UPDATE public.clientes
SET nome_fantasia = razao_social
WHERE nome_fantasia IS NULL;

UPDATE public.clientes
SET created_at = now()
WHERE created_at IS NULL;

UPDATE public.clientes
SET updated_at = now()
WHERE updated_at IS NULL;

-- Adicionar NOT NULL constraints à tabela clientes
ALTER TABLE public.clientes
ALTER COLUMN created_at SET NOT NULL,
ALTER COLUMN updated_at SET NOT NULL,
ALTER COLUMN nome_fantasia SET NOT NULL;

-- Adicionar valores padrão para os campos que agora são NOT NULL
ALTER TABLE public.clientes
ALTER COLUMN created_at SET DEFAULT now(),
ALTER COLUMN updated_at SET DEFAULT now(),
ALTER COLUMN nome_fantasia SET DEFAULT '';