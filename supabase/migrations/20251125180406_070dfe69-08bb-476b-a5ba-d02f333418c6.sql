-- Corrigir função desvincular_colaborador_posto para converter motivo_vago em NULL
-- quando o dia já estava vago antes da exclusão do colaborador
CREATE OR REPLACE FUNCTION public.desvincular_colaborador_posto()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_posto_id UUID;
BEGIN
  -- Determinar o posto_servico_id que está sendo desvinculado
  IF TG_OP = 'DELETE' THEN
    v_posto_id := OLD.posto_servico_id;
  ELSIF TG_OP = 'UPDATE' AND OLD.posto_servico_id IS NOT NULL AND NEW.posto_servico_id IS NULL THEN
    v_posto_id := OLD.posto_servico_id;
  ELSE
    RETURN NEW;
  END IF;
  
  -- Se não há posto para desvincular, retornar
  IF v_posto_id IS NULL THEN
    IF TG_OP = 'DELETE' THEN
      RETURN OLD;
    ELSE
      RETURN NEW;
    END IF;
  END IF;
  
  -- Deletar apenas os posto_dias_vagos específicos do colaborador
  DELETE FROM public.posto_dias_vagos
  WHERE posto_servico_id = v_posto_id
    AND colaborador_id = OLD.id
    AND data >= CURRENT_DATE;
  
  -- Deletar todas as presenças futuras do colaborador neste posto
  DELETE FROM public.presencas
  WHERE colaborador_id = OLD.id
    AND posto_servico_id = v_posto_id
    AND data >= CURRENT_DATE;
  
  -- ATUALIZAÇÃO CRÍTICA: Atualizar dias_trabalho futuros
  -- Se o dia já estava vago, converter motivo_vago para NULL
  -- Se o dia estava com outro status, usar 'Posto vago'
  UPDATE public.dias_trabalho
  SET colaborador_id = NULL,
      status = 'vago'::status_posto,
      motivo_vago = CASE 
        WHEN status = 'vago'::status_posto THEN NULL
        ELSE 'Posto vago'::motivo_vago_type
      END,
      updated_at = now()
  WHERE colaborador_id = OLD.id
    AND posto_servico_id = v_posto_id
    AND data >= CURRENT_DATE;
  
  -- Inserir novos dias vagos genéricos para os dias liberados
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
    'Posto vago',
    COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
  FROM public.dias_trabalho
  WHERE posto_servico_id = v_posto_id
    AND colaborador_id IS NULL
    AND data >= CURRENT_DATE
    AND status = 'vago'::status_posto
  ON CONFLICT (posto_servico_id, data) 
  WHERE colaborador_id IS NULL
  DO UPDATE SET
    motivo = 'Posto vago',
    created_by = COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid);
  
  -- Retornar registro apropriado
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$function$;