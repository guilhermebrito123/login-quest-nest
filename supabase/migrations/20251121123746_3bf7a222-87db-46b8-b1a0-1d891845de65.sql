-- Ajustar comportamento ao desvincular colaborador de posto_servico
-- para que dias_trabalho voltem a status 'vago' em vez de serem deletados

CREATE OR REPLACE FUNCTION public.atribuir_dias_trabalho_colaborador()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- Caso o colaborador tenha sido atribuído a um posto (INSERT ou UPDATE trocando de posto)
  IF NEW.posto_servico_id IS NOT NULL AND (TG_OP = 'INSERT' OR OLD.posto_servico_id IS DISTINCT FROM NEW.posto_servico_id) THEN
    
    -- Se está mudando de um posto antigo para um novo posto
    IF TG_OP = 'UPDATE' AND OLD.posto_servico_id IS NOT NULL THEN
      -- Reverter dias do posto antigo para "vago" e desvincular do colaborador
      UPDATE public.dias_trabalho
      SET colaborador_id = NULL,
          status = 'vago'::status_posto,
          motivo_vago = 'Posto vago'::motivo_vago_type
      WHERE posto_servico_id = OLD.posto_servico_id
        AND colaborador_id = NEW.id
        AND data >= CURRENT_DATE;
      -- O trigger sync_dias_vagos() irá garantir o registro correto em posto_dias_vagos
    END IF;
    
    -- Atualizar dias_trabalho do novo posto para ocupado e vincular ao colaborador
    UPDATE public.dias_trabalho
    SET colaborador_id = NEW.id,
        status = 'ocupado'::status_posto,
        motivo_vago = NULL
    WHERE posto_servico_id = NEW.posto_servico_id
      AND data >= CURRENT_DATE
      AND colaborador_id IS NULL;
    
    -- Remover dias vagos do novo posto em posto_dias_vagos (se existirem)
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.posto_servico_id
      AND data >= CURRENT_DATE;
  
  -- Caso o colaborador tenha sido removido de um posto (NEW.posto_servico_id IS NULL)
  ELSIF NEW.posto_servico_id IS NULL AND TG_OP = 'UPDATE' AND OLD.posto_servico_id IS NOT NULL THEN
    -- Não fazemos nada aqui: a função desvincular_colaborador_posto()
    -- (chamada pelo trigger correspondente) já trata este cenário,
    -- garantindo que os dias_trabalho voltem a "vago" e que posto_dias_vagos
    -- seja atualizado corretamente.
    RETURN NEW;
  END IF;
  
  RETURN NEW;
END;
$function$;