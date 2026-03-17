
-- 1) Update autolink_falta_apos_diaria to skip faltas with active horas_extras
CREATE OR REPLACE FUNCTION public.autolink_falta_apos_diaria()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.motivo_vago IN ('DIÁRIA - FALTA', 'DIÁRIA - FALTA ATESTADO')
     AND NEW.colaborador_ausente_convenia IS NOT NULL THEN

    UPDATE public.faltas_colaboradores_convenia
    SET diaria_temporaria_id = NEW.id,
        updated_at = now()
    WHERE colaborador_convenia_id = NEW.colaborador_ausente_convenia
      AND data_falta = NEW.data_diaria
      AND (diaria_temporaria_id IS NULL
           OR EXISTS (
             SELECT 1 FROM public.diarias_temporarias dt
             WHERE dt.id = diaria_temporaria_id
               AND dt.status IN ('Reprovada', 'Cancelada')
           ))
      -- Block if falta already has active hora_extra
      AND NOT EXISTS (
        SELECT 1 FROM public.horas_extras he
        WHERE he.falta_id = faltas_colaboradores_convenia.id
          AND he.status IN ('pendente', 'confirmada', 'aprovada')
      );

    IF FOUND THEN
      PERFORM set_config('app.falta_already_linked', 'true', true);
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- 2) Update vincular_ou_bloquear_diaria_por_falta to block when falta has active hora_extra
CREATE OR REPLACE FUNCTION public.vincular_ou_bloquear_diaria_por_falta()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_falta_id bigint;
  v_falta_diaria_id bigint;
  v_diaria_status text;
  v_has_active_he boolean;
BEGIN
  IF NEW.motivo_vago IN ('DIÁRIA - FALTA', 'DIÁRIA - FALTA ATESTADO')
     AND NEW.colaborador_ausente_convenia IS NOT NULL THEN

    SELECT f.id, f.diaria_temporaria_id
    INTO v_falta_id, v_falta_diaria_id
    FROM public.faltas_colaboradores_convenia f
    WHERE f.colaborador_convenia_id = NEW.colaborador_ausente_convenia
      AND f.data_falta = NEW.data_diaria
    LIMIT 1;

    IF v_falta_id IS NOT NULL THEN
      -- Check if falta has active hora_extra
      SELECT EXISTS (
        SELECT 1 FROM public.horas_extras he
        WHERE he.falta_id = v_falta_id
          AND he.status IN ('pendente', 'confirmada', 'aprovada')
      ) INTO v_has_active_he;

      IF v_has_active_he THEN
        RAISE EXCEPTION 'Esta falta já possui uma hora extra ativa vinculada (falta ID %). Não é possível criar diária temporária.', v_falta_id;
      END IF;

      IF v_falta_diaria_id IS NOT NULL THEN
        SELECT dt.status::text INTO v_diaria_status
        FROM public.diarias_temporarias dt
        WHERE dt.id = v_falta_diaria_id;

        IF v_diaria_status IN ('Reprovada', 'Cancelada') THEN
          UPDATE public.faltas_colaboradores_convenia
          SET diaria_temporaria_id = NULL, updated_at = now()
          WHERE id = v_falta_id;
        ELSE
          RAISE EXCEPTION 'Já existe uma falta registrada para este colaborador nesta data (%) com diária vinculada (ID %). Não é possível criar outra diária.',
            NEW.data_diaria, v_falta_diaria_id;
        END IF;
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- 3) Add a trigger on faltas_colaboradores_convenia to prevent linking diaria_temporaria_id
--    when falta has active hora_extra
CREATE OR REPLACE FUNCTION public.bloquear_vinculo_diaria_se_hora_extra_ativa()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Only check when diaria_temporaria_id is being set (null -> value)
  IF NEW.diaria_temporaria_id IS NOT NULL
     AND (OLD.diaria_temporaria_id IS NULL OR OLD.diaria_temporaria_id IS DISTINCT FROM NEW.diaria_temporaria_id) THEN
    IF EXISTS (
      SELECT 1 FROM public.horas_extras he
      WHERE he.falta_id = NEW.id
        AND he.status IN ('pendente', 'confirmada', 'aprovada')
    ) THEN
      RAISE EXCEPTION 'Não é possível vincular diária temporária: esta falta (ID %) já possui hora extra ativa.', NEW.id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_bloquear_vinculo_diaria_se_hora_extra
  BEFORE UPDATE ON public.faltas_colaboradores_convenia
  FOR EACH ROW
  EXECUTE FUNCTION public.bloquear_vinculo_diaria_se_hora_extra_ativa();
