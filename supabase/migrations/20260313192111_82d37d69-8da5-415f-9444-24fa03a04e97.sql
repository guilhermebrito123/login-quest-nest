
CREATE OR REPLACE FUNCTION public.vincular_ou_bloquear_diaria_por_falta()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_falta_id bigint;
  v_falta_diaria_id bigint;
BEGIN
  IF NEW.motivo_vago = 'DIÁRIA - FALTA'
     AND NEW.colaborador_ausente_convenia IS NOT NULL THEN

    SELECT id, diaria_temporaria_id
    INTO v_falta_id, v_falta_diaria_id
    FROM public.faltas_colaboradores_convenia
    WHERE colaborador_convenia_id = NEW.colaborador_ausente_convenia
      AND data_falta = NEW.data_diaria
    LIMIT 1;

    IF v_falta_id IS NOT NULL AND v_falta_diaria_id IS NOT NULL THEN
      RAISE EXCEPTION 'Já existe uma falta registrada para este colaborador nesta data (%) com diária vinculada (ID %). Não é possível criar outra diária.',
        NEW.data_diaria, v_falta_diaria_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_vincular_ou_bloquear_diaria_por_falta ON public.diarias_temporarias;

CREATE TRIGGER trg_vincular_ou_bloquear_diaria_por_falta
BEFORE INSERT ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.vincular_ou_bloquear_diaria_por_falta();

-- AFTER INSERT: auto-link unlinked falta to the newly created diaria (skip creating new falta)
CREATE OR REPLACE FUNCTION public.autolink_falta_apos_diaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_linked boolean;
BEGIN
  IF NEW.motivo_vago = 'DIÁRIA - FALTA'
     AND NEW.colaborador_ausente_convenia IS NOT NULL THEN

    UPDATE public.faltas_colaboradores_convenia
    SET diaria_temporaria_id = NEW.id,
        updated_at = now()
    WHERE colaborador_convenia_id = NEW.colaborador_ausente_convenia
      AND data_falta = NEW.data_diaria
      AND diaria_temporaria_id IS NULL;

    -- If we linked an existing falta, prevent criar_falta_colaborador_convenia from creating a new one
    IF FOUND THEN
      -- Set a flag so the other AFTER INSERT trigger skips
      PERFORM set_config('app.falta_already_linked', 'true', true);
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_autolink_falta_apos_diaria ON public.diarias_temporarias;

-- Name starts with 'a' to fire BEFORE the criar_falta trigger alphabetically
CREATE TRIGGER trg_a_autolink_falta_apos_diaria
AFTER INSERT ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.autolink_falta_apos_diaria();

-- Update criar_falta to check the flag
CREATE OR REPLACE FUNCTION public.criar_falta_colaborador_convenia()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Skip if autolink already handled it
  IF current_setting('app.falta_already_linked', true) = 'true' THEN
    PERFORM set_config('app.falta_already_linked', '', true);
    RETURN NEW;
  END IF;

  IF NEW.motivo_vago = 'DIÁRIA - FALTA'
     AND NEW.colaborador_ausente_convenia IS NOT NULL THEN
    INSERT INTO public.faltas_colaboradores_convenia (
      colaborador_convenia_id,
      diaria_temporaria_id,
      data_falta,
      motivo
    ) VALUES (
      NEW.colaborador_ausente_convenia,
      NEW.id,
      NEW.data_diaria,
      'FALTA INJUSTIFICADA'
    )
    ON CONFLICT (diaria_temporaria_id)
    WHERE diaria_temporaria_id IS NOT NULL
    DO UPDATE SET
      colaborador_convenia_id = EXCLUDED.colaborador_convenia_id,
      data_falta = EXCLUDED.data_falta,
      updated_at = now()
    WHERE public.faltas_colaboradores_convenia.motivo = 'FALTA INJUSTIFICADA';
  END IF;

  RETURN NEW;
END;
$$;
