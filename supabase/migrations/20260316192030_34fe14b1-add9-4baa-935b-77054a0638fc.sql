
-- 1) Enums
CREATE TYPE public.status_hora_extra AS ENUM (
  'pendente',
  'confirmada',
  'aprovada',
  'reprovada',
  'cancelada'
);

CREATE TYPE public.motivo_reprovacao_hora_extra AS ENUM (
  'horario_invalido',
  'dados_inconsistentes',
  'colaborador_indisponivel',
  'falta_sem_validacao',
  'duplicidade',
  'outros'
);

CREATE TYPE public.motivo_cancelamento_hora_extra AS ENUM (
  'cobertura_nao_necessaria',
  'lancamento_indevido',
  'substituicao_reorganizada',
  'erro_operacional',
  'outros'
);

-- 2) Extension for exclusion constraint
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- 3) Table
CREATE TABLE public.horas_extras (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  falta_id bigint NOT NULL
    REFERENCES public.faltas_colaboradores_convenia(id),

  colaborador_cobrindo_id uuid NOT NULL
    REFERENCES public.colaboradores_convenia(id),

  cost_center_id uuid NOT NULL
    REFERENCES public.cost_center(id),

  operacao text NOT NULL,

  inicio_em timestamptz NOT NULL,
  intervalo_inicio_em timestamptz NULL,
  intervalo_fim_em timestamptz NULL,
  fim_em timestamptz NOT NULL,

  observacao text NULL,

  status public.status_hora_extra NOT NULL DEFAULT 'pendente',

  criado_por uuid NOT NULL
    REFERENCES public.usuarios(id),
  criado_em timestamptz NOT NULL DEFAULT now(),

  confirmado_por uuid NULL
    REFERENCES public.usuarios(id),
  confirmado_em timestamptz NULL,

  aprovado_por uuid NULL
    REFERENCES public.usuarios(id),
  aprovado_em timestamptz NULL,

  reprovado_por uuid NULL
    REFERENCES public.usuarios(id),
  reprovado_em timestamptz NULL,
  motivo_reprovacao public.motivo_reprovacao_hora_extra NULL,
  detalhe_reprovacao text NULL,

  cancelado_por uuid NULL
    REFERENCES public.usuarios(id),
  cancelado_em timestamptz NULL,
  motivo_cancelamento public.motivo_cancelamento_hora_extra NULL,
  detalhe_cancelamento text NULL,

  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 4) Validation trigger (replaces CHECK constraints for consistency rules)
CREATE OR REPLACE FUNCTION public.fn_horas_extras_validar_constraints()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- fim > inicio
  IF NEW.fim_em <= NEW.inicio_em THEN
    RAISE EXCEPTION 'fim_em deve ser maior que inicio_em';
  END IF;

  -- intervalo consistency
  IF (NEW.intervalo_inicio_em IS NULL) != (NEW.intervalo_fim_em IS NULL) THEN
    RAISE EXCEPTION 'intervalo_inicio_em e intervalo_fim_em devem ser ambos preenchidos ou ambos nulos';
  END IF;

  IF NEW.intervalo_inicio_em IS NOT NULL THEN
    IF NEW.intervalo_inicio_em < NEW.inicio_em THEN
      RAISE EXCEPTION 'intervalo_inicio_em deve ser >= inicio_em';
    END IF;
    IF NEW.intervalo_fim_em > NEW.fim_em THEN
      RAISE EXCEPTION 'intervalo_fim_em deve ser <= fim_em';
    END IF;
    IF NEW.intervalo_fim_em <= NEW.intervalo_inicio_em THEN
      RAISE EXCEPTION 'intervalo_fim_em deve ser > intervalo_inicio_em';
    END IF;
  END IF;

  -- confirmacao consistency
  IF NEW.status = 'confirmada' AND (NEW.confirmado_por IS NULL OR NEW.confirmado_em IS NULL) THEN
    RAISE EXCEPTION 'Status confirmada requer confirmado_por e confirmado_em';
  END IF;

  -- aprovacao consistency
  IF NEW.status = 'aprovada' AND (NEW.aprovado_por IS NULL OR NEW.aprovado_em IS NULL) THEN
    RAISE EXCEPTION 'Status aprovada requer aprovado_por e aprovado_em';
  END IF;

  -- reprovacao consistency
  IF NEW.status = 'reprovada' AND (NEW.reprovado_por IS NULL OR NEW.reprovado_em IS NULL OR NEW.motivo_reprovacao IS NULL) THEN
    RAISE EXCEPTION 'Status reprovada requer reprovado_por, reprovado_em e motivo_reprovacao';
  END IF;

  -- cancelamento consistency
  IF NEW.status = 'cancelada' AND (NEW.cancelado_por IS NULL OR NEW.cancelado_em IS NULL OR NEW.motivo_cancelamento IS NULL) THEN
    RAISE EXCEPTION 'Status cancelada requer cancelado_por, cancelado_em e motivo_cancelamento';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_horas_extras_validar_constraints
  BEFORE INSERT OR UPDATE ON public.horas_extras
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_horas_extras_validar_constraints();

-- 5) Business logic trigger
CREATE OR REPLACE FUNCTION public.fn_horas_extras_before_ins_upd()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_cost_center_id uuid;
  v_diaria_id bigint;
  v_falta_colaborador_id uuid;
  v_conflict_count integer;
BEGIN
  NEW.updated_at := now();

  -- cost_center_id immutable on update
  IF TG_OP = 'UPDATE' AND NEW.cost_center_id IS DISTINCT FROM OLD.cost_center_id THEN
    RAISE EXCEPTION 'cost_center_id da hora extra não pode ser alterado após a criação';
  END IF;

  -- validate falta
  SELECT
    f.diaria_temporaria_id,
    f.colaborador_convenia_id
  INTO
    v_diaria_id,
    v_falta_colaborador_id
  FROM public.faltas_colaboradores_convenia f
  WHERE f.id = NEW.falta_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Falta informada não encontrada';
  END IF;

  IF v_diaria_id IS NOT NULL THEN
    RAISE EXCEPTION 'Não é possível cadastrar hora extra: esta falta já possui diária temporária vinculada';
  END IF;

  IF v_falta_colaborador_id IS NULL THEN
    RAISE EXCEPTION 'A falta informada não possui colaborador ausente vinculado';
  END IF;

  IF v_falta_colaborador_id = NEW.colaborador_cobrindo_id THEN
    RAISE EXCEPTION 'O colaborador que cobre a falta não pode ser o mesmo colaborador faltante';
  END IF;

  -- auto-fill cost_center_id on insert
  IF TG_OP = 'INSERT' THEN
    SELECT c.cost_center_id
      INTO v_cost_center_id
    FROM public.colaboradores_convenia c
    WHERE c.id = v_falta_colaborador_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Colaborador ausente vinculado à falta não encontrado';
    END IF;

    IF v_cost_center_id IS NULL THEN
      RAISE EXCEPTION 'O colaborador ausente não possui cost_center_id vinculado';
    END IF;

    NEW.cost_center_id := v_cost_center_id;
  END IF;

  -- check time overlap for colaborador_cobrindo_id
  SELECT count(*) INTO v_conflict_count
  FROM public.horas_extras h
  WHERE h.colaborador_cobrindo_id = NEW.colaborador_cobrindo_id
    AND h.status IN ('pendente', 'confirmada', 'aprovada')
    AND h.id IS DISTINCT FROM NEW.id
    AND tstzrange(h.inicio_em, h.fim_em, '[)') && tstzrange(NEW.inicio_em, NEW.fim_em, '[)');

  IF v_conflict_count > 0 THEN
    RAISE EXCEPTION 'Já existe hora extra ativa (pendente/confirmada/aprovada) com horário sobreposto para este colaborador';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_horas_extras_before_ins_upd
  BEFORE INSERT OR UPDATE ON public.horas_extras
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_horas_extras_before_ins_upd();

-- 6) Unique index: only one active hora_extra per falta
CREATE UNIQUE INDEX horas_extras_falta_id_ativa_unique
  ON public.horas_extras (falta_id)
  WHERE status IN ('pendente', 'confirmada', 'aprovada');

-- 7) Useful indexes
CREATE INDEX idx_horas_extras_falta_id ON public.horas_extras (falta_id);
CREATE INDEX idx_horas_extras_colaborador_cobrindo_id ON public.horas_extras (colaborador_cobrindo_id);
CREATE INDEX idx_horas_extras_cost_center_id ON public.horas_extras (cost_center_id);
CREATE INDEX idx_horas_extras_status ON public.horas_extras (status);
CREATE INDEX idx_horas_extras_inicio_fim ON public.horas_extras (inicio_em, fim_em);

-- 8) RLS
ALTER TABLE public.horas_extras ENABLE ROW LEVEL SECURITY;

CREATE POLICY "horas_extras_select"
  ON public.horas_extras
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "horas_extras_insert"
  ON public.horas_extras
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.current_internal_access_level() NOT IN (
      'assistente_financeiro',
      'gestor_financeiro',
      'cliente_view'
    )
    AND criado_por = auth.uid()
  );

CREATE POLICY "horas_extras_update"
  ON public.horas_extras
  FOR UPDATE
  TO authenticated
  USING (
    public.current_internal_access_level() IN (
      'admin',
      'gestor_operacoes',
      'supervisor',
      'analista_centro_controle',
      'assistente_operacoes'
    )
  );

-- 9) RPCs

-- Criar hora extra
CREATE OR REPLACE FUNCTION public.criar_hora_extra(
  p_falta_id bigint,
  p_colaborador_cobrindo_id uuid,
  p_operacao text,
  p_inicio_em timestamptz,
  p_fim_em timestamptz,
  p_intervalo_inicio_em timestamptz DEFAULT NULL,
  p_intervalo_fim_em timestamptz DEFAULT NULL,
  p_observacao text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.internal_access_level;
  v_id uuid;
BEGIN
  v_role := public.current_internal_access_level();

  IF v_role IN ('assistente_financeiro', 'gestor_financeiro', 'cliente_view') THEN
    RAISE EXCEPTION 'Usuário sem permissão para cadastrar hora extra';
  END IF;

  INSERT INTO public.horas_extras (
    falta_id,
    colaborador_cobrindo_id,
    cost_center_id,
    operacao,
    inicio_em,
    intervalo_inicio_em,
    intervalo_fim_em,
    fim_em,
    observacao,
    status,
    criado_por
  )
  VALUES (
    p_falta_id,
    p_colaborador_cobrindo_id,
    '00000000-0000-0000-0000-000000000000'::uuid, -- trigger will overwrite
    p_operacao,
    p_inicio_em,
    p_intervalo_inicio_em,
    p_intervalo_fim_em,
    p_fim_em,
    p_observacao,
    'pendente',
    auth.uid()
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

-- Confirmar hora extra
CREATE OR REPLACE FUNCTION public.confirmar_hora_extra(
  p_hora_extra_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.horas_extras
     SET status = 'confirmada',
         confirmado_por = auth.uid(),
         confirmado_em = now(),
         updated_at = now()
   WHERE id = p_hora_extra_id
     AND status = 'pendente';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Hora extra não encontrada ou não está pendente';
  END IF;
END;
$$;

-- Aprovar hora extra
CREATE OR REPLACE FUNCTION public.aprovar_hora_extra(
  p_hora_extra_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.internal_access_level;
BEGIN
  v_role := public.current_internal_access_level();

  IF v_role NOT IN ('admin', 'gestor_operacoes', 'supervisor', 'analista_centro_controle') THEN
    RAISE EXCEPTION 'Usuário sem permissão para aprovar hora extra';
  END IF;

  UPDATE public.horas_extras
     SET status = 'aprovada',
         aprovado_por = auth.uid(),
         aprovado_em = now(),
         updated_at = now()
   WHERE id = p_hora_extra_id
     AND status IN ('pendente', 'confirmada');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Hora extra não encontrada ou não está pendente/confirmada';
  END IF;
END;
$$;

-- Reprovar hora extra
CREATE OR REPLACE FUNCTION public.reprovar_hora_extra(
  p_hora_extra_id uuid,
  p_motivo_reprovacao public.motivo_reprovacao_hora_extra,
  p_detalhe_reprovacao text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.internal_access_level;
BEGIN
  v_role := public.current_internal_access_level();

  IF v_role NOT IN ('admin', 'gestor_operacoes', 'supervisor', 'analista_centro_controle') THEN
    RAISE EXCEPTION 'Usuário sem permissão para reprovar hora extra';
  END IF;

  UPDATE public.horas_extras
     SET status = 'reprovada',
         reprovado_por = auth.uid(),
         reprovado_em = now(),
         motivo_reprovacao = p_motivo_reprovacao,
         detalhe_reprovacao = p_detalhe_reprovacao,
         updated_at = now()
   WHERE id = p_hora_extra_id
     AND status IN ('pendente', 'confirmada');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Hora extra não encontrada ou não está pendente/confirmada';
  END IF;
END;
$$;

-- Cancelar hora extra
CREATE OR REPLACE FUNCTION public.cancelar_hora_extra(
  p_hora_extra_id uuid,
  p_motivo_cancelamento public.motivo_cancelamento_hora_extra,
  p_detalhe_cancelamento text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.internal_access_level;
BEGIN
  v_role := public.current_internal_access_level();

  IF v_role NOT IN (
    'admin',
    'gestor_operacoes',
    'supervisor',
    'analista_centro_controle',
    'assistente_operacoes'
  ) THEN
    RAISE EXCEPTION 'Usuário sem permissão para cancelar hora extra';
  END IF;

  UPDATE public.horas_extras
     SET status = 'cancelada',
         cancelado_por = auth.uid(),
         cancelado_em = now(),
         motivo_cancelamento = p_motivo_cancelamento,
         detalhe_cancelamento = p_detalhe_cancelamento,
         updated_at = now()
   WHERE id = p_hora_extra_id
     AND status IN ('pendente', 'confirmada');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Hora extra não encontrada ou não está pendente/confirmada';
  END IF;
END;
$$;
