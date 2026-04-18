-- Permite que o colaborador solicitante de um chamado leia o registro
-- do usuário que resolveu o chamado (para exibir o full_name do resolvedor).
CREATE POLICY "Solicitante colaborador pode ler resolvedor do chamado"
ON public.usuarios
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.chamados c
    WHERE c.resolvido_por = usuarios.id
      AND c.solicitante_id = auth.uid()
      AND public.is_colaborador_user(auth.uid())
  )
);