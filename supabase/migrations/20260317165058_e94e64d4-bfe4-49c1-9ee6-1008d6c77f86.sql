
CREATE OR REPLACE FUNCTION public.fn_horas_extras_before_ins_upd()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_diaria_id bigint;
  v_falta_colaborador_id uuid;
  v_conflict_count integer;
BEGIN
  NEW.updated_at := now();

  -- cost_center_id immutable on update
  IF TG_OP = 'UPDATE' AND NEW.cost_center_id IS DISTINCT FROM OLD.cost_center_id THEN
    RAISE EXCEPTION 'cost_center_id da hora extra não pode ser alterado após a criação';
  END IF;

  -- validate falta (only when falta_id is provided)
  IF NEW.falta_id IS NOT NULL THEN
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
  END IF;

  -- cost_center_id must be provided manually by the user on INSERT
  IF TG_OP = 'INSERT' AND NEW.cost_center_id IS NULL THEN
    RAISE EXCEPTION 'O centro de custo (cost_center_id) é obrigatório e deve ser informado manualmente';
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
