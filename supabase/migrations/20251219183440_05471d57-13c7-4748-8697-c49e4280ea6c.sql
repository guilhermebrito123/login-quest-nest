-- Create subitens table
CREATE TABLE public.subitens (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  nome TEXT NOT NULL,
  cliente_id INTEGER NOT NULL REFERENCES public.clientes(id) ON DELETE CASCADE,
  valor_unitario NUMERIC,
  observacao TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.subitens ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Usuarios autenticados podem ler subitens"
ON public.subitens
FOR SELECT
USING (true);

CREATE POLICY "Admins e gestores podem inserir subitens"
ON public.subitens
FOR INSERT
WITH CHECK (has_role(auth.uid(), 'admin'::internal_access_level) OR has_role(auth.uid(), 'gestor_operacoes'::internal_access_level));

CREATE POLICY "Admins e gestores podem atualizar subitens"
ON public.subitens
FOR UPDATE
USING (has_role(auth.uid(), 'admin'::internal_access_level) OR has_role(auth.uid(), 'gestor_operacoes'::internal_access_level));

CREATE POLICY "Apenas admins podem deletar subitens"
ON public.subitens
FOR DELETE
USING (has_role(auth.uid(), 'admin'::internal_access_level));

-- Create trigger for updated_at
CREATE TRIGGER update_subitens_updated_at
BEFORE UPDATE ON public.subitens
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();