-- Atualizar política de DELETE na tabela diarias
-- Apenas diárias com status "Cancelada" podem ser excluídas
DROP POLICY IF EXISTS "Usuarios autorizados podem deletar diarias" ON public.diarias;

CREATE POLICY "Usuarios autorizados podem deletar diarias"
ON public.diarias
FOR DELETE
TO authenticated
USING (
  (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'gestor_operacoes'::app_role))
  AND status = 'Cancelada'::status_diaria
);