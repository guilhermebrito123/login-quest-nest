-- Update trigger to remove dias_vagos when collaborator is assigned
CREATE OR REPLACE FUNCTION public.atribuir_dias_trabalho_colaborador()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Se o colaborador foi atribuído a um posto (INSERT ou UPDATE com novo posto)
  IF NEW.posto_servico_id IS NOT NULL AND (TG_OP = 'INSERT' OR OLD.posto_servico_id IS DISTINCT FROM NEW.posto_servico_id) THEN
    
    -- Remover dias_trabalho anteriores deste colaborador (se estiver mudando de posto)
    IF TG_OP = 'UPDATE' AND OLD.posto_servico_id IS NOT NULL THEN
      DELETE FROM public.dias_trabalho
      WHERE colaborador_id = NEW.id;
    END IF;
    
    -- Copiar dias_trabalho do posto para o colaborador
    INSERT INTO public.dias_trabalho (posto_servico_id, data, horario_inicio, horario_fim, intervalo_refeicao, colaborador_id)
    SELECT 
      posto_servico_id,
      data,
      horario_inicio,
      horario_fim,
      intervalo_refeicao,
      NEW.id
    FROM public.dias_trabalho
    WHERE posto_servico_id = NEW.posto_servico_id
      AND colaborador_id IS NULL  -- Apenas os dias genéricos do posto
      AND data >= CURRENT_DATE;   -- Apenas dias futuros e de hoje
    
    -- Remover dias vagos de posto_dias_vagos para este posto
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.posto_servico_id
      AND data >= CURRENT_DATE;
      
  -- Se o colaborador foi removido do posto
  ELSIF NEW.posto_servico_id IS NULL AND TG_OP = 'UPDATE' AND OLD.posto_servico_id IS NOT NULL THEN
    -- Remover dias_trabalho do colaborador
    DELETE FROM public.dias_trabalho
    WHERE colaborador_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$;