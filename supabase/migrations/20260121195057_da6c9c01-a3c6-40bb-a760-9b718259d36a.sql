-- Criar tabela cost_center conforme API Convenia
CREATE TABLE public.cost_center (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  convenia_id text NOT NULL UNIQUE,
  name text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE public.cost_center ENABLE ROW LEVEL SECURITY;

-- Políticas de acesso
CREATE POLICY "Usuarios autenticados podem ler cost_center" 
ON public.cost_center 
FOR SELECT 
USING (true);

CREATE POLICY "Usuarios autorizados podem gerenciar cost_center" 
ON public.cost_center 
FOR ALL 
USING (has_role(auth.uid(), 'admin'::internal_access_level) OR has_role(auth.uid(), 'gestor_operacoes'::internal_access_level));

-- Trigger para atualizar updated_at
CREATE TRIGGER update_cost_center_updated_at
BEFORE UPDATE ON public.cost_center
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();