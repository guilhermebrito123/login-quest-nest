
-- 1) Funções auxiliares de permissão
CREATE OR REPLACE FUNCTION public.current_internal_access_level()
RETURNS public.internal_access_level
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT ip.nivel_acesso
  FROM public.internal_profiles ip
  WHERE ip.user_id = auth.uid()
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.current_internal_access_level() = 'admin'::public.internal_access_level;
$$;

CREATE OR REPLACE FUNCTION public.is_internal_user()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.current_internal_access_level() IS NOT NULL;
$$;

-- 2) RLS: remover policies existentes
DROP POLICY IF EXISTS "Admins podem ler todas diarias temporarias" ON public.diarias_temporarias;
DROP POLICY IF EXISTS "Deletar apenas diarias canceladas ou reprovadas" ON public.diarias_temporarias;
DROP POLICY IF EXISTS "Usuarios autenticados podem atualizar diarias temporarias" ON public.diarias_temporarias;
DROP POLICY IF EXISTS "Usuarios autenticados podem criar diarias temporarias" ON public.diarias_temporarias;
DROP POLICY IF EXISTS diarias_temporarias_select_policy ON public.diarias_temporarias;
DROP POLICY IF EXISTS diarias_temporarias_insert_policy ON public.diarias_temporarias;
DROP POLICY IF EXISTS diarias_temporarias_update_policy ON public.diarias_temporarias;
DROP POLICY IF EXISTS diarias_temporarias_delete_policy ON public.diarias_temporarias;

ALTER TABLE public.diarias_temporarias ENABLE ROW LEVEL SECURITY;

-- SELECT: qualquer usuário interno
CREATE POLICY diarias_temporarias_select_policy
ON public.diarias_temporarias
FOR SELECT
TO authenticated
USING (public.is_internal_user());

-- INSERT
CREATE POLICY diarias_temporarias_insert_policy
ON public.diarias_temporarias
FOR INSERT
TO authenticated
WITH CHECK (
  public.current_internal_access_level() = ANY(ARRAY[
    'admin',
    'gestor_operacoes',
    'supervisor',
    'assistente_operacoes',
    'tecnico'
  ]::public.internal_access_level[])
);

-- UPDATE
CREATE POLICY diarias_temporarias_update_policy
ON public.diarias_temporarias
FOR UPDATE
TO authenticated
USING (
  public.current_internal_access_level() = ANY(ARRAY[
    'admin',
    'gestor_operacoes',
    'supervisor',
    'assistente_operacoes',
    'tecnico',
    'analista_centro_controle',
    'assistente_financeiro',
    'gestor_financeiro'
  ]::public.internal_access_level[])
)
WITH CHECK (
  public.current_internal_access_level() = ANY(ARRAY[
    'admin',
    'gestor_operacoes',
    'supervisor',
    'assistente_operacoes',
    'tecnico',
    'analista_centro_controle',
    'assistente_financeiro',
    'gestor_financeiro'
  ]::public.internal_access_level[])
);

-- DELETE: apenas admin
CREATE POLICY diarias_temporarias_delete_policy
ON public.diarias_temporarias
FOR DELETE
TO authenticated
USING (public.is_admin_user());

-- 3) Trigger: autorizar transições de status + ok_pagamento
CREATE OR REPLACE FUNCTION public.autorizar_transicoes_diaria_temporaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_level public.internal_access_level;
  v_bypass text;
BEGIN
  -- Respeitar bypass de RPC
  BEGIN
    v_bypass := current_setting('app.rpc_call', true);
  EXCEPTION WHEN OTHERS THEN
    v_bypass := NULL;
  END;
  
  IF v_bypass IN ('true', 'justificar_falta', 'reverter_justificativa') THEN
    RETURN NEW;
  END IF;

  v_level := public.current_internal_access_level();

  IF v_level IS NULL THEN
    RAISE EXCEPTION 'Usuário não possui perfil interno para operar diárias temporárias.';
  END IF;

  -- Admin faz tudo
  IF v_level = 'admin'::public.internal_access_level THEN
    IF NEW.ok_pagamento IS DISTINCT FROM OLD.ok_pagamento THEN
      NEW.ok_pagamento_em := now();
      NEW.ok_pagamento_por := auth.uid();
      IF NEW.ok_pagamento = true THEN
        NEW.status := 'Paga'::public.status_diaria;
        NEW.paga_em := now();
        NEW.paga_por := auth.uid();
      END IF;
    END IF;

    IF NEW.status IS DISTINCT FROM OLD.status THEN
      IF NEW.status = 'Confirmada'::public.status_diaria THEN
        NEW.confirmada_em := COALESCE(NEW.confirmada_em, now());
        NEW.confirmada_por := COALESCE(NEW.confirmada_por, auth.uid());
      ELSIF NEW.status = 'Aprovada'::public.status_diaria THEN
        NEW.aprovada_em := COALESCE(NEW.aprovada_em, now());
        NEW.aprovada_por := COALESCE(NEW.aprovada_por, auth.uid());
      ELSIF NEW.status = 'Lançada para pagamento'::public.status_diaria THEN
        NEW.lancada_em := COALESCE(NEW.lancada_em, now());
        NEW.lancada_por := COALESCE(NEW.lancada_por, auth.uid());
      ELSIF NEW.status = 'Cancelada'::public.status_diaria THEN
        NEW.cancelada_em := COALESCE(NEW.cancelada_em, now());
        NEW.cancelada_por := COALESCE(NEW.cancelada_por, auth.uid());
      ELSIF NEW.status = 'Reprovada'::public.status_diaria THEN
        NEW.reprovada_em := COALESCE(NEW.reprovada_em, now());
        NEW.reprovada_por := COALESCE(NEW.reprovada_por, auth.uid());
      END IF;
    END IF;

    RETURN NEW;
  END IF;

  -- ok_pagamento: somente admin
  IF NEW.ok_pagamento IS DISTINCT FROM OLD.ok_pagamento THEN
    RAISE EXCEPTION 'Somente admin pode alterar ok_pagamento.';
  END IF;

  -- Mudança de status
  IF NEW.status IS DISTINCT FROM OLD.status THEN

    -- CONFIRMAR
    IF NEW.status = 'Confirmada'::public.status_diaria THEN
      IF NOT (v_level = ANY(ARRAY[
        'gestor_operacoes',
        'supervisor',
        'assistente_operacoes',
        'tecnico'
      ]::public.internal_access_level[])) THEN
        RAISE EXCEPTION 'Sem permissão para marcar como Confirmada.';
      END IF;
      IF OLD.status IS DISTINCT FROM 'Aguardando confirmacao'::public.status_diaria THEN
        RAISE EXCEPTION 'Só é permitido confirmar quando o status atual é Aguardando confirmacao.';
      END IF;
      NEW.confirmada_em := now();
      NEW.confirmada_por := auth.uid();

    -- APROVAR
    ELSIF NEW.status = 'Aprovada'::public.status_diaria THEN
      IF NOT (v_level = ANY(ARRAY[
        'gestor_operacoes'
      ]::public.internal_access_level[])) THEN
        RAISE EXCEPTION 'Somente admin ou gestor_operacoes pode marcar como Aprovada.';
      END IF;
      IF OLD.status IS DISTINCT FROM 'Confirmada'::public.status_diaria THEN
        RAISE EXCEPTION 'Só é permitido aprovar quando o status atual é Confirmada.';
      END IF;
      NEW.aprovada_em := now();
      NEW.aprovada_por := auth.uid();

    -- LANÇAR PARA PAGAMENTO
    ELSIF NEW.status = 'Lançada para pagamento'::public.status_diaria THEN
      IF NOT (v_level = ANY(ARRAY[
        'assistente_financeiro',
        'gestor_financeiro'
      ]::public.internal_access_level[])) THEN
        RAISE EXCEPTION 'Somente financeiro (assistente/gestor) ou admin pode lançar para pagamento.';
      END IF;
      IF OLD.status IS DISTINCT FROM 'Aprovada'::public.status_diaria THEN
        RAISE EXCEPTION 'Só é permitido lançar para pagamento quando o status atual é Aprovada.';
      END IF;
      NEW.lancada_em := now();
      NEW.lancada_por := auth.uid();

    -- CANCELAR (permitido mesmo se Paga)
    ELSIF NEW.status = 'Cancelada'::public.status_diaria THEN
      IF NOT (v_level = ANY(ARRAY[
        'gestor_operacoes',
        'supervisor',
        'assistente_operacoes'
      ]::public.internal_access_level[])) THEN
        RAISE EXCEPTION 'Somente Operações (incl. assistente) ou admin pode cancelar.';
      END IF;
      NEW.cancelada_em := now();
      NEW.cancelada_por := auth.uid();

    -- PAGA: não pode setar manualmente
    ELSIF NEW.status = 'Paga'::public.status_diaria THEN
      RAISE EXCEPTION 'Status Paga só pode ser definido automaticamente via ok_pagamento por admin.';

    -- REPROVADA: somente admin
    ELSIF NEW.status = 'Reprovada'::public.status_diaria THEN
      RAISE EXCEPTION 'Somente admin pode reprovar.';

    ELSE
      RAISE EXCEPTION 'Transição de status não permitida.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_autorizar_transicoes_diaria_temporaria ON public.diarias_temporarias;

CREATE TRIGGER trg_autorizar_transicoes_diaria_temporaria
BEFORE UPDATE ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.autorizar_transicoes_diaria_temporaria();

-- 4) Trigger: lock estrutural (reutiliza função existente)
DROP TRIGGER IF EXISTS trg_bloquear_edicao_diaria_temporaria ON public.diarias_temporarias;

CREATE TRIGGER trg_bloquear_edicao_diaria_temporaria
BEFORE UPDATE ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.bloquear_edicao_diaria_temporaria();
