
CREATE OR REPLACE FUNCTION public.validar_falta_justificada_diaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_motivo_falta text;
BEGIN
  -- Only validate for motivos related to faltas
  IF NEW.motivo_vago NOT IN ('DIÁRIA - FALTA', 'DIÁRIA - FALTA ATESTADO') THEN
    -- Check if there's an existing falta for this colaborador+date that would require a falta-related motivo
    IF NEW.colaborador_ausente_convenia IS NOT NULL THEN
      SELECT f.motivo INTO v_motivo_falta
      FROM public.faltas_colaboradores_convenia f
      WHERE f.colaborador_convenia_id = NEW.colaborador_ausente_convenia
        AND f.data_falta = NEW.data_diaria
        AND f.diaria_temporaria_id IS NULL
      LIMIT 1;

      IF v_motivo_falta = 'FALTA JUSTIFICADA' THEN
        RAISE EXCEPTION 'O colaborador possui uma falta JUSTIFICADA nesta data (%). O motivo da diária deve ser DIÁRIA - FALTA ATESTADO.', NEW.data_diaria;
      ELSIF v_motivo_falta = 'FALTA INJUSTIFICADA' THEN
        RAISE EXCEPTION 'O colaborador possui uma falta INJUSTIFICADA nesta data (%). O motivo da diária deve ser DIÁRIA - FALTA.', NEW.data_diaria;
      END IF;
    END IF;

    RETURN NEW;
  END IF;

  -- Validate DIÁRIA - FALTA ATESTADO requires FALTA JUSTIFICADA
  IF NEW.motivo_vago = 'DIÁRIA - FALTA ATESTADO' THEN
    IF NEW.colaborador_ausente_convenia IS NULL THEN
      RAISE EXCEPTION 'Para criar uma diária com motivo DIÁRIA - FALTA ATESTADO é necessário informar o colaborador ausente (Convênia).';
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM public.faltas_colaboradores_convenia f
      WHERE f.colaborador_convenia_id = NEW.colaborador_ausente_convenia
        AND f.data_falta = NEW.data_diaria
        AND f.diaria_temporaria_id IS NULL
        AND f.motivo = 'FALTA JUSTIFICADA'
    ) THEN
      -- Check if there's an unjustified falta
      IF EXISTS (
        SELECT 1
        FROM public.faltas_colaboradores_convenia f
        WHERE f.colaborador_convenia_id = NEW.colaborador_ausente_convenia
          AND f.data_falta = NEW.data_diaria
          AND f.diaria_temporaria_id IS NULL
          AND f.motivo = 'FALTA INJUSTIFICADA'
      ) THEN
        RAISE EXCEPTION 'O colaborador possui uma falta NÃO JUSTIFICADA nesta data (%). O motivo da diária deve ser DIÁRIA - FALTA, não DIÁRIA - FALTA ATESTADO.', NEW.data_diaria;
      ELSE
        RAISE EXCEPTION 'Não existe registro de falta justificada para este colaborador na data %. Não é possível criar diária com motivo DIÁRIA - FALTA ATESTADO.', NEW.data_diaria;
      END IF;
    END IF;
  END IF;

  -- Validate DIÁRIA - FALTA: if there's a justified falta, must use DIÁRIA - FALTA ATESTADO
  IF NEW.motivo_vago = 'DIÁRIA - FALTA' THEN
    IF NEW.colaborador_ausente_convenia IS NOT NULL THEN
      IF EXISTS (
        SELECT 1
        FROM public.faltas_colaboradores_convenia f
        WHERE f.colaborador_convenia_id = NEW.colaborador_ausente_convenia
          AND f.data_falta = NEW.data_diaria
          AND f.diaria_temporaria_id IS NULL
          AND f.motivo = 'FALTA JUSTIFICADA'
      ) THEN
        RAISE EXCEPTION 'O colaborador possui uma falta JUSTIFICADA nesta data (%). O motivo da diária deve ser DIÁRIA - FALTA ATESTADO, não DIÁRIA - FALTA.', NEW.data_diaria;
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

-- Ensure trigger exists on INSERT
DROP TRIGGER IF EXISTS trg_validar_falta_justificada_diaria ON public.diarias_temporarias;
CREATE TRIGGER trg_validar_falta_justificada_diaria
  BEFORE INSERT ON public.diarias_temporarias
  FOR EACH ROW
  EXECUTE FUNCTION public.validar_falta_justificada_diaria();
