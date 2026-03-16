
CREATE OR REPLACE FUNCTION public.cascade_delete_diaria_on_falta_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.diaria_temporaria_id IS NOT NULL THEN
    PERFORM set_config('app.rpc_call', 'cascade_falta_delete', true);
    DELETE FROM public.diarias_temporarias WHERE id = OLD.diaria_temporaria_id;
    PERFORM set_config('app.rpc_call', '', true);
  END IF;
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_cascade_delete_diaria_on_falta_delete ON public.faltas_colaboradores_convenia;

CREATE TRIGGER trg_cascade_delete_diaria_on_falta_delete
  BEFORE DELETE ON public.faltas_colaboradores_convenia
  FOR EACH ROW
  EXECUTE FUNCTION public.cascade_delete_diaria_on_falta_delete();
