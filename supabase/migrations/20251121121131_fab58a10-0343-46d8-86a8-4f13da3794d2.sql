-- Corrigir trigger para atualizar motivo_vago nos dias_trabalho ao desvincular colaborador
CREATE OR REPLACE FUNCTION public.atribuir_dias_trabalho_colaborador()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- Se o colaborador foi atribuído a um posto (INSERT ou UPDATE com novo posto)
  IF NEW.posto_servico_id IS NOT NULL AND (TG_OP = 'INSERT' OR OLD.posto_servico_id IS DISTINCT FROM NEW.posto_servico_id) THEN
    
    -- Remover dias_trabalho anteriores deste colaborador (se estiver mudando de posto)
    IF TG_OP = 'UPDATE' AND OLD.posto_servico_id IS NOT NULL THEN
      -- Deletar dias do posto antigo do colaborador
      DELETE FROM public.dias_trabalho
      WHERE colaborador_id = NEW.id
        AND posto_servico_id = OLD.posto_servico_id
        AND data >= CURRENT_DATE;
      
      -- Atualizar motivo_vago dos dias genéricos do posto antigo
      UPDATE public.dias_trabalho
      SET motivo_vago = 'Posto vago'::motivo_vago_type,
          status = 'vago'::status_posto
      WHERE posto_servico_id = OLD.posto_servico_id
        AND colaborador_id IS NULL
        AND data >= CURRENT_DATE;
      
      -- Inserir dias vagos do posto antigo em posto_dias_vagos
      INSERT INTO public.posto_dias_vagos (
        posto_servico_id,
        colaborador_id,
        data,
        motivo,
        created_by
      )
      SELECT 
        OLD.posto_servico_id,
        NULL,
        data,
        'Posto vago',
        COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
      FROM public.dias_trabalho
      WHERE posto_servico_id = OLD.posto_servico_id
        AND colaborador_id IS NULL
        AND data >= CURRENT_DATE
      ON CONFLICT ON CONSTRAINT posto_dias_vagos_unique_constraint
      DO NOTHING;
    END IF;
    
    -- Atualizar dias_trabalho do novo posto para ocupado e vincular ao colaborador
    UPDATE public.dias_trabalho
    SET colaborador_id = NEW.id,
        status = 'ocupado'::status_posto,
        motivo_vago = NULL
    WHERE posto_servico_id = NEW.posto_servico_id
      AND data >= CURRENT_DATE
      AND colaborador_id IS NULL;
    
    -- Remover dias do novo posto de posto_dias_vagos
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.posto_servico_id
      AND data >= CURRENT_DATE;
      
  -- Se o colaborador foi removido do posto
  ELSIF NEW.posto_servico_id IS NULL AND TG_OP = 'UPDATE' AND OLD.posto_servico_id IS NOT NULL THEN
    -- Deletar dias_trabalho do colaborador
    DELETE FROM public.dias_trabalho
    WHERE colaborador_id = NEW.id
      AND posto_servico_id = OLD.posto_servico_id
      AND data >= CURRENT_DATE;
    
    -- Atualizar motivo_vago dos dias genéricos do posto
    UPDATE public.dias_trabalho
    SET motivo_vago = 'Posto vago'::motivo_vago_type,
        status = 'vago'::status_posto
    WHERE posto_servico_id = OLD.posto_servico_id
      AND colaborador_id IS NULL
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
      OLD.posto_servico_id,
      NULL,
      data,
      'Posto vago',
      COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
    FROM public.dias_trabalho
    WHERE posto_servico_id = OLD.posto_servico_id
      AND colaborador_id IS NULL
      AND data >= CURRENT_DATE
    ON CONFLICT ON CONSTRAINT posto_dias_vagos_unique_constraint
    DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$function$;