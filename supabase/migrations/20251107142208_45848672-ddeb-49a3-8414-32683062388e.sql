-- Create diaristas table
CREATE TABLE public.diaristas (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  nome_completo TEXT NOT NULL,
  rg TEXT NOT NULL,
  cnh TEXT NOT NULL,
  endereco TEXT NOT NULL,
  telefone TEXT NOT NULL,
  email TEXT NOT NULL,
  possui_antecedente BOOLEAN NOT NULL DEFAULT false,
  status TEXT DEFAULT 'ativo',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.diaristas ENABLE ROW LEVEL SECURITY;

-- Create policies for diaristas
CREATE POLICY "Usuarios autenticados podem ler diaristas" 
ON public.diaristas 
FOR SELECT 
USING (true);

CREATE POLICY "Usuarios autorizados podem inserir diaristas" 
ON public.diaristas 
FOR INSERT 
WITH CHECK (
  (has_role(auth.uid(), 'admin'::app_role) OR 
   has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
   has_role(auth.uid(), 'supervisor'::app_role))
  AND possui_antecedente = false
);

CREATE POLICY "Usuarios autorizados podem atualizar diaristas" 
ON public.diaristas 
FOR UPDATE 
USING (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
  has_role(auth.uid(), 'supervisor'::app_role)
);

CREATE POLICY "Usuarios autorizados podem deletar diaristas" 
ON public.diaristas 
FOR DELETE 
USING (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role)
);

-- Create trigger for automatic timestamp updates
CREATE TRIGGER update_diaristas_updated_at
BEFORE UPDATE ON public.diaristas
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();