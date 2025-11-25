-- Garantir que ao deletar colaborador, TODOS os dias futuros sejam restabelecidos como "Posto vago"
-- incluindo dias que já tinham outro motivo_vago

-- Recriar a função para forçar atualização de todos os dias
CREATE OR REPLACE FUNCTION public.desvincular_colaborador_posto()
RETURNS TRIGGER
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
  
  -- CRÍTICO: Atualizar TODOS os dias futuros deste colaborador neste posto
  -- Forçar status='vago' e motivo_vago='Posto vago' independentemente dos valores anteriores
  UPDATE public.dias_trabalho
  SET colaborador_id = NULL,
      status = 'vago'::status_posto,
      motivo_vago = 'Posto vago'::motivo_vago_type,
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