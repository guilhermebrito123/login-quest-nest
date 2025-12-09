-- Alterar id da tabela clientes para SERIAL auto-increment

-- 1. Remover a foreign key de contratos que referencia clientes
ALTER TABLE public.contratos DROP CONSTRAINT IF EXISTS contratos_cliente_id_fkey;

-- 2. Adicionar nova coluna id numérica auto-increment
ALTER TABLE public.clientes ADD COLUMN new_id SERIAL;

-- 3. Atualizar contratos para usar o novo id numérico
UPDATE public.contratos c
SET cliente_id = cl.new_id::text
FROM public.clientes cl
WHERE c.cliente_id = cl.id;

-- 4. Remover a coluna id antiga e renomear a nova
ALTER TABLE public.clientes DROP CONSTRAINT clientes_pkey;
ALTER TABLE public.clientes DROP COLUMN id;
ALTER TABLE public.clientes RENAME COLUMN new_id TO id;
ALTER TABLE public.clientes ADD PRIMARY KEY (id);

-- 5. Alterar tipo da coluna cliente_id em contratos para integer
ALTER TABLE public.contratos ALTER COLUMN cliente_id TYPE integer USING cliente_id::integer;

-- 6. Recriar a foreign key
ALTER TABLE public.contratos 
ADD CONSTRAINT contratos_cliente_id_fkey 
FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON DELETE CASCADE;