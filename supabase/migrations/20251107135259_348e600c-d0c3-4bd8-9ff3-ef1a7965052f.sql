-- Criar tabela para armazenar as jornadas cadastradas dos postos
CREATE TABLE IF NOT EXISTS public.posto_jornadas (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  posto_servico_id UUID NOT NULL REFERENCES public.postos_servico(id) ON DELETE CASCADE,
  mes INTEGER NOT NULL,
  ano INTEGER NOT NULL,
  dias_trabalho DATE[] NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_by UUID NOT NULL REFERENCES auth.users(id),
  UNIQUE(posto_servico_id, mes, ano)
);

-- Enable RLS
ALTER TABLE public.posto_jornadas ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Usuarios autenticados podem ler jornadas"
ON public.posto_jornadas
FOR SELECT
USING (true);

CREATE POLICY "Usuarios autorizados podem criar jornadas"
ON public.posto_jornadas
FOR INSERT
WITH CHECK (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
  has_role(auth.uid(), 'supervisor'::app_role)
);

CREATE POLICY "Usuarios autorizados podem atualizar jornadas"
ON public.posto_jornadas
FOR UPDATE
USING (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
  has_role(auth.uid(), 'supervisor'::app_role)
);

CREATE POLICY "Usuarios autorizados podem deletar jornadas"
ON public.posto_jornadas
FOR DELETE
USING (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role)
);

-- Create index for better performance
CREATE INDEX idx_posto_jornadas_posto_mes_ano ON public.posto_jornadas(posto_servico_id, mes, ano);