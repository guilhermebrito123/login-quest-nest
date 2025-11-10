-- Create inspecoes table
CREATE TABLE public.inspecoes (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  posto_servico_id UUID REFERENCES public.postos_servico(id) ON DELETE SET NULL,
  colaborador_id UUID REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  inspetor TEXT NOT NULL,
  data_hora TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  
  -- Checklist de Conformidade
  apresentacao_pessoal TEXT CHECK (apresentacao_pessoal IN ('conforme', 'nao_conforme')),
  uso_uniforme TEXT CHECK (uso_uniforme IN ('conforme', 'nao_conforme')),
  disponibilidade_recursos TEXT CHECK (disponibilidade_recursos IN ('conforme', 'nao_conforme')),
  disponibilidade_equipamentos TEXT CHECK (disponibilidade_equipamentos IN ('conforme', 'nao_conforme')),
  
  -- Campos de texto
  observacoes TEXT,
  acompanhamento_cliente TEXT,
  problemas_po TEXT,
  outras_observacoes TEXT,
  
  -- Status
  status_inspecao TEXT DEFAULT 'aprovado' CHECK (status_inspecao IN ('aprovado', 'reprovado', 'pendente')),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.inspecoes ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Usuarios autenticados podem ler inspecoes"
  ON public.inspecoes FOR SELECT
  USING (true);

CREATE POLICY "Usuarios autorizados podem criar inspecoes"
  ON public.inspecoes FOR INSERT
  WITH CHECK (
    has_role(auth.uid(), 'admin'::app_role) OR
    has_role(auth.uid(), 'gestor_operacoes'::app_role) OR
    has_role(auth.uid(), 'supervisor'::app_role)
  );

CREATE POLICY "Usuarios autorizados podem atualizar inspecoes"
  ON public.inspecoes FOR UPDATE
  USING (
    has_role(auth.uid(), 'admin'::app_role) OR
    has_role(auth.uid(), 'gestor_operacoes'::app_role) OR
    has_role(auth.uid(), 'supervisor'::app_role)
  );

CREATE POLICY "Usuarios autorizados podem deletar inspecoes"
  ON public.inspecoes FOR DELETE
  USING (
    has_role(auth.uid(), 'admin'::app_role) OR
    has_role(auth.uid(), 'gestor_operacoes'::app_role)
  );

-- Create trigger for updated_at
CREATE TRIGGER update_inspecoes_updated_at
  BEFORE UPDATE ON public.inspecoes
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();