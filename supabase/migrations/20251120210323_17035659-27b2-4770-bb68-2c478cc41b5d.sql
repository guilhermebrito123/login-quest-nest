-- Fix atualizar_status_posto function to use correct ENUM type
CREATE OR REPLACE FUNCTION public.atualizar_status_posto()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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
  
  -- Atualizar status do posto usando o tipo ENUM correto
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
$$;