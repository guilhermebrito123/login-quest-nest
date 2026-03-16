
-- 1) vincular_ou_bloquear: only block if linked diaria is NOT Reprovada/Cancelada
CREATE OR REPLACE FUNCTION public.vincular_ou_bloquear_diaria_por_falta()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_falta_id bigint;
  v_falta_diaria_id bigint;
  v_diaria_status text;
BEGIN
  IF NEW.motivo_vago IN ('DIÁRIA - FALTA', 'DIÁRIA - FALTA ATESTADO')
     AND NEW.colaborador_ausente_convenia IS NOT NULL THEN

    SELECT f.id, f.diaria_temporaria_id
    INTO v_falta_id, v_falta_diaria_id
    FROM public.faltas_colaboradores_convenia f
    WHERE f.colaborador_convenia_id = NEW.colaborador_ausente_convenia
      AND f.data_falta = NEW.data_diaria
    LIMIT 1;

    IF v_falta_id IS NOT NULL AND v_falta_diaria_id IS NOT NULL THEN
      -- Check the status of the linked diaria
      SELECT dt.status::text INTO v_diaria_status
      FROM public.diarias_temporarias dt
      WHERE dt.id = v_falta_diaria_id;

      IF v_diaria_status IN ('Reprovada', 'Cancelada') THEN
        -- Unlink the old falta so the new diaria can be linked
        UPDATE public.faltas_colaboradores_convenia
        SET diaria_temporaria_id = NULL, updated_at = now()
        WHERE id = v_falta_id;
      ELSE
        RAISE EXCEPTION 'Já existe uma falta registrada para este colaborador nesta data (%) com diária vinculada (ID %). Não é possível criar outra diária.',
          NEW.data_diaria, v_falta_diaria_id;
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

-- 2) validar_falta_justificada_diaria: treat faltas linked to Reprovada/Cancelada as unlinked
CREATE OR REPLACE FUNCTION public.validar_falta_justificada_diaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_motivo_falta text;
BEGIN
  IF NEW.motivo_vago NOT IN ('DIÁRIA - FALTA', 'DIÁRIA - FALTA ATESTADO') THEN
    IF NEW.colaborador_ausente_convenia IS NOT NULL THEN
      SELECT f.motivo INTO v_motivo_falta
      FROM public.faltas_colaboradores_convenia f
      WHERE f.colaborador_convenia_id = NEW.colaborador_ausente_convenia
        AND f.data_falta = NEW.data_diaria
        AND (f.diaria_temporaria_id IS NULL
             OR EXISTS (
               SELECT 1 FROM public.diarias_temporarias dt
               WHERE dt.id = f.diaria_temporaria_id
                 AND dt.status IN ('Reprovada', 'Cancelada')
             ))
      LIMIT 1;

      IF v_motivo_falta = 'FALTA JUSTIFICADA' THEN
        RAISE EXCEPTION 'O colaborador possui uma falta JUSTIFICADA nesta data (%). O motivo da diária deve ser DIÁRIA - FALTA ATESTADO.', NEW.data_diaria;
      ELSIF v_motivo_falta = 'FALTA INJUSTIFICADA' THEN
        RAISE EXCEPTION 'O colaborador possui uma falta INJUSTIFICADA nesta data (%). O motivo da diária deve ser DIÁRIA - FALTA.', NEW.data_diaria;
      END IF;
    END IF;
    RETURN NEW;
  END IF;

  IF NEW.motivo_vago = 'DIÁRIA - FALTA ATESTADO' THEN
    IF NEW.colaborador_ausente_convenia IS NULL THEN
      RAISE EXCEPTION 'Para criar uma diária com motivo DIÁRIA - FALTA ATESTADO é necessário informar o colaborador ausente (Convênia).';
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM public.faltas_colaboradores_convenia f
      WHERE f.colaborador_convenia_id = NEW.colaborador_ausente_convenia
        AND f.data_falta = NEW.data_diaria
        AND f.motivo = 'FALTA JUSTIFICADA'
        AND (f.diaria_temporaria_id IS NULL
             OR EXISTS (
               SELECT 1 FROM public.diarias_temporarias dt
               WHERE dt.id = f.diaria_temporaria_id
                 AND dt.status IN ('Reprovada', 'Cancelada')
             ))
    ) THEN
      IF EXISTS (
        SELECT 1
        FROM public.faltas_colaboradores_convenia f
        WHERE f.colaborador_convenia_id = NEW.colaborador_ausente_convenia
          AND f.data_falta = NEW.data_diaria
          AND f.motivo = 'FALTA INJUSTIFICADA'
          AND (f.diaria_temporaria_id IS NULL
               OR EXISTS (
                 SELECT 1 FROM public.diarias_temporarias dt
                 WHERE dt.id = f.diaria_temporaria_id
                   AND dt.status IN ('Reprovada', 'Cancelada')
               ))
      ) THEN
        RAISE EXCEPTION 'O colaborador possui uma falta NÃO JUSTIFICADA nesta data (%). O motivo da diária deve ser DIÁRIA - FALTA, não DIÁRIA - FALTA ATESTADO.', NEW.data_diaria;
      ELSE
        RAISE EXCEPTION 'Não existe registro de falta justificada para este colaborador na data %. Não é possível criar diária com motivo DIÁRIA - FALTA ATESTADO.', NEW.data_diaria;
      END IF;
    END IF;
  END IF;

  IF NEW.motivo_vago = 'DIÁRIA - FALTA' THEN
    IF NEW.colaborador_ausente_convenia IS NOT NULL THEN
      IF EXISTS (
        SELECT 1
        FROM public.faltas_colaboradores_convenia f
        WHERE f.colaborador_convenia_id = NEW.colaborador_ausente_convenia
          AND f.data_falta = NEW.data_diaria
          AND f.motivo = 'FALTA JUSTIFICADA'
          AND (f.diaria_temporaria_id IS NULL
               OR EXISTS (
                 SELECT 1 FROM public.diarias_temporarias dt
                 WHERE dt.id = f.diaria_temporaria_id
                   AND dt.status IN ('Reprovada', 'Cancelada')
               ))
      ) THEN
        RAISE EXCEPTION 'O colaborador possui uma falta JUSTIFICADA nesta data (%). O motivo da diária deve ser DIÁRIA - FALTA ATESTADO, não DIÁRIA - FALTA.', NEW.data_diaria;
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

-- 3) autolink_falta_apos_diaria: also relink faltas from Reprovada/Cancelada diarias
CREATE OR REPLACE FUNCTION public.autolink_falta_apos_diaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
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
           ));

    IF FOUND THEN
      PERFORM set_config('app.falta_already_linked', 'true', true);
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;
