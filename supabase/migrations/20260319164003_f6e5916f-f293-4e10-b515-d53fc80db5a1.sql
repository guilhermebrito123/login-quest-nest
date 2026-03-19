
CREATE OR REPLACE FUNCTION public.trg_diaristas_nome_upper()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = public
AS $function$
BEGIN
  new.nome_completo := UPPER(new.nome_completo);
  RETURN new;
END;
$function$;

DROP TRIGGER IF EXISTS trg_diaristas_nome_upper ON public.diaristas;

CREATE TRIGGER trg_diaristas_nome_upper
  BEFORE INSERT OR UPDATE ON public.diaristas
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_diaristas_nome_upper();
