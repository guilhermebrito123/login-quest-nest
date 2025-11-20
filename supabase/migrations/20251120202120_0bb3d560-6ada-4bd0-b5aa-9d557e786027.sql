-- Drop existing trigger
DROP TRIGGER IF EXISTS sync_dias_vagos_trigger ON public.dias_trabalho;

-- Recreate sync_dias_vagos function with ON CONFLICT DO NOTHING
CREATE OR REPLACE FUNCTION public.sync_dias_vagos()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.status = 'vago'::status_posto AND (OLD IS NULL OR OLD.status != 'vago'::status_posto) THEN
    INSERT INTO public.posto_dias_vagos (
      posto_servico_id,
      colaborador_id,
      data,
      motivo,
      created_by
    ) VALUES (
      NEW.posto_servico_id,
      NEW.colaborador_id,
      NEW.data,
      COALESCE(
        (SELECT 'Posto vago' FROM public.postos_servico WHERE id = NEW.posto_servico_id AND status = 'vago'::status_posto),
        'Dia vago'
      ),
      COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
    )
    ON CONFLICT ON CONSTRAINT posto_dias_vagos_unique_constraint DO NOTHING;
  
  ELSIF NEW.status = 'ocupado'::status_posto AND OLD.status = 'vago'::status_posto THEN
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.posto_servico_id
      AND data = NEW.data
      AND COALESCE(colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid) = 
          COALESCE(NEW.colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid);
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Recreate trigger
CREATE TRIGGER sync_dias_vagos_trigger
  AFTER INSERT OR UPDATE ON public.dias_trabalho
  FOR EACH ROW EXECUTE FUNCTION public.sync_dias_vagos();