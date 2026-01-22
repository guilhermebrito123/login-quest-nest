-- 1. Criar o bucket de atestados (privado para segurança)
INSERT INTO storage.buckets (id, name, public)
VALUES ('atestados', 'atestados', false);

-- 2. Política de INSERT: admin, gestor_operacoes e supervisor podem fazer upload
CREATE POLICY "Usuarios autorizados podem fazer upload de atestados"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'atestados'
  AND EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_roles.user_id = auth.uid()
    AND user_roles.role IN ('admin', 'gestor_operacoes', 'supervisor')
  )
);

-- 3. Política de SELECT: todos os usuários autenticados podem visualizar
CREATE POLICY "Usuarios autenticados podem visualizar atestados"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'atestados');

-- 4. Política de DELETE: apenas admin pode deletar documentos
CREATE POLICY "Apenas admin pode deletar atestados"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'atestados'
  AND EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_roles.user_id = auth.uid()
    AND user_roles.role = 'admin'
  )
);