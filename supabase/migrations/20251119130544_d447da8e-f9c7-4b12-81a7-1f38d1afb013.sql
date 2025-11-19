-- Função para atualizar status do posto baseado em colaboradores
CREATE OR REPLACE FUNCTION public.atualizar_status_posto()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_posto_id UUID;
  v_tem_colaborador BOOLEAN;
BEGIN
  -- Determinar qual posto_servico_id usar baseado na operação
  IF TG_OP = 'DELETE' THEN
    v_posto_id := OLD.posto_servico_id;
  ELSE
    v_posto_id := NEW.posto_servico_id;
  END IF;
  
  -- Se não há posto_servico_id, retornar
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
  ) INTO v_tem_colaborador;
  
  -- Atualizar status do posto
  UPDATE public.postos_servico
  SET status = CASE 
    WHEN v_tem_colaborador THEN 'ocupado'
    ELSE 'vago'
  END
  WHERE id = v_posto_id;
  
  -- Retornar registro apropriado
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$;

-- Remover triggers existentes se houver
DROP TRIGGER IF EXISTS trigger_atualizar_status_posto_insert ON public.colaboradores;
DROP TRIGGER IF EXISTS trigger_atualizar_status_posto_update ON public.colaboradores;
DROP TRIGGER IF EXISTS trigger_atualizar_status_posto_delete ON public.colaboradores;

-- Trigger para INSERT
CREATE TRIGGER trigger_atualizar_status_posto_insert
AFTER INSERT ON public.colaboradores
FOR EACH ROW
EXECUTE FUNCTION public.atualizar_status_posto();

-- Trigger para UPDATE
CREATE TRIGGER trigger_atualizar_status_posto_update
AFTER UPDATE OF posto_servico_id, status ON public.colaboradores
FOR EACH ROW
WHEN (OLD.posto_servico_id IS DISTINCT FROM NEW.posto_servico_id OR OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION public.atualizar_status_posto();

-- Trigger para DELETE
CREATE TRIGGER trigger_atualizar_status_posto_delete
AFTER DELETE ON public.colaboradores
FOR EACH ROW
EXECUTE FUNCTION public.atualizar_status_posto();

-- Atualizar status de todos os postos existentes
UPDATE public.postos_servico p
SET status = CASE
  WHEN EXISTS (
    SELECT 1 FROM public.colaboradores c 
    WHERE c.posto_servico_id = p.id 
    AND c.status = 'ativo'
  ) THEN 'ocupado'
  ELSE 'vago'
END;