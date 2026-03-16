
-- When a diaria_temporaria is updated to Reprovada or Cancelada, unlink it from faltas
CREATE OR REPLACE FUNCTION public.desvincular_falta_ao_reprovar_cancelar()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  IF NEW.status IN ('Reprovada', 'Cancelada')
     AND (OLD.status IS DISTINCT FROM NEW.status) THEN
    UPDATE public.faltas_colaboradores_convenia
    SET diaria_temporaria_id = NULL, updated_at = now()
    WHERE diaria_temporaria_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_desvincular_falta_ao_reprovar_cancelar ON public.diarias_temporarias;
CREATE TRIGGER trg_desvincular_falta_ao_reprovar_cancelar
  AFTER UPDATE ON public.diarias_temporarias
  FOR EACH ROW
  EXECUTE FUNCTION public.desvincular_falta_ao_reprovar_cancelar();
