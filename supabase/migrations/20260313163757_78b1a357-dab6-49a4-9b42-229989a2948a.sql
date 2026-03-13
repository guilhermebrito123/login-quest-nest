-- Atualizar política de INSERT na tabela diaristas para permitir todos os usuários internos
DROP POLICY IF EXISTS "Usuarios autorizados podem inserir diaristas" ON public.diaristas;

CREATE POLICY "Usuarios autorizados podem inserir diaristas"
ON public.diaristas
FOR INSERT
TO public
WITH CHECK (
  is_internal_user() AND (possui_antecedente = false)
);