-- Recriar trigger para atualizar status do posto ao desvincular colaborador
DROP TRIGGER IF EXISTS atualizar_status_posto_trigger ON public.colaboradores;

CREATE OR REPLACE FUNCTION public.atualizar_status_posto()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_posto_id UUID;
  v_tem_colaborador BOOLEAN;
BEGIN
  -- Determinar qual posto_servico_id usar baseado na operação
  IF TG_OP = 'DELETE' THEN
    v_posto_id := OLD.posto_servico_id;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Se está desvinculando (posto_servico_id está sendo setado para NULL)
    IF OLD.posto_servico_id IS NOT NULL AND NEW.posto_servico_id IS NULL THEN
      v_posto_id := OLD.posto_servico_id;
    -- Se está vinculando a um novo posto
    ELSIF NEW.posto_servico_id IS NOT NULL THEN
      v_posto_id := NEW.posto_servico_id;
    -- Se está mudando de posto
    ELSIF OLD.posto_servico_id IS NOT NULL AND NEW.posto_servico_id IS NOT NULL AND OLD.posto_servico_id != NEW.posto_servico_id THEN
      -- Atualizar o posto antigo primeiro
      SELECT EXISTS (
        SELECT 1 
        FROM public.colaboradores 
        WHERE posto_servico_id = OLD.posto_servico_id
        AND id != NEW.id
        AND status = 'ativo'
      ) INTO v_tem_colaborador;
      
      UPDATE public.postos_servico
      SET status = CASE 
        WHEN v_tem_colaborador THEN 'ocupado'::status_posto
        ELSE 'vago'::status_posto
      END
      WHERE id = OLD.posto_servico_id;
      
      -- Agora tratar o novo posto
      v_posto_id := NEW.posto_servico_id;
    END IF;
  ELSIF TG_OP = 'INSERT' THEN
    v_posto_id := NEW.posto_servico_id;
  END IF;
  
  -- Se não há posto para atualizar, retornar
  IF v_posto_id IS NULL THEN
    IF TG_OP = 'DELETE' THEN
      RETURN OLD;
    ELSE
      RETURN NEW;
    END IF;
  END IF;
  
  -- Verificar se existe pelo menos um colaborador ativo no posto
  SELECT EXISTS (
    SELECT 1 
    FROM public.colaboradores 
    WHERE posto_servico_id = v_posto_id
    AND status = 'ativo'
    AND (TG_OP = 'DELETE' OR id != OLD.id)
  ) INTO v_tem_colaborador;
  
  -- Atualizar status do posto
  UPDATE public.postos_servico
  SET status = CASE 
    WHEN v_tem_colaborador THEN 'ocupado'::status_posto
    ELSE 'vago'::status_posto
  END
  WHERE id = v_posto_id;
  
  -- Retornar registro apropriado
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$function$;

-- Recriar trigger
CREATE TRIGGER atualizar_status_posto_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.colaboradores
FOR EACH ROW
EXECUTE FUNCTION public.atualizar_status_posto();