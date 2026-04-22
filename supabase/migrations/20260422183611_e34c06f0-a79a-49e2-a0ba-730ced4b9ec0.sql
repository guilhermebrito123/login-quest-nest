
-- 1. Atualiza a função usada pelo RLS de INSERT em plano_acao_responsaveis:
--    APENAS colaboradores ativos vinculados ao CC do plano são elegíveis.
CREATE OR REPLACE FUNCTION public.can_assign_action_plan_user(_assigned_user_id uuid, _cost_center_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.module_is_colaborador_in_cc(_assigned_user_id, _cost_center_id)
$$;


-- 2. Atualiza a RPC consumida pelo frontend: somente colaboradores do CC.
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
  -- Bloqueia se o usuário logado não puder gerenciar o plano (admin ou supervisor do CC).
  IF NOT public.get_current_user_can_manage_plan(_plano_acao_id) THEN
    RETURN;
  END IF;

  SELECT i.cost_center_id
    INTO _cc_id
  FROM public.planos_acao p
  JOIN public.checklist_instancias i ON i.id = p.checklist_instancia_id
  WHERE p.id = _plano_acao_id;

  IF _cc_id IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    u.id                                        AS user_id,
    COALESCE(NULLIF(TRIM(u.nome), ''), u.email) AS nome,
    u.email                                     AS email,
    'colaborador'::text                         AS tipo,
    NULL::text                                  AS nivel_acesso
  FROM public.usuarios u
  JOIN public.colaborador_profiles cp ON cp.user_id = u.id
  WHERE u.role = 'colaborador'
    AND cp.ativo = true
    AND cp.cost_center_id = _cc_id
  ORDER BY nome;
END;
$$;


-- 3. Trigger de validação como segunda camada de defesa:
--    garante a regra em qualquer INSERT/UPDATE, inclusive escritas diretas.
CREATE OR REPLACE FUNCTION public.validate_plano_acao_responsavel()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _cc_id uuid;
BEGIN
  SELECT i.cost_center_id
    INTO _cc_id
  FROM public.planos_acao p
  JOIN public.checklist_instancias i ON i.id = p.checklist_instancia_id
  WHERE p.id = NEW.plano_acao_id;

  IF _cc_id IS NULL THEN
    RAISE EXCEPTION 'Plano de ação % não possui cost center vinculado', NEW.plano_acao_id
      USING ERRCODE = 'check_violation';
  END IF;

  IF NOT public.module_is_colaborador_in_cc(NEW.assigned_user_id, _cc_id) THEN
    RAISE EXCEPTION 'Apenas colaboradores ativos vinculados ao centro de custo do plano podem ser atribuídos como responsáveis'
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_plano_acao_responsavel ON public.plano_acao_responsaveis;

CREATE TRIGGER trg_validate_plano_acao_responsavel
BEFORE INSERT OR UPDATE OF assigned_user_id, plano_acao_id
ON public.plano_acao_responsaveis
FOR EACH ROW
EXECUTE FUNCTION public.validate_plano_acao_responsavel();
