-- Create table for attendance control
CREATE TABLE public.presencas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  colaborador_id UUID REFERENCES public.colaboradores(id) ON DELETE CASCADE NOT NULL,
  data DATE NOT NULL,
  tipo TEXT NOT NULL CHECK (tipo IN ('presente', 'falta', 'falta_justificada', 'ferias', 'atestado', 'folga')),
  horario_entrada TIMESTAMPTZ,
  horario_saida TIMESTAMPTZ,
  observacao TEXT,
  registrado_por UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE(colaborador_id, data)
);

-- Enable RLS on presencas
ALTER TABLE public.presencas ENABLE ROW LEVEL SECURITY;

-- RLS policies for presencas
CREATE POLICY "Usuarios autenticados podem ler presencas"
ON public.presencas FOR SELECT
USING (auth.uid() IS NOT NULL);

CREATE POLICY "Usuarios autorizados podem registrar presencas"
ON public.presencas FOR INSERT
WITH CHECK (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
  has_role(auth.uid(), 'supervisor'::app_role)
);

CREATE POLICY "Usuarios autorizados podem atualizar presencas"
ON public.presencas FOR UPDATE
USING (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
  has_role(auth.uid(), 'supervisor'::app_role)
);

CREATE POLICY "Usuarios autorizados podem deletar presencas"
ON public.presencas FOR DELETE
USING (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role)
);

-- Create trigger for updated_at
CREATE TRIGGER update_presencas_updated_at
BEFORE UPDATE ON public.presencas
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX idx_presencas_colaborador_id ON public.presencas(colaborador_id);
CREATE INDEX idx_presencas_data ON public.presencas(data);
CREATE INDEX idx_presencas_tipo ON public.presencas(tipo);