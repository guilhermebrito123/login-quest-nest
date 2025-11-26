-- Atualizar função para validar duplicidade por data
CREATE OR REPLACE FUNCTION public.validar_duplicidade_diaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_data_posto DATE;
BEGIN
  -- Buscar a data do posto_dia_vago_id que está sendo inserido
  SELECT data INTO v_data_posto
  FROM public.posto_dias_vagos
  WHERE id = NEW.posto_dia_vago_id;
  
  -- Verificar se já existe uma diária para o mesmo diarista na mesma data
  IF EXISTS (
    SELECT 1 
    FROM public.diarias d
    JOIN public.posto_dias_vagos pdv ON d.posto_dia_vago_id = pdv.id
    WHERE d.diarista_id = NEW.diarista_id 
      AND pdv.data = v_data_posto
      AND d.id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
  ) THEN
    RAISE EXCEPTION 'O diarista já possui uma diária cadastrada para esta data. Um diarista não pode estar em dois lugares ao mesmo tempo.';
  END IF;
  
  RETURN NEW;
END;
$function$;