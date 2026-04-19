-- =====================================================
-- Fluxo de recuperação manual de senha via suporte
-- =====================================================

-- 1) Pedidos de recuperação manual abertos pelo usuário
CREATE TABLE IF NOT EXISTS public.account_recovery_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NULL REFERENCES public.usuarios(id) ON DELETE SET NULL,
  requested_identifier text NOT NULL,
  status text NOT NULL CHECK (status IN ('pending', 'approved', 'rejected', 'consumed', 'expired')),
  reason text NULL,
  opened_at timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz NULL,
  reviewed_by uuid NULL REFERENCES public.usuarios(id) ON DELETE SET NULL,
  rejection_reason text NULL,
  ip text NULL,
  user_agent text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_arr_status ON public.account_recovery_requests(status);
CREATE INDEX IF NOT EXISTS idx_arr_user_id ON public.account_recovery_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_arr_opened_at ON public.account_recovery_requests(opened_at DESC);

-- 2) Sessão curta gerada após aprovação do admin (token entregue ao usuário)
CREATE TABLE IF NOT EXISTS public.account_recovery_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid NOT NULL REFERENCES public.account_recovery_requests(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  token_hash text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  consumed_at timestamptz NULL,
  ip text NULL,
  user_agent text NULL
);

CREATE INDEX IF NOT EXISTS idx_ars_user_id ON public.account_recovery_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_ars_expires_at ON public.account_recovery_sessions(expires_at);

-- 3) Auditoria
CREATE TABLE IF NOT EXISTS public.account_recovery_audit (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid NULL REFERENCES public.account_recovery_requests(id) ON DELETE SET NULL,
  user_id uuid NULL REFERENCES public.usuarios(id) ON DELETE SET NULL,
  actor_user_id uuid NULL REFERENCES public.usuarios(id) ON DELETE SET NULL,
  action text NOT NULL,
  metadata jsonb NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ara_request_id ON public.account_recovery_audit(request_id);
CREATE INDEX IF NOT EXISTS idx_ara_user_id ON public.account_recovery_audit(user_id);
CREATE INDEX IF NOT EXISTS idx_ara_created_at ON public.account_recovery_audit(created_at DESC);

-- =====================================================
-- RLS
-- =====================================================
ALTER TABLE public.account_recovery_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_recovery_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_recovery_audit ENABLE ROW LEVEL SECURITY;

-- Apenas admins podem ler pedidos de recuperação
CREATE POLICY "Admins podem ler pedidos de recuperacao"
ON public.account_recovery_requests
FOR SELECT
TO authenticated
USING (has_role(auth.uid(), 'admin'::internal_access_level));

-- Apenas admins podem ver auditoria
CREATE POLICY "Admins podem ler auditoria de recuperacao"
ON public.account_recovery_audit
FOR SELECT
TO authenticated
USING (has_role(auth.uid(), 'admin'::internal_access_level));

-- Sessões: nenhuma policy de cliente. Apenas service_role acessa via Edge Function.

-- =====================================================
-- Trigger para updated_at
-- =====================================================
CREATE OR REPLACE FUNCTION public.update_account_recovery_requests_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_arr_updated_at ON public.account_recovery_requests;
CREATE TRIGGER trg_arr_updated_at
BEFORE UPDATE ON public.account_recovery_requests
FOR EACH ROW
EXECUTE FUNCTION public.update_account_recovery_requests_updated_at();