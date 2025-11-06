-- Criar tabela de ativos
CREATE TABLE public.ativos (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  unidade_id UUID REFERENCES public.unidades(id),
  categoria TEXT,
  tag_patrimonio TEXT NOT NULL UNIQUE,
  fabricante TEXT,
  modelo TEXT,
  numero_serie TEXT,
  status TEXT DEFAULT 'operacional',
  critico BOOLEAN DEFAULT false,
  data_instalacao DATE,
  frequencia_preventiva_dias INTEGER DEFAULT 90,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Criar tabela de itens de estoque
CREATE TABLE public.itens_estoque (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  unidade_id UUID REFERENCES public.unidades(id),
  sku TEXT NOT NULL UNIQUE,
  descricao TEXT NOT NULL,
  unidade_medida TEXT NOT NULL,
  quantidade_minima INTEGER NOT NULL,
  quantidade_atual INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Habilitar RLS nas tabelas
ALTER TABLE public.ativos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itens_estoque ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para ativos
CREATE POLICY "Usuarios autenticados podem ler ativos"
  ON public.ativos FOR SELECT
  USING (true);

CREATE POLICY "Usuarios autorizados podem inserir ativos"
  ON public.ativos FOR INSERT
  WITH CHECK (
    has_role(auth.uid(), 'admin'::app_role) OR 
    has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
    has_role(auth.uid(), 'supervisor'::app_role)
  );

CREATE POLICY "Usuarios autorizados podem atualizar ativos"
  ON public.ativos FOR UPDATE
  USING (
    has_role(auth.uid(), 'admin'::app_role) OR 
    has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
    has_role(auth.uid(), 'supervisor'::app_role)
  );

CREATE POLICY "Usuarios autorizados podem deletar ativos"
  ON public.ativos FOR DELETE
  USING (
    has_role(auth.uid(), 'admin'::app_role) OR 
    has_role(auth.uid(), 'gestor_operacoes'::app_role)
  );

-- Políticas RLS para itens de estoque
CREATE POLICY "Usuarios autenticados podem ler itens estoque"
  ON public.itens_estoque FOR SELECT
  USING (true);

CREATE POLICY "Usuarios autorizados podem inserir itens estoque"
  ON public.itens_estoque FOR INSERT
  WITH CHECK (
    has_role(auth.uid(), 'admin'::app_role) OR 
    has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
    has_role(auth.uid(), 'supervisor'::app_role)
  );

CREATE POLICY "Usuarios autorizados podem atualizar itens estoque"
  ON public.itens_estoque FOR UPDATE
  USING (
    has_role(auth.uid(), 'admin'::app_role) OR 
    has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
    has_role(auth.uid(), 'supervisor'::app_role)
  );

CREATE POLICY "Usuarios autorizados podem deletar itens estoque"
  ON public.itens_estoque FOR DELETE
  USING (
    has_role(auth.uid(), 'admin'::app_role) OR 
    has_role(auth.uid(), 'gestor_operacoes'::app_role)
  );

-- Triggers para atualizar updated_at
CREATE TRIGGER update_ativos_updated_at
  BEFORE UPDATE ON public.ativos
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_itens_estoque_updated_at
  BEFORE UPDATE ON public.itens_estoque
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();