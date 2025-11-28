-- Remover foreign key constraint da tabela contratos
ALTER TABLE public.contratos
DROP CONSTRAINT IF EXISTS contratos_cliente_id_fkey;

-- Criar tabela temporária para backup dos dados
CREATE TEMP TABLE clientes_backup AS 
SELECT * FROM public.clientes;

-- Criar tabela temporária para backup dos contratos
CREATE TEMP TABLE contratos_backup AS
SELECT * FROM public.contratos;

-- Limpar as tabelas
TRUNCATE public.contratos CASCADE;
TRUNCATE public.clientes CASCADE;

-- Alterar o tipo da coluna id de clientes para TEXT e remover o default
ALTER TABLE public.clientes
ALTER COLUMN id TYPE TEXT,
ALTER COLUMN id DROP DEFAULT;

-- Restaurar dados de clientes usando CNPJ como id
INSERT INTO public.clientes (id, razao_social, cnpj, contato_nome, contato_email, contato_telefone, nome_fantasia, created_at, updated_at)
SELECT cnpj, razao_social, cnpj, contato_nome, contato_email, contato_telefone, nome_fantasia, created_at, updated_at
FROM clientes_backup;

-- Alterar o tipo da coluna cliente_id em contratos para TEXT
ALTER TABLE public.contratos
ALTER COLUMN cliente_id TYPE TEXT;

-- Restaurar dados de contratos com os novos ids (CNPJ)
INSERT INTO public.contratos (id, cliente_id, codigo, nome, data_inicio, data_fim, sla_alvo_pct, nps_meta, status, created_at, updated_at)
SELECT c.id, cb.cnpj, c.codigo, c.nome, c.data_inicio, c.data_fim, c.sla_alvo_pct, c.nps_meta, c.status, c.created_at, c.updated_at
FROM contratos_backup c
LEFT JOIN clientes_backup cb ON c.cliente_id = cb.id;

-- Recriar foreign key constraint
ALTER TABLE public.contratos
ADD CONSTRAINT contratos_cliente_id_fkey 
FOREIGN KEY (cliente_id) 
REFERENCES public.clientes(id) 
ON DELETE SET NULL;