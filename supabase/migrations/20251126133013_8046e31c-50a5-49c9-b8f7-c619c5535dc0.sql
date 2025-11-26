-- Remover trigger e função antiga de validação de diárias pendentes
DROP TRIGGER IF EXISTS validar_diarias_pendentes_trigger ON public.diarias;
DROP FUNCTION IF EXISTS public.validar_diarias_pendentes();

-- Criar função para validar duplicidade de diária na mesma data
CREATE OR REPLACE FUNCTION public.validar_duplicidade_diaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_data_nova DATE;
  v_data_existente DATE;
BEGIN
  -- Buscar a data do posto_dia_vago da nova diária
  SELECT pdv.data INTO v_data_nova
  FROM public.posto_dias_vagos pdv
  WHERE pdv.id = NEW.posto_dia_vago_id;
  
  -- Verificar se já existe uma diária para o mesmo diarista na mesma data
  IF EXISTS (
    SELECT 1 
    FROM public.diarias d
    INNER JOIN public.posto_dias_vagos pdv ON d.posto_dia_vago_id = pdv.id
    WHERE d.diarista_id = NEW.diarista_id 
      AND pdv.data = v_data_nova
      AND d.id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
  ) THEN
    RAISE EXCEPTION 'O diarista já possui uma diária cadastrada para a data %', v_data_nova;
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Criar trigger para validar duplicidade de diária
CREATE TRIGGER validar_duplicidade_diaria_trigger
  BEFORE INSERT OR UPDATE ON public.diarias
  FOR EACH ROW
  EXECUTE FUNCTION public.validar_duplicidade_diaria();