-- Primeiro, adicionar a coluna cliente_id (nullable temporariamente para permitir a migração)
ALTER TABLE public.diarias_temporarias
ADD COLUMN cliente_id integer;

-- Atualizar registros existentes com um cliente_id padrão (primeiro cliente)
UPDATE public.diarias_temporarias
SET cliente_id = (SELECT id FROM public.clientes LIMIT 1)
WHERE cliente_id IS NULL;

-- Agora tornar NOT NULL
ALTER TABLE public.diarias_temporarias
ALTER COLUMN cliente_id SET NOT NULL;

-- Adicionar a foreign key constraint
ALTER TABLE public.diarias_temporarias
ADD CONSTRAINT diarias_temporarias_cliente_id_fkey
FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON DELETE CASCADE;

-- Remover a coluna cliente_nome
ALTER TABLE public.diarias_temporarias
DROP COLUMN IF EXISTS cliente_nome;