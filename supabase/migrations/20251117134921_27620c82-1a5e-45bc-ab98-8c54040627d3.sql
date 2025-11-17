-- Criar enum para status de execução
CREATE TYPE public.status_execucao AS ENUM ('ativo', 'concluido', 'atrasado', 'cancelado');

-- Criar enum para periodicidade
CREATE TYPE public.periodicidade_type AS ENUM ('diaria', 'semanal', 'quinzenal', 'mensal', 'trimestral', 'semestral', 'anual');

-- Excluir tabelas antigas
DROP TABLE IF EXISTS public.checklist_respostas CASCADE;
DROP TABLE IF EXISTS public.checklist_execucoes CASCADE;
DROP TABLE IF EXISTS public.checklist_itens CASCADE;
DROP TABLE IF EXISTS public.checklists CASCADE;

-- Criar tabela checklist
CREATE TABLE public.checklist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contrato_id UUID REFERENCES public.contratos(id) ON DELETE CASCADE,
  unidade_id UUID REFERENCES public.unidades(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  periodicidade periodicidade_type NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Criar tabela checklist_item
CREATE TABLE public.checklist_item (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_id UUID REFERENCES public.checklist(id) ON DELETE CASCADE NOT NULL,
  ativo_id UUID REFERENCES public.ativos(id) ON DELETE CASCADE,
  descricao TEXT NOT NULL,
  periodicidade periodicidade_type NOT NULL,
  ordem INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Criar tabela execucao_checklist
CREATE TABLE public.execucao_checklist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_id UUID REFERENCES public.checklist(id) ON DELETE CASCADE NOT NULL,
  supervisor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  data_prevista DATE NOT NULL,
  finalizado_em TIMESTAMPTZ,
  status status_execucao NOT NULL DEFAULT 'ativo',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Criar tabela execucao_checklist_item
CREATE TABLE public.execucao_checklist_item (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  execucao_checklist_id UUID REFERENCES public.execucao_checklist(id) ON DELETE CASCADE NOT NULL,
  checklist_item_id UUID REFERENCES public.checklist_item(id) ON DELETE CASCADE NOT NULL,
  resposta TEXT,
  foto TEXT,
  supervisor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  data_prevista DATE NOT NULL,
  finalizado_em TIMESTAMPTZ,
  status status_execucao NOT NULL DEFAULT 'ativo',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Criar tabela resposta_execucao_checklist
CREATE TABLE public.resposta_execucao_checklist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  execucao_checklist_id UUID REFERENCES public.execucao_checklist(id) ON DELETE CASCADE NOT NULL,
  resposta TEXT NOT NULL,
  foto TEXT,
  conforme BOOLEAN NOT NULL,
  observacoes TEXT,
  registrado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Criar tabela resposta_execucao_checklist_item
CREATE TABLE public.resposta_execucao_checklist_item (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  execucao_checklist_item_id UUID REFERENCES public.execucao_checklist_item(id) ON DELETE CASCADE NOT NULL,
  resposta TEXT NOT NULL,
  foto TEXT,
  conforme BOOLEAN NOT NULL,
  observacoes TEXT,
  registrado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Criar índices
CREATE INDEX idx_checklist_contrato ON public.checklist(contrato_id);
CREATE INDEX idx_checklist_unidade ON public.checklist(unidade_id);
CREATE INDEX idx_checklist_item_checklist ON public.checklist_item(checklist_id);
CREATE INDEX idx_checklist_item_ativo ON public.checklist_item(ativo_id);
CREATE INDEX idx_execucao_checklist_checklist ON public.execucao_checklist(checklist_id);
CREATE INDEX idx_execucao_checklist_supervisor ON public.execucao_checklist(supervisor_id);
CREATE INDEX idx_execucao_checklist_status ON public.execucao_checklist(status);
CREATE INDEX idx_execucao_checklist_item_execucao ON public.execucao_checklist_item(execucao_checklist_id);
CREATE INDEX idx_execucao_checklist_item_status ON public.execucao_checklist_item(status);

-- Trigger para atualizar updated_at em checklist
CREATE TRIGGER update_checklist_updated_at
  BEFORE UPDATE ON public.checklist
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger para atualizar updated_at em execucao_checklist
CREATE TRIGGER update_execucao_checklist_updated_at
  BEFORE UPDATE ON public.execucao_checklist
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger para atualizar updated_at em execucao_checklist_item
CREATE TRIGGER update_execucao_checklist_item_updated_at
  BEFORE UPDATE ON public.execucao_checklist_item
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Função para marcar execução checklist como concluída quando resposta é criada
CREATE OR REPLACE FUNCTION public.finalizar_execucao_checklist()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.execucao_checklist
  SET status = 'concluido',
      finalizado_em = NEW.registrado_em
  WHERE id = NEW.execucao_checklist_id;
  
  RETURN NEW;
END;
$$;

-- Trigger para finalizar execucao_checklist quando resposta é criada
CREATE TRIGGER trigger_finalizar_execucao_checklist
  AFTER INSERT ON public.resposta_execucao_checklist
  FOR EACH ROW
  EXECUTE FUNCTION public.finalizar_execucao_checklist();

-- Função para marcar execução checklist item como concluída quando resposta é criada
CREATE OR REPLACE FUNCTION public.finalizar_execucao_checklist_item()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.execucao_checklist_item
  SET status = 'concluido',
      finalizado_em = NEW.registrado_em
  WHERE id = NEW.execucao_checklist_item_id;
  
  RETURN NEW;
END;
$$;

-- Trigger para finalizar execucao_checklist_item quando resposta é criada
CREATE TRIGGER trigger_finalizar_execucao_checklist_item
  AFTER INSERT ON public.resposta_execucao_checklist_item
  FOR EACH ROW
  EXECUTE FUNCTION public.finalizar_execucao_checklist_item();

-- Função para cancelar execução de checklist
CREATE OR REPLACE FUNCTION public.cancelar_execucao_checklist(execucao_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.execucao_checklist
  SET status = 'cancelado',
      updated_at = now()
  WHERE id = execucao_id;
END;
$$;

-- Função para cancelar execução de checklist item
CREATE OR REPLACE FUNCTION public.cancelar_execucao_checklist_item(execucao_item_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.execucao_checklist_item
  SET status = 'cancelado',
      updated_at = now()
  WHERE id = execucao_item_id;
END;
$$;

-- Habilitar RLS em todas as tabelas
ALTER TABLE public.checklist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_item ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.execucao_checklist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.execucao_checklist_item ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resposta_execucao_checklist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resposta_execucao_checklist_item ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para checklist
CREATE POLICY "Usuarios autenticados podem ler checklists"
  ON public.checklist FOR SELECT
  USING (true);

CREATE POLICY "Usuarios autorizados podem gerenciar checklists"
  ON public.checklist FOR ALL
  USING (
    has_role(auth.uid(), 'admin'::app_role) OR 
    has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
    has_role(auth.uid(), 'supervisor'::app_role)
  );

-- Políticas RLS para checklist_item
CREATE POLICY "Usuarios autenticados podem ler itens checklist"
  ON public.checklist_item FOR SELECT
  USING (true);

CREATE POLICY "Usuarios autorizados podem gerenciar itens checklist"
  ON public.checklist_item FOR ALL
  USING (
    has_role(auth.uid(), 'admin'::app_role) OR 
    has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
    has_role(auth.uid(), 'supervisor'::app_role)
  );

-- Políticas RLS para execucao_checklist
CREATE POLICY "Usuarios autenticados podem ler execucoes"
  ON public.execucao_checklist FOR SELECT
  USING (true);

CREATE POLICY "Usuarios podem criar execucoes"
  ON public.execucao_checklist FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Usuarios podem atualizar execucoes"
  ON public.execucao_checklist FOR UPDATE
  USING (true);

-- Políticas RLS para execucao_checklist_item
CREATE POLICY "Usuarios autenticados podem ler execucoes item"
  ON public.execucao_checklist_item FOR SELECT
  USING (true);

CREATE POLICY "Usuarios podem criar execucoes item"
  ON public.execucao_checklist_item FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Usuarios podem atualizar execucoes item"
  ON public.execucao_checklist_item FOR UPDATE
  USING (true);

-- Políticas RLS para resposta_execucao_checklist
CREATE POLICY "Usuarios autenticados podem ler respostas"
  ON public.resposta_execucao_checklist FOR SELECT
  USING (true);

CREATE POLICY "Usuarios podem criar respostas"
  ON public.resposta_execucao_checklist FOR INSERT
  WITH CHECK (true);

-- Políticas RLS para resposta_execucao_checklist_item
CREATE POLICY "Usuarios autenticados podem ler respostas item"
  ON public.resposta_execucao_checklist_item FOR SELECT
  USING (true);

CREATE POLICY "Usuarios podem criar respostas item"
  ON public.resposta_execucao_checklist_item FOR INSERT
  WITH CHECK (true);