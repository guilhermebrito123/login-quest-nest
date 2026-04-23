
-- Ajusta a função is_action_plan_responsavel para considerar apenas responsáveis ativos
CREATE OR REPLACE FUNCTION public.is_action_plan_responsavel(_user_id uuid, _plano_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.plano_acao_responsaveis
    WHERE plano_acao_id = _plano_id
      AND assigned_user_id = _user_id
      AND ativo = true
  )
$$;
