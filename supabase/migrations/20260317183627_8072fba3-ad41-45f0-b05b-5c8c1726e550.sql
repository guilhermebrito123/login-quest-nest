
-- Add data_hora_extra column
ALTER TABLE public.horas_extras ADD COLUMN data_hora_extra date NOT NULL DEFAULT CURRENT_DATE;

-- Remove the default after adding
ALTER TABLE public.horas_extras ALTER COLUMN data_hora_extra DROP DEFAULT;

-- Update trigger to handle data_hora_extra logic
CREATE OR REPLACE FUNCTION public.fn_horas_extras_before_ins_upd()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_diaria_id bigint;
  v_falta_colaborador_id uuid;
  v_falta_motivo text;
  v_falta_local uuid;
  v_falta_data date;
  v_conflict_count integer;
BEGIN
  NEW.updated_at := now();

  -- local_hora_extra immutable on update
  IF TG_OP = 'UPDATE' AND NEW.local_hora_extra IS DISTINCT FROM OLD.local_hora_extra THEN
    RAISE EXCEPTION 'local_hora_extra da hora extra não pode ser alterado após a criação';
  END IF;

  -- data_hora_extra immutable on update
  IF TG_OP = 'UPDATE' AND NEW.data_hora_extra IS DISTINCT FROM OLD.data_hora_extra THEN
    RAISE EXCEPTION 'data_hora_extra não pode ser alterada após a criação';
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
      -- Auto-set data_hora_extra from falta's data_falta
      NEW.data_hora_extra := v_falta_data;
    END IF;
  ELSE
    -- Without falta_id: local and data must be provided manually
    IF TG_OP = 'INSERT' AND NEW.local_hora_extra IS NULL THEN
      RAISE EXCEPTION 'O local da hora extra (local_hora_extra) é obrigatório e deve ser informado manualmente';
    END IF;

    IF TG_OP = 'INSERT' AND NEW.data_hora_extra IS NULL THEN
      RAISE EXCEPTION 'A data da hora extra (data_hora_extra) é obrigatória quando não há falta vinculada';
    END IF;
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
