-- Create candidatos table
CREATE TABLE public.candidatos (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  nome_completo TEXT NOT NULL,
  email TEXT NOT NULL,
  cidade TEXT NOT NULL,
  estado TEXT NOT NULL,
  telefone TEXT NOT NULL,
  celular TEXT NOT NULL,
  curriculo_path TEXT NOT NULL,
  experiencia_relevante TEXT[] NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo'),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo')
);

-- Create candidatos_anexos table for documentos_apoio (optional attachments)
CREATE TABLE public.candidatos_anexos (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  candidato_id UUID NOT NULL REFERENCES public.candidatos(id) ON DELETE CASCADE,
  nome_arquivo TEXT NOT NULL,
  caminho_storage TEXT NOT NULL,
  tipo_arquivo TEXT,
  tamanho_bytes BIGINT,
  uploaded_by UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS on candidatos
ALTER TABLE public.candidatos ENABLE ROW LEVEL SECURITY;

-- RLS policies for candidatos
CREATE POLICY "Usuarios autenticados podem ler candidatos"
ON public.candidatos FOR SELECT
USING (true);

CREATE POLICY "Usuarios autorizados podem inserir candidatos"
ON public.candidatos FOR INSERT
WITH CHECK (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'gestor_operacoes'::app_role));

CREATE POLICY "Usuarios autorizados podem atualizar candidatos"
ON public.candidatos FOR UPDATE
USING (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'gestor_operacoes'::app_role));

CREATE POLICY "Usuarios autorizados podem deletar candidatos"
ON public.candidatos FOR DELETE
USING (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'gestor_operacoes'::app_role));

-- Enable RLS on candidatos_anexos
ALTER TABLE public.candidatos_anexos ENABLE ROW LEVEL SECURITY;

-- RLS policies for candidatos_anexos
CREATE POLICY "Usuarios autenticados podem ler anexos de candidatos"
ON public.candidatos_anexos FOR SELECT
USING (auth.uid() IS NOT NULL);

CREATE POLICY "Usuarios autorizados podem criar anexos de candidatos"
ON public.candidatos_anexos FOR INSERT
WITH CHECK (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'gestor_operacoes'::app_role));

CREATE POLICY "Usuarios autorizados podem deletar anexos de candidatos"
ON public.candidatos_anexos FOR DELETE
USING (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'gestor_operacoes'::app_role));

-- Create storage bucket for candidatos files
INSERT INTO storage.buckets (id, name, public) VALUES ('candidatos-anexos', 'candidatos-anexos', false);

-- Storage policies
CREATE POLICY "Usuarios autenticados podem ver arquivos de candidatos"
ON storage.objects FOR SELECT
USING (bucket_id = 'candidatos-anexos' AND auth.uid() IS NOT NULL);

CREATE POLICY "Usuarios autorizados podem fazer upload de arquivos de candidatos"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'candidatos-anexos' AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'gestor_operacoes'::app_role)));

CREATE POLICY "Usuarios autorizados podem deletar arquivos de candidatos"
ON storage.objects FOR DELETE
USING (bucket_id = 'candidatos-anexos' AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'gestor_operacoes'::app_role)));