-- Permitir que perfis internos operacionais (não cliente_view) leiam dados básicos
-- de outros usuários, necessário para resolver embeds de FKs como solicitante,
-- responsável, resolvido_por em chamados (e telas semelhantes).

CREATE POLICY "Internos operacionais podem ler usuarios"
ON public.usuarios
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.usuarios u
    JOIN public.internal_profiles ip ON ip.user_id = u.id
    WHERE u.id = auth.uid()
      AND u.role = 'perfil_interno'
      AND ip.nivel_acesso <> 'cliente_view'
  )
);