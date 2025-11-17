-- Remover TODOS os triggers relacionados às tabelas de execução
DROP TRIGGER IF EXISTS trigger_generate_execucao_checklist_id ON public.execucao_checklist;
DROP TRIGGER IF EXISTS trigger_generate_execucao_checklist_item_id ON public.execucao_checklist_item;
DROP TRIGGER IF EXISTS finalizar_execucao_checklist_trigger ON public.resposta_execucao_checklist;
DROP TRIGGER IF EXISTS finalizar_execucao_checklist_item_trigger ON public.resposta_execucao_checklist_item;

-- Remover funções de geração de ID (se existirem)
DROP FUNCTION IF EXISTS public.generate_execucao_checklist_id();
DROP FUNCTION IF EXISTS public.generate_execucao_checklist_item_id();

-- Remover constraints de foreign keys
ALTER TABLE public.execucao_checklist_item 
  DROP CONSTRAINT IF EXISTS execucao_checklist_item_execucao_checklist_id_fkey;

ALTER TABLE public.resposta_execucao_checklist 
  DROP CONSTRAINT IF EXISTS resposta_execucao_checklist_execucao_checklist_id_fkey;

ALTER TABLE public.resposta_execucao_checklist_item 
  DROP CONSTRAINT IF EXISTS resposta_execucao_checklist_ite_execucao_checklist_item_id_fkey;

-- Alterar tipo da coluna id de execucao_checklist para TEXT
ALTER TABLE public.execucao_checklist 
  ALTER COLUMN id DROP DEFAULT,
  ALTER COLUMN id TYPE TEXT USING id::TEXT;

-- Alterar colunas que referenciam execucao_checklist.id
ALTER TABLE public.execucao_checklist_item 
  ALTER COLUMN execucao_checklist_id TYPE TEXT USING execucao_checklist_id::TEXT;

ALTER TABLE public.resposta_execucao_checklist 
  ALTER COLUMN execucao_checklist_id TYPE TEXT USING execucao_checklist_id::TEXT;

-- Alterar tipo da coluna id de execucao_checklist_item para TEXT
ALTER TABLE public.execucao_checklist_item 
  ALTER COLUMN id DROP DEFAULT,
  ALTER COLUMN id TYPE TEXT USING id::TEXT;

-- Alterar colunas que referenciam execucao_checklist_item.id
ALTER TABLE public.resposta_execucao_checklist_item 
  ALTER COLUMN execucao_checklist_item_id TYPE TEXT USING execucao_checklist_item_id::TEXT;

-- Recriar constraints de foreign keys
ALTER TABLE public.execucao_checklist_item 
  ADD CONSTRAINT execucao_checklist_item_execucao_checklist_id_fkey 
  FOREIGN KEY (execucao_checklist_id) REFERENCES public.execucao_checklist(id) ON DELETE CASCADE;

ALTER TABLE public.resposta_execucao_checklist 
  ADD CONSTRAINT resposta_execucao_checklist_execucao_checklist_id_fkey 
  FOREIGN KEY (execucao_checklist_id) REFERENCES public.execucao_checklist(id) ON DELETE CASCADE;

ALTER TABLE public.resposta_execucao_checklist_item 
  ADD CONSTRAINT resposta_execucao_checklist_ite_execucao_checklist_item_id_fkey 
  FOREIGN KEY (execucao_checklist_item_id) REFERENCES public.execucao_checklist_item(id) ON DELETE CASCADE;

-- Função para gerar ID customizado da execução de checklist
-- Formato: [iniciais_checklist]-[id_supervisor]-[numero_execucoes]
CREATE OR REPLACE FUNCTION public.generate_execucao_checklist_id()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  checklist_iniciais TEXT;
  contador INTEGER;
BEGIN
  -- Pegar iniciais do nome do checklist
  SELECT STRING_AGG(SUBSTRING(word, 1, 1), '')
  INTO checklist_iniciais
  FROM regexp_split_to_table(
    (SELECT nome FROM public.checklist WHERE id = NEW.checklist_id), 
    '\s+'
  ) AS word;
  
  -- Contar execuções existentes do supervisor
  SELECT COUNT(*) + 1
  INTO contador
  FROM public.execucao_checklist
  WHERE supervisor_id = NEW.supervisor_id;
  
  -- Gerar ID customizado
  NEW.id := UPPER(COALESCE(checklist_iniciais, 'CL')) || '-' || 
            SUBSTRING(COALESCE(NEW.supervisor_id::TEXT, 'SEM-SUP'), 1, 8) || '-' || 
            LPAD(contador::TEXT, 3, '0');
  
  RETURN NEW;
END;
$$;

-- Função para gerar ID customizado da execução de item de checklist
-- Formato: [nome_item]-[id_supervisor]-[numero_execucoes]
CREATE OR REPLACE FUNCTION public.generate_execucao_checklist_item_id()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  item_nome TEXT;
  contador INTEGER;
BEGIN
  -- Pegar nome do item (via checklist_item e itens_estoque)
  SELECT COALESCE(ie.nome, ci.descricao)
  INTO item_nome
  FROM public.checklist_item ci
  LEFT JOIN public.itens_estoque ie ON ci.item_id = ie.id
  WHERE ci.id = NEW.checklist_item_id;
  
  -- Limpar nome do item (remover espaços e caracteres especiais)
  item_nome := REGEXP_REPLACE(UPPER(COALESCE(item_nome, 'ITEM')), '[^A-Z0-9]', '', 'g');
  
  -- Contar execuções existentes do supervisor
  SELECT COUNT(*) + 1
  INTO contador
  FROM public.execucao_checklist_item
  WHERE supervisor_id = NEW.supervisor_id;
  
  -- Gerar ID customizado (limitar tamanho do nome para evitar IDs muito longos)
  NEW.id := SUBSTRING(item_nome, 1, 20) || '-' || 
            SUBSTRING(COALESCE(NEW.supervisor_id::TEXT, 'SEM-SUP'), 1, 8) || '-' || 
            LPAD(contador::TEXT, 3, '0');
  
  RETURN NEW;
END;
$$;

-- Criar triggers para gerar IDs automaticamente
CREATE TRIGGER trigger_generate_execucao_checklist_id
  BEFORE INSERT ON public.execucao_checklist
  FOR EACH ROW
  WHEN (NEW.id IS NULL OR NEW.id = '')
  EXECUTE FUNCTION public.generate_execucao_checklist_id();

CREATE TRIGGER trigger_generate_execucao_checklist_item_id
  BEFORE INSERT ON public.execucao_checklist_item
  FOR EACH ROW
  WHEN (NEW.id IS NULL OR NEW.id = '')
  EXECUTE FUNCTION public.generate_execucao_checklist_item_id();

-- Recriar triggers para finalização automática
CREATE TRIGGER finalizar_execucao_checklist_trigger
  AFTER INSERT ON public.resposta_execucao_checklist
  FOR EACH ROW
  EXECUTE FUNCTION public.finalizar_execucao_checklist();

CREATE TRIGGER finalizar_execucao_checklist_item_trigger
  AFTER INSERT ON public.resposta_execucao_checklist_item
  FOR EACH ROW
  EXECUTE FUNCTION public.finalizar_execucao_checklist_item();