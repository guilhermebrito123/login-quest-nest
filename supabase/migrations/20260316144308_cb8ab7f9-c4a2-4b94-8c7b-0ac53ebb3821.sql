
-- Update validar_falta_justificada_diaria to allow DIÁRIA - FALTA ATESTADO
-- when there's an existing unlinked falta with motivo 'FALTA JUSTIFICADA'
CREATE OR REPLACE FUNCTION public.validar_falta_justificada_diaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_bypass text;
  v_falta_exists boolean;
BEGIN
  v_bypass := current_setting('app.rpc_call', true);

  IF TG_OP = 'INSERT' AND NEW.motivo_vago = 'DIÁRIA - FALTA ATESTADO' THEN
    -- Allow if bypass is set (RPC justification flow)
    IF v_bypass IN ('justificar_falta', 'true') THEN
      RETURN NEW;
    END IF;

    -- Allow if there's an existing unlinked falta with FALTA JUSTIFICADA
    -- for the same collaborator and date
    IF NEW.colaborador_ausente_convenia IS NOT NULL THEN
      SELECT EXISTS (
        SELECT 1
        FROM public.faltas_colaboradores_convenia
        WHERE colaborador_convenia_id = NEW.colaborador_ausente_convenia
          AND data_falta = NEW.data_diaria
          AND diaria_temporaria_id IS NULL
          AND motivo = 'FALTA JUSTIFICADA'
      ) INTO v_falta_exists;

      IF v_falta_exists THEN
        RETURN NEW;
      END IF;
    END IF;

    RAISE EXCEPTION 'Não é permitido criar diária como DIÁRIA - FALTA ATESTADO sem uma falta justificada (FALTA JUSTIFICADA) já registrada e sem diária vinculada para o mesmo colaborador e data.';
  END IF;

  IF TG_OP = 'UPDATE' 
     AND OLD.motivo_vago = 'DIÁRIA - FALTA'
     AND NEW.motivo_vago = 'DIÁRIA - FALTA ATESTADO' THEN
    IF v_bypass IN ('justificar_falta', 'true') THEN
      RETURN NEW;
    END IF;
    RAISE EXCEPTION 'Não é permitido alterar para DIÁRIA - FALTA ATESTADO diretamente. Use a função justificar_falta_convenia com atestado.';
  END IF;

  RETURN NEW;
END;
$function$;

-- Update vincular_ou_bloquear_diaria_por_falta to also handle DIÁRIA - FALTA ATESTADO
CREATE OR REPLACE FUNCTION public.vincular_ou_bloquear_diaria_por_falta()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_falta_id bigint;
  v_falta_diaria_id bigint;
BEGIN
  IF NEW.motivo_vago IN ('DIÁRIA - FALTA', 'DIÁRIA - FALTA ATESTADO')
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
$function$;
