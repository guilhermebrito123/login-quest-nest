CREATE OR REPLACE FUNCTION public.is_action_plan_responsavel(_user_id uuid, _plano_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.plano_acao_responsaveis
    WHERE plano_acao_id = _plano_id AND assigned_user_id = _user_id
  )
$$;

DROP POLICY IF EXISTS plano_select ON public.planos_acao;

CREATE POLICY plano_select ON public.planos_acao
FOR SELECT
USING (
  public.module_user_allowed(auth.uid()) AND EXISTS (
    SELECT 1 FROM public.checklist_instancias i
    WHERE i.id = planos_acao.checklist_instancia_id
      AND (
        public.module_is_admin(auth.uid())
        OR public.module_supervisor_has_cost_center(auth.uid(), i.cost_center_id)
        OR public.is_action_plan_responsavel(auth.uid(), planos_acao.id)
      )
  )
);