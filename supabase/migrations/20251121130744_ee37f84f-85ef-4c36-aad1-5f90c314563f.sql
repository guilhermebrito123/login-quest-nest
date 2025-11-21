-- Criar ENUM para status de diárias
CREATE TYPE public.status_diaria AS ENUM (
  'Aguardando confirmacao',
  'Confirmada',
  'Aprovada',
  'Lançada para pagamento',
  'Aprovada para pagamento',
  'Cancelada'
);

-- Criar tabela diarias
CREATE TABLE public.diarias (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  posto_dia_vago_id UUID NOT NULL REFERENCES public.posto_dias_vagos(id) ON DELETE CASCADE,
  diarista_id UUID NOT NULL REFERENCES public.diaristas(id) ON DELETE CASCADE,
  valor NUMERIC(10, 2) NOT NULL,
  status status_diaria NOT NULL DEFAULT 'Aguardando confirmacao',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE public.diarias ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Usuarios autenticados podem ler diarias"
ON public.diarias
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Usuarios autorizados podem inserir diarias"
ON public.diarias
FOR INSERT
TO authenticated
WITH CHECK (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
  has_role(auth.uid(), 'supervisor'::app_role)
);

CREATE POLICY "Usuarios autorizados podem atualizar diarias"
ON public.diarias
FOR UPDATE
TO authenticated
USING (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
  has_role(auth.uid(), 'supervisor'::app_role)
);

CREATE POLICY "Usuarios autorizados podem deletar diarias"
ON public.diarias
FOR DELETE
TO authenticated
USING (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role)
);

-- Trigger para atualizar updated_at
CREATE TRIGGER update_diarias_updated_at
  BEFORE UPDATE ON public.diarias
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();