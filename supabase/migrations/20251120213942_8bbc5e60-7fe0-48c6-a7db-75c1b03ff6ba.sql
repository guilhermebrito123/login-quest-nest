-- Update trigger to set colaborador_id to NULL and status to vago when collaborator is unlinked
CREATE OR REPLACE FUNCTION public.desvincular_colaborador_posto()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
  
  -- Desvincular colaborador dos dias_trabalho (setar colaborador_id como NULL) e marcar como 'vago'
  UPDATE public.dias_trabalho
  SET colaborador_id = NULL,
      status = 'vago'::status_posto
  WHERE colaborador_id = OLD.id
    AND posto_servico_id = v_posto_id
    AND data >= CURRENT_DATE;
  
  -- Inserir dias vagos em posto_dias_vagos com motivo "Posto vago"
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
  ON CONFLICT ON CONSTRAINT posto_dias_vagos_unique_constraint DO NOTHING;
  
  -- Retornar registro apropriado
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$;