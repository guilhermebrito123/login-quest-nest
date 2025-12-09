-- Corrigir uso do enum motivo_vago_type para o valor atual

-- Ajustar dados legados que ainda possam ter "Posto vago"
UPDATE public.dias_trabalho
SET motivo_vago = 'VAGA EM ABERTO (COBERTURA SALÁRIO)'::motivo_vago_type
WHERE motivo_vago::text = 'Posto vago';

UPDATE public.posto_dias_vagos
SET motivo = 'VAGA EM ABERTO (COBERTURA SALÁRIO)'
WHERE motivo = 'Posto vago';

-- Recriar função usada na desvinculação de colaborador, ajustando o valor do enum
CREATE OR REPLACE FUNCTION public.desvincular_colaborador_posto()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_posto_id UUID;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_posto_id := OLD.posto_servico_id;
  ELSIF TG_OP = 'UPDATE' AND OLD.posto_servico_id IS NOT NULL AND NEW.posto_servico_id IS NULL THEN
    v_posto_id := OLD.posto_servico_id;
  ELSE
    RETURN NEW;
  END IF;
  
  IF v_posto_id IS NULL THEN
    IF TG_OP = 'DELETE' THEN
      RETURN OLD;
    ELSE
      RETURN NEW;
    END IF;
  END IF;
  
  DELETE FROM public.posto_dias_vagos
  WHERE posto_servico_id = v_posto_id
    AND colaborador_id = OLD.id
    AND data >= CURRENT_DATE;
  
  DELETE FROM public.presencas
  WHERE colaborador_id = OLD.id
    AND posto_servico_id = v_posto_id
    AND data >= CURRENT_DATE;
  
  UPDATE public.dias_trabalho
  SET colaborador_id = NULL,
      status = 'vago'::status_posto,
      motivo_vago = 'VAGA EM ABERTO (COBERTURA SALÁRIO)'::motivo_vago_type,
      updated_at = now()
  WHERE colaborador_id = OLD.id
    AND posto_servico_id = v_posto_id
    AND data >= CURRENT_DATE;
  
  INSERT INTO public.posto_dias_vagos (
    posto_servico_id,
    colaborador_id,
    data,
    motivo,
    created_by
  )
  SELECT 
    v_posto_id,
    NULL,
    data,
    'VAGA EM ABERTO (COBERTURA SALÁRIO)',
    COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
  FROM public.dias_trabalho
  WHERE posto_servico_id = v_posto_id
    AND colaborador_id IS NULL
    AND data >= CURRENT_DATE
    AND status = 'vago'::status_posto
  ON CONFLICT (posto_servico_id, data) 
  WHERE colaborador_id IS NULL
  DO UPDATE SET
    motivo = 'VAGA EM ABERTO (COBERTURA SALÁRIO)',
    created_by = COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid);
  
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$function$;