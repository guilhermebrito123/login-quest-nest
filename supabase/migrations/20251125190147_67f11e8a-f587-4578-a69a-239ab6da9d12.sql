-- Criar enum para status_colaborador
CREATE TYPE public.status_colaborador AS ENUM ('ativo', 'inativo');

-- Remover todos os triggers temporariamente
DROP TRIGGER IF EXISTS trigger_atualizar_status_posto_update ON public.colaboradores;
DROP TRIGGER IF EXISTS trigger_atualizar_status_posto_insert ON public.colaboradores;
DROP TRIGGER IF EXISTS trigger_atualizar_status_posto_delete ON public.colaboradores;
DROP TRIGGER IF EXISTS trigger_desvincular_colaborador_posto ON public.colaboradores;
DROP TRIGGER IF EXISTS trigger_atribuir_dias_trabalho_colaborador ON public.colaboradores;

-- Adicionar nova coluna com o enum
ALTER TABLE public.colaboradores 
  ADD COLUMN status_colaborador status_colaborador DEFAULT 'ativo'::status_colaborador;

-- Copiar dados da coluna antiga para a nova
UPDATE public.colaboradores
SET status_colaborador = status::status_colaborador;

-- Tornar a nova coluna NOT NULL
ALTER TABLE public.colaboradores 
  ALTER COLUMN status_colaborador SET NOT NULL;

-- Remover a coluna antiga
ALTER TABLE public.colaboradores 
  DROP COLUMN status;

-- Atualizar função atualizar_status_posto para usar status_colaborador
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
  IF TG_OP = 'DELETE' THEN
    v_posto_id := OLD.posto_servico_id;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.posto_servico_id IS NOT NULL AND NEW.posto_servico_id IS NULL THEN
      v_posto_id := OLD.posto_servico_id;
    ELSIF NEW.posto_servico_id IS NOT NULL THEN
      v_posto_id := NEW.posto_servico_id;
    ELSIF OLD.posto_servico_id IS NOT NULL AND NEW.posto_servico_id IS NOT NULL AND OLD.posto_servico_id != NEW.posto_servico_id THEN
      SELECT EXISTS (
        SELECT 1 
        FROM public.colaboradores 
        WHERE posto_servico_id = OLD.posto_servico_id
        AND id != NEW.id
        AND status_colaborador = 'ativo'::status_colaborador
      ) INTO v_tem_colaborador;
      
      UPDATE public.postos_servico
      SET status = CASE 
        WHEN v_tem_colaborador THEN 'ocupado'::status_posto
        ELSE 'vago'::status_posto
      END
      WHERE id = OLD.posto_servico_id;
      
      v_posto_id := NEW.posto_servico_id;
    END IF;
  ELSIF TG_OP = 'INSERT' THEN
    v_posto_id := NEW.posto_servico_id;
  END IF;
  
  IF v_posto_id IS NULL THEN
    IF TG_OP = 'DELETE' THEN
      RETURN OLD;
    ELSE
      RETURN NEW;
    END IF;
  END IF;
  
  IF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND NEW.posto_servico_id IS NULL) THEN
    SELECT EXISTS (
      SELECT 1 
      FROM public.colaboradores 
      WHERE posto_servico_id = v_posto_id
      AND id != OLD.id
      AND status_colaborador = 'ativo'::status_colaborador
    ) INTO v_tem_colaborador;
  ELSE
    SELECT EXISTS (
      SELECT 1 
      FROM public.colaboradores 
      WHERE posto_servico_id = v_posto_id
      AND status_colaborador = 'ativo'::status_colaborador
    ) INTO v_tem_colaborador;
  END IF;
  
  UPDATE public.postos_servico
  SET status = CASE 
    WHEN v_tem_colaborador THEN 'ocupado'::status_posto
    ELSE 'vago'::status_posto
  END
  WHERE id = v_posto_id;
  
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$function$;

-- Recriar triggers
CREATE TRIGGER trigger_atualizar_status_posto_update
  AFTER UPDATE OF status_colaborador, posto_servico_id ON public.colaboradores
  FOR EACH ROW
  EXECUTE FUNCTION public.atualizar_status_posto();

CREATE TRIGGER trigger_atualizar_status_posto_insert
  AFTER INSERT ON public.colaboradores
  FOR EACH ROW
  EXECUTE FUNCTION public.atualizar_status_posto();

CREATE TRIGGER trigger_atualizar_status_posto_delete
  AFTER DELETE ON public.colaboradores
  FOR EACH ROW
  EXECUTE FUNCTION public.atualizar_status_posto();

CREATE TRIGGER trigger_desvincular_colaborador_posto
  BEFORE UPDATE OF posto_servico_id OR DELETE ON public.colaboradores
  FOR EACH ROW
  EXECUTE FUNCTION public.desvincular_colaborador_posto();

CREATE TRIGGER trigger_atribuir_dias_trabalho_colaborador
  AFTER INSERT OR UPDATE OF posto_servico_id ON public.colaboradores
  FOR EACH ROW
  EXECUTE FUNCTION public.atribuir_dias_trabalho_colaborador();