-- Create table to store marked vacant days for service posts
CREATE TABLE IF NOT EXISTS public.posto_dias_vagos (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  posto_servico_id UUID NOT NULL REFERENCES public.postos_servico(id) ON DELETE CASCADE,
  colaborador_id UUID REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  data DATE NOT NULL,
  motivo TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_by UUID NOT NULL REFERENCES auth.users(id),
  UNIQUE(posto_servico_id, data)
);

-- Enable RLS
ALTER TABLE public.posto_dias_vagos ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Usuarios autenticados podem ler dias vagos"
  ON public.posto_dias_vagos
  FOR SELECT
  USING (true);

CREATE POLICY "Usuarios autorizados podem criar dias vagos"
  ON public.posto_dias_vagos
  FOR INSERT
  WITH CHECK (
    has_role(auth.uid(), 'admin'::app_role) OR 
    has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
    has_role(auth.uid(), 'supervisor'::app_role)
  );

CREATE POLICY "Usuarios autorizados podem atualizar dias vagos"
  ON public.posto_dias_vagos
  FOR UPDATE
  USING (
    has_role(auth.uid(), 'admin'::app_role) OR 
    has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
    has_role(auth.uid(), 'supervisor'::app_role)
  );

CREATE POLICY "Usuarios autorizados podem deletar dias vagos"
  ON public.posto_dias_vagos
  FOR DELETE
  USING (
    has_role(auth.uid(), 'admin'::app_role) OR 
    has_role(auth.uid(), 'gestor_operacoes'::app_role)
  );

-- Create index for performance
CREATE INDEX idx_posto_dias_vagos_posto ON public.posto_dias_vagos(posto_servico_id);
CREATE INDEX idx_posto_dias_vagos_data ON public.posto_dias_vagos(data);