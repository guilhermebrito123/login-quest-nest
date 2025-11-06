-- Create storage bucket for OS attachments
INSERT INTO storage.buckets (id, name, public)
VALUES ('os-anexos', 'os-anexos', false);

-- Create RLS policies for OS attachments
CREATE POLICY "Usuarios autenticados podem visualizar anexos de OS"
ON storage.objects FOR SELECT
USING (bucket_id = 'os-anexos' AND auth.uid() IS NOT NULL);

CREATE POLICY "Usuarios autorizados podem fazer upload de anexos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'os-anexos' AND 
  (has_role(auth.uid(), 'admin'::app_role) OR 
   has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
   has_role(auth.uid(), 'supervisor'::app_role) OR
   has_role(auth.uid(), 'analista_centro_controle'::app_role))
);

CREATE POLICY "Usuarios autorizados podem deletar anexos"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'os-anexos' AND 
  (has_role(auth.uid(), 'admin'::app_role) OR 
   has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
   has_role(auth.uid(), 'supervisor'::app_role))
);

-- Create table for OS change history
CREATE TABLE public.os_historico (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  os_id UUID REFERENCES public.ordens_servico(id) ON DELETE CASCADE NOT NULL,
  usuario_id UUID REFERENCES auth.users(id) NOT NULL,
  acao TEXT NOT NULL,
  campo_alterado TEXT,
  valor_anterior TEXT,
  valor_novo TEXT,
  observacao TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Enable RLS on os_historico
ALTER TABLE public.os_historico ENABLE ROW LEVEL SECURITY;

-- RLS policies for os_historico
CREATE POLICY "Usuarios autenticados podem ler historico de OS"
ON public.os_historico FOR SELECT
USING (auth.uid() IS NOT NULL);

CREATE POLICY "Sistema pode inserir no historico"
ON public.os_historico FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

-- Create table for OS attachments metadata
CREATE TABLE public.os_anexos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  os_id UUID REFERENCES public.ordens_servico(id) ON DELETE CASCADE NOT NULL,
  nome_arquivo TEXT NOT NULL,
  caminho_storage TEXT NOT NULL,
  tamanho_bytes BIGINT,
  tipo_arquivo TEXT,
  uploaded_by UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Enable RLS on os_anexos
ALTER TABLE public.os_anexos ENABLE ROW LEVEL SECURITY;

-- RLS policies for os_anexos
CREATE POLICY "Usuarios autenticados podem ler anexos de OS"
ON public.os_anexos FOR SELECT
USING (auth.uid() IS NOT NULL);

CREATE POLICY "Usuarios autorizados podem criar anexos"
ON public.os_anexos FOR INSERT
WITH CHECK (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
  has_role(auth.uid(), 'supervisor'::app_role) OR
  has_role(auth.uid(), 'analista_centro_controle'::app_role)
);

CREATE POLICY "Usuarios autorizados podem deletar anexos"
ON public.os_anexos FOR DELETE
USING (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
  has_role(auth.uid(), 'supervisor'::app_role)
);

-- Create function to log OS changes
CREATE OR REPLACE FUNCTION public.log_os_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.os_historico (os_id, usuario_id, acao, observacao)
    VALUES (NEW.id, auth.uid(), 'criacao', 'OS criada');
  ELSIF TG_OP = 'UPDATE' THEN
    -- Log status changes
    IF OLD.status IS DISTINCT FROM NEW.status THEN
      INSERT INTO public.os_historico (os_id, usuario_id, acao, campo_alterado, valor_anterior, valor_novo)
      VALUES (NEW.id, auth.uid(), 'atualizacao', 'status', OLD.status, NEW.status);
    END IF;
    
    -- Log responsavel changes
    IF OLD.responsavel_id IS DISTINCT FROM NEW.responsavel_id THEN
      INSERT INTO public.os_historico (os_id, usuario_id, acao, campo_alterado, valor_anterior, valor_novo)
      VALUES (NEW.id, auth.uid(), 'atualizacao', 'responsavel_id', OLD.responsavel_id::TEXT, NEW.responsavel_id::TEXT);
    END IF;
    
    -- Log prioridade changes
    IF OLD.prioridade IS DISTINCT FROM NEW.prioridade THEN
      INSERT INTO public.os_historico (os_id, usuario_id, acao, campo_alterado, valor_anterior, valor_novo)
      VALUES (NEW.id, auth.uid(), 'atualizacao', 'prioridade', OLD.prioridade, NEW.prioridade);
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger for OS changes
CREATE TRIGGER os_change_log
AFTER INSERT OR UPDATE ON public.ordens_servico
FOR EACH ROW
EXECUTE FUNCTION public.log_os_change();

-- Add index for better performance
CREATE INDEX idx_os_historico_os_id ON public.os_historico(os_id);
CREATE INDEX idx_os_anexos_os_id ON public.os_anexos(os_id);