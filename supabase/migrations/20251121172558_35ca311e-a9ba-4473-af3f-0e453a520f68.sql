-- Criar bucket de storage para anexos de diaristas
INSERT INTO storage.buckets (id, name, public)
VALUES ('diaristas-anexos', 'diaristas-anexos', false)
ON CONFLICT (id) DO NOTHING;

-- Criar tabela de anexos de diaristas
CREATE TABLE IF NOT EXISTS public.diaristas_anexos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  diarista_id UUID NOT NULL REFERENCES public.diaristas(id) ON DELETE CASCADE,
  nome_arquivo TEXT NOT NULL,
  caminho_storage TEXT NOT NULL,
  tipo_arquivo TEXT,
  tamanho_bytes BIGINT,
  uploaded_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Habilitar RLS
ALTER TABLE public.diaristas_anexos ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para diaristas_anexos
CREATE POLICY "Usuarios autenticados podem ler anexos de diaristas"
  ON public.diaristas_anexos
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Usuarios autorizados podem criar anexos de diaristas"
  ON public.diaristas_anexos
  FOR INSERT
  WITH CHECK (
    has_role(auth.uid(), 'admin'::app_role) OR 
    has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
    has_role(auth.uid(), 'supervisor'::app_role)
  );

CREATE POLICY "Usuarios autorizados podem deletar anexos de diaristas"
  ON public.diaristas_anexos
  FOR DELETE
  USING (
    has_role(auth.uid(), 'admin'::app_role) OR 
    has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
    has_role(auth.uid(), 'supervisor'::app_role)
  );

-- Políticas de storage para o bucket diaristas-anexos
CREATE POLICY "Usuarios autenticados podem visualizar anexos de diaristas"
  ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'diaristas-anexos' AND
    auth.uid() IS NOT NULL
  );

CREATE POLICY "Usuarios autorizados podem fazer upload de anexos de diaristas"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'diaristas-anexos' AND
    (
      has_role(auth.uid(), 'admin'::app_role) OR 
      has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
      has_role(auth.uid(), 'supervisor'::app_role)
    )
  );

CREATE POLICY "Usuarios autorizados podem deletar anexos de diaristas"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'diaristas-anexos' AND
    (
      has_role(auth.uid(), 'admin'::app_role) OR 
      has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
      has_role(auth.uid(), 'supervisor'::app_role)
    )
  );