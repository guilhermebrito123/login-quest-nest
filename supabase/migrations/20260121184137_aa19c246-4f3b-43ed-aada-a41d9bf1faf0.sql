-- Tabela de mapeamento de cost centers do Convenia para clientes
CREATE TABLE public.cost_centers_convenia (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  convenia_cost_center_id text UNIQUE NOT NULL,
  convenia_cost_center_name text NOT NULL,
  cliente_id integer REFERENCES public.clientes(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.cost_centers_convenia ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Usuarios autenticados podem ler cost_centers_convenia"
ON public.cost_centers_convenia
FOR SELECT
USING (true);

CREATE POLICY "Usuarios autorizados podem gerenciar cost_centers_convenia"
ON public.cost_centers_convenia
FOR ALL
USING (
  has_role(auth.uid(), 'admin'::internal_access_level) OR 
  has_role(auth.uid(), 'gestor_operacoes'::internal_access_level)
);

-- Trigger para updated_at
CREATE TRIGGER update_cost_centers_convenia_updated_at
BEFORE UPDATE ON public.cost_centers_convenia
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();