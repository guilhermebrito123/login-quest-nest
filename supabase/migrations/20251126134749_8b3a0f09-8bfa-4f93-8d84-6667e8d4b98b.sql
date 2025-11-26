-- Atualizar função para validar apenas duplicidade por posto_dia_vago_id
CREATE OR REPLACE FUNCTION public.validar_duplicidade_diaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  -- Verificar se já existe uma diária para o mesmo diarista com o mesmo posto_dia_vago_id
  IF EXISTS (
    SELECT 1 
    FROM public.diarias d
    WHERE d.diarista_id = NEW.diarista_id 
      AND d.posto_dia_vago_id = NEW.posto_dia_vago_id
      AND d.id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
  ) THEN
    RAISE EXCEPTION 'O diarista já possui uma diária cadastrada para este posto/dia específico';
  END IF;
  
  RETURN NEW;
END;
$function$;