
-- Helper: o usuário logado pode gerenciar (atribuir/remover responsáveis) de um plano específico?
CREATE OR REPLACE FUNCTION public.get_current_user_can_manage_plan(_plano_acao_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.planos_acao p
    JOIN public.checklist_instancias i ON i.id = p.checklist_instancia_id
    WHERE p.id = _plano_acao_id
      AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
  )
$$;

GRANT EXECUTE ON FUNCTION public.get_current_user_can_manage_plan(uuid) TO authenticated;


-- Lista de usuários elegíveis a serem atribuídos como responsáveis de um plano de ação.
-- Espelha exatamente as regras do RLS de INSERT em plano_acao_responsaveis:
--   (a) Colaboradores ativos vinculados ao CC do plano.
--   (b) Perfis internos (não cliente_view) que sejam admin OU vinculados ao CC.
CREATE OR REPLACE FUNCTION public.get_action_plan_assignable_users(_plano_acao_id uuid)
RETURNS TABLE (
  user_id uuid,
  nome text,
  email text,
  tipo text,
  nivel_acesso text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _cc_id uuid;
BEGIN
  -- Bloqueia se o usuário logado não puder gerenciar o plano.
  IF NOT public.get_current_user_can_manage_plan(_plano_acao_id) THEN
    RETURN;
  END IF;

  -- Resolve o CC do plano.
  SELECT i.cost_center_id
    INTO _cc_id
  FROM public.planos_acao p
  JOIN public.checklist_instancias i ON i.id = p.checklist_instancia_id
  WHERE p.id = _plano_acao_id;

  IF _cc_id IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH colaboradores AS (
    SELECT
      u.id              AS user_id,
      COALESCE(NULLIF(TRIM(u.nome), ''), u.email) AS nome,
      u.email           AS email,
      'colaborador'::text AS tipo,
      NULL::text        AS nivel_acesso
    FROM public.usuarios u
    JOIN public.colaborador_profiles cp ON cp.user_id = u.id
    WHERE u.role = 'colaborador'
      AND cp.ativo = true
      AND cp.cost_center_id = _cc_id
  ),
  internos AS (
    SELECT
      u.id              AS user_id,
      COALESCE(NULLIF(TRIM(u.nome), ''), u.email) AS nome,
      u.email           AS email,
      'interno'::text   AS tipo,
      ip.nivel_acesso::text AS nivel_acesso
    FROM public.internal_profiles ip
    JOIN public.usuarios u ON u.id = ip.user_id
    LEFT JOIN public.internal_profile_cost_centers ipcc
      ON ipcc.user_id = ip.user_id AND ipcc.cost_center_id = _cc_id
    WHERE ip.nivel_acesso <> 'cliente_view'
      AND (ip.nivel_acesso = 'admin' OR ipcc.cost_center_id = _cc_id)
  )
  SELECT * FROM colaboradores
  UNION
  SELECT * FROM internos
  ORDER BY tipo, nome;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_action_plan_assignable_users(uuid) TO authenticated;
