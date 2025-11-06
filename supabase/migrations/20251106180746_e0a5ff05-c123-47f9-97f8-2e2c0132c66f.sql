-- Criar bucket para anexos de chamados se não existir
INSERT INTO storage.buckets (id, name, public)
VALUES ('chamados-anexos', 'chamados-anexos', false)
ON CONFLICT (id) DO NOTHING;

-- Políticas RLS para o bucket de anexos de chamados
CREATE POLICY "Usuarios autenticados podem visualizar anexos de chamados"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'chamados-anexos');

CREATE POLICY "Usuarios autenticados podem fazer upload de anexos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'chamados-anexos' AND
  (storage.foldername(name))[1] IS NOT NULL
);

CREATE POLICY "Usuarios podem deletar seus proprios anexos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'chamados-anexos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);