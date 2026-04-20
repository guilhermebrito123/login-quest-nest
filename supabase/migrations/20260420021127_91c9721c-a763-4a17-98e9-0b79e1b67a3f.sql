-- Corrige search_path nas funções restantes
ALTER FUNCTION public.module_set_updated_at() SET search_path = public;
ALTER FUNCTION public.calc_next_recurrence(public.module_recurrence_type, integer, timestamptz) SET search_path = public;

-- Políticas faltantes em checklist_instancia_tarefas (snapshots — admins gerenciam)
CREATE POLICY "inst_tarefas_admin_modify" ON public.checklist_instancia_tarefas FOR ALL TO authenticated
USING (EXISTS (
  SELECT 1 FROM public.checklist_instancias i
  WHERE i.id = checklist_instancia_id
    AND (public.module_is_admin(auth.uid()) OR public.module_supervisor_has_cost_center(auth.uid(), i.cost_center_id))
))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.checklist_instancias i
  WHERE i.id = checklist_instancia_id
    AND (public.module_is_admin(auth.uid()) OR public.module_supervisor_has_cost_center(auth.uid(), i.cost_center_id))
));

-- Política de UPDATE/DELETE em module_audit_logs (somente admin, raramente usado)
CREATE POLICY "audit_admin_modify" ON public.module_audit_logs FOR UPDATE TO authenticated
USING (public.module_is_admin(auth.uid())) WITH CHECK (public.module_is_admin(auth.uid()));
CREATE POLICY "audit_admin_delete" ON public.module_audit_logs FOR DELETE TO authenticated
USING (public.module_is_admin(auth.uid()));