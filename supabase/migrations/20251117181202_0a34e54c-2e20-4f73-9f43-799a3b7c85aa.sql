-- Adicionar políticas de DELETE para execucao_checklist
CREATE POLICY "Usuarios autorizados podem deletar execucoes"
ON public.execucao_checklist
FOR DELETE
USING (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
  has_role(auth.uid(), 'supervisor'::app_role)
);

-- Adicionar políticas de DELETE para execucao_checklist_item
CREATE POLICY "Usuarios autorizados podem deletar execucoes item"
ON public.execucao_checklist_item
FOR DELETE
USING (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
  has_role(auth.uid(), 'supervisor'::app_role)
);