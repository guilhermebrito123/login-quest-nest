-- Remover valor "Aprovada para pagamento" do enum status_diaria

-- Atualizar registros que possam estar usando esse valor
UPDATE public.diarias SET status = 'Aprovada' WHERE status = 'Aprovada para pagamento';
UPDATE public.diarias_temporarias SET status = 'Aprovada' WHERE status = 'Aprovada para pagamento';

-- Remover TODAS as políticas RLS das tabelas afetadas
DROP POLICY IF EXISTS "Usuarios autenticados podem ler diarias" ON public.diarias;
DROP POLICY IF EXISTS "Usuarios autorizados podem atualizar diarias" ON public.diarias;
DROP POLICY IF EXISTS "Usuarios autorizados podem deletar diarias" ON public.diarias;
DROP POLICY IF EXISTS "Usuarios autorizados podem inserir diarias" ON public.diarias;

DROP POLICY IF EXISTS "Admins podem ler todas diarias temporarias" ON public.diarias_temporarias;
DROP POLICY IF EXISTS "Deletar apenas diarias canceladas ou reprovadas" ON public.diarias_temporarias;
DROP POLICY IF EXISTS "Usuarios autenticados podem atualizar diarias temporarias" ON public.diarias_temporarias;
DROP POLICY IF EXISTS "Usuarios autenticados podem criar diarias temporarias" ON public.diarias_temporarias;
DROP POLICY IF EXISTS "diarias_temporarias_delete_policy" ON public.diarias_temporarias;
DROP POLICY IF EXISTS "diarias_temporarias_insert_policy" ON public.diarias_temporarias;
DROP POLICY IF EXISTS "diarias_temporarias_select_policy" ON public.diarias_temporarias;
DROP POLICY IF EXISTS "diarias_temporarias_update_policy" ON public.diarias_temporarias;

-- Remover defaults temporariamente
ALTER TABLE public.diarias ALTER COLUMN status DROP DEFAULT;
ALTER TABLE public.diarias_temporarias ALTER COLUMN status DROP DEFAULT;

-- Criar novo tipo enum sem o valor "Aprovada para pagamento"
CREATE TYPE status_diaria_new AS ENUM (
  'Aguardando confirmacao',
  'Confirmada',
  'Aprovada',
  'Lançada para pagamento',
  'Paga',
  'Cancelada',
  'Reprovada'
);

-- Alterar as colunas para usar o novo tipo
ALTER TABLE public.diarias 
  ALTER COLUMN status TYPE status_diaria_new 
  USING status::text::status_diaria_new;

ALTER TABLE public.diarias_temporarias 
  ALTER COLUMN status TYPE status_diaria_new 
  USING status::text::status_diaria_new;

-- Remover o tipo antigo
DROP TYPE status_diaria;

-- Renomear o novo tipo para o nome original
ALTER TYPE status_diaria_new RENAME TO status_diaria;

-- Restaurar os defaults
ALTER TABLE public.diarias ALTER COLUMN status SET DEFAULT 'Aguardando confirmacao'::status_diaria;
ALTER TABLE public.diarias_temporarias ALTER COLUMN status SET DEFAULT 'Aguardando confirmacao'::status_diaria;

-- Recriar políticas RLS para diarias
CREATE POLICY "Usuarios autenticados podem ler diarias"
ON public.diarias FOR SELECT TO authenticated USING (true);

CREATE POLICY "Usuarios autorizados podem atualizar diarias"
ON public.diarias FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Usuarios autorizados podem deletar diarias"
ON public.diarias FOR DELETE TO authenticated
USING (status IN ('Cancelada', 'Reprovada'));

CREATE POLICY "Usuarios autorizados podem inserir diarias"
ON public.diarias FOR INSERT TO authenticated WITH CHECK (true);

-- Recriar políticas RLS para diarias_temporarias
CREATE POLICY "Admins podem ler todas diarias temporarias"
ON public.diarias_temporarias FOR SELECT TO authenticated USING (true);

CREATE POLICY "Usuarios autenticados podem criar diarias temporarias"
ON public.diarias_temporarias FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Usuarios autenticados podem atualizar diarias temporarias"
ON public.diarias_temporarias FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Deletar apenas diarias canceladas ou reprovadas"
ON public.diarias_temporarias FOR DELETE TO authenticated
USING (status IN ('Cancelada', 'Reprovada'));