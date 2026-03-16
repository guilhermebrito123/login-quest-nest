
CREATE OR REPLACE FUNCTION public.autolink_falta_apos_diaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_linked boolean;
BEGIN
  IF NEW.motivo_vago IN ('DIÁRIA - FALTA', 'DIÁRIA - FALTA ATESTADO')
     AND NEW.colaborador_ausente_convenia IS NOT NULL THEN

    UPDATE public.faltas_colaboradores_convenia
    SET diaria_temporaria_id = NEW.id,
        updated_at = now()
    WHERE colaborador_convenia_id = NEW.colaborador_ausente_convenia
      AND data_falta = NEW.data_diaria
      AND diaria_temporaria_id IS NULL;

    IF FOUND THEN
      PERFORM set_config('app.falta_already_linked', 'true', true);
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;
