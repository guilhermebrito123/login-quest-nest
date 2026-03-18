
CREATE OR REPLACE FUNCTION public.fn_horas_extras_before_ins_upd()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_diaria_id bigint;
  v_falta_colaborador_id uuid;
  v_falta_motivo text;
  v_falta_local uuid;
  v_falta_data date;
  v_conflict_count integer;
  v_rpc_call text;
BEGIN
  NEW.updated_at := now();

  -- Check session variable for cascade bypass
  BEGIN
    v_rpc_call := current_setting('app.rpc_call', true);
  EXCEPTION WHEN OTHERS THEN
    v_rpc_call := '';
  END;

  -- local_hora_extra immutable on update UNLESS cascading from falta
  IF TG_OP = 'UPDATE' AND NEW.local_hora_extra IS DISTINCT FROM OLD.local_hora_extra THEN
    IF v_rpc_call IS DISTINCT FROM 'cascade_falta_local' THEN
      RAISE EXCEPTION 'local_hora_extra da hora extra não pode ser alterado após a criação';
    END IF;
  END IF;

  -- validate falta (only when falta_id is provided)
  IF NEW.falta_id IS NOT NULL THEN
    SELECT
      f.diaria_temporaria_id,
      f.colaborador_convenia_id,
      f.motivo,
      f.local_falta,
      f.data_falta
    INTO
      v_diaria_id,
      v_falta_colaborador_id,
      v_falta_motivo,
      v_falta_local,
      v_falta_data
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

    -- Enforce operacao based on falta motivo
    IF v_falta_motivo = 'FALTA INJUSTIFICADA' AND NEW.operacao != 'cobertura_falta' THEN
      RAISE EXCEPTION 'Para falta injustificada, a operação deve ser "cobertura_falta"';
    END IF;

    IF v_falta_motivo = 'FALTA JUSTIFICADA' AND NEW.operacao != 'cobertura_falta_atestado' THEN
      RAISE EXCEPTION 'Para falta justificada (atestado), a operação deve ser "cobertura_falta_atestado"';
    END IF;

    -- Auto-set local_hora_extra from falta
    IF v_falta_local IS NULL THEN
      RAISE EXCEPTION 'A falta referenciada não possui local_falta definido. Preencha o local da falta antes de criar a hora extra.';
    END IF;

    IF TG_OP = 'INSERT' THEN
      NEW.local_hora_extra := v_falta_local;
      NEW.data_hora_extra := v_falta_data;
    END IF;
  ELSE
    -- Without falta_id: local and data must be provided manually
    IF TG_OP = 'INSERT' AND NEW.local_hora_extra IS NULL THEN
      RAISE EXCEPTION 'O local da hora extra (local_hora_extra) é obrigatório e deve ser informado manualmente';
    END IF;

    IF TG_OP = 'INSERT' AND NEW.data_hora_extra IS NULL THEN
      RAISE EXCEPTION 'A data da hora extra (data_hora_extra) é obrigatória e deve ser informada manualmente';
    END IF;
  END IF;

  -- data_hora_extra immutable on update
  IF TG_OP = 'UPDATE' AND NEW.data_hora_extra IS DISTINCT FROM OLD.data_hora_extra THEN
    IF v_rpc_call IS DISTINCT FROM 'cascade_falta_data' THEN
      RAISE EXCEPTION 'data_hora_extra da hora extra não pode ser alterado após a criação';
    END IF;
  END IF;

  -- Overlap check for same colaborador on active records
  IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND (
    NEW.inicio_em IS DISTINCT FROM OLD.inicio_em OR
    NEW.fim_em IS DISTINCT FROM OLD.fim_em OR
    NEW.colaborador_cobrindo_id IS DISTINCT FROM OLD.colaborador_cobrindo_id OR
    NEW.status IS DISTINCT FROM OLD.status
  )) THEN
    IF NEW.status NOT IN ('cancelada', 'reprovada') THEN
      SELECT count(*) INTO v_conflict_count
      FROM public.horas_extras
      WHERE colaborador_cobrindo_id = NEW.colaborador_cobrindo_id
        AND id IS DISTINCT FROM NEW.id
        AND status NOT IN ('cancelada', 'reprovada')
        AND tstzrange(inicio_em, fim_em, '[)') && tstzrange(NEW.inicio_em, NEW.fim_em, '[)');

      IF v_conflict_count > 0 THEN
        RAISE EXCEPTION 'Conflito de horário: o colaborador já possui hora extra ativa nesse período';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Update cascade function to set bypass variable
CREATE OR REPLACE FUNCTION public.fn_faltas_convenia_cascade_data_hora_extra()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_diff interval;
  v_saved_rpc text;
BEGIN
  -- Save current rpc_call
  BEGIN
    v_saved_rpc := current_setting('app.rpc_call', true);
  EXCEPTION WHEN OTHERS THEN
    v_saved_rpc := '';
  END;

  -- Cascade data_falta changes
  IF NEW.data_falta IS DISTINCT FROM OLD.data_falta THEN
    v_diff := (NEW.data_falta - OLD.data_falta) * interval '1 day';

    PERFORM set_config('app.rpc_call', 'cascade_falta_data', true);

    UPDATE public.horas_extras
    SET
      inicio_em            = inicio_em + v_diff,
      fim_em               = fim_em + v_diff,
      intervalo_inicio_em  = CASE
                               WHEN intervalo_inicio_em IS NOT NULL
                               THEN intervalo_inicio_em + v_diff
                               ELSE NULL
                             END,
      intervalo_fim_em     = CASE
                               WHEN intervalo_fim_em IS NOT NULL
                               THEN intervalo_fim_em + v_diff
                               ELSE NULL
                             END,
      data_hora_extra      = NEW.data_falta,
      updated_at           = now()
    WHERE falta_id = NEW.id
      AND status NOT IN ('cancelada', 'reprovada');

    PERFORM set_config('app.rpc_call', coalesce(v_saved_rpc, ''), true);
  END IF;

  -- Cascade local_falta changes
  IF NEW.local_falta IS DISTINCT FROM OLD.local_falta THEN
    PERFORM set_config('app.rpc_call', 'cascade_falta_local', true);

    UPDATE public.horas_extras
    SET
      local_hora_extra = NEW.local_falta,
      updated_at       = now()
    WHERE falta_id = NEW.id
      AND status NOT IN ('cancelada', 'reprovada');

    PERFORM set_config('app.rpc_call', coalesce(v_saved_rpc, ''), true);
  END IF;

  RETURN NEW;
END;
$$;
