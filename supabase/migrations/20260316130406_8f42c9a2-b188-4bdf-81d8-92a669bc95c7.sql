CREATE OR REPLACE FUNCTION public.sync_falta_colaborador_convenia()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_rpc_call text;
BEGIN
  v_rpc_call := current_setting('app.rpc_call', true);

  IF v_rpc_call IN ('justificar_falta', 'reverter_justificativa', 'true') THEN
    RETURN NEW;
  END IF;

  IF NEW.motivo_vago = 'DIÁRIA - FALTA'
     AND NEW.colaborador_ausente_convenia IS NOT NULL THEN

    UPDATE public.faltas_colaboradores_convenia
    SET
      colaborador_convenia_id = NEW.colaborador_ausente_convenia,
      data_falta = NEW.data_diaria,
      updated_at = now()
    WHERE diaria_temporaria_id = NEW.id;

    IF NOT FOUND THEN
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
        updated_at = now();
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;