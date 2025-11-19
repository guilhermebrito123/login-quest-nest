-- Adicionar coluna status em dias_trabalho
ALTER TABLE public.dias_trabalho
ADD COLUMN status TEXT DEFAULT 'ativo' CHECK (status IN ('ativo', 'dia_vago'));

-- Função para sincronizar dias vagos com posto_dias_vagos
CREATE OR REPLACE FUNCTION public.sync_dias_vagos()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- Se o dia foi marcado como vago, inserir em posto_dias_vagos
  IF NEW.status = 'dia_vago' AND (OLD IS NULL OR OLD.status != 'dia_vago') THEN
    INSERT INTO public.posto_dias_vagos (
      posto_servico_id,
      colaborador_id,
      data,
      motivo,
      created_by
    ) VALUES (
      NEW.posto_servico_id,
      NEW.colaborador_id,
      NEW.data,
      COALESCE(
        (SELECT 'Posto vago' FROM public.postos_servico WHERE id = NEW.posto_servico_id AND status = 'vago'),
        'Dia vago'
      ),
      COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
    )
    ON CONFLICT (posto_servico_id, data, COALESCE(colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid))
    DO UPDATE SET motivo = EXCLUDED.motivo;
  
  -- Se o dia foi marcado como ativo, remover de posto_dias_vagos
  ELSIF NEW.status = 'ativo' AND OLD.status = 'dia_vago' THEN
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.posto_servico_id
      AND data = NEW.data
      AND COALESCE(colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid) = 
          COALESCE(NEW.colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid);
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Trigger para sincronizar dias_trabalho com posto_dias_vagos
CREATE TRIGGER sync_dias_vagos_trigger
AFTER INSERT OR UPDATE OF status ON public.dias_trabalho
FOR EACH ROW
EXECUTE FUNCTION public.sync_dias_vagos();

-- Função para marcar dias como vagos quando posto fica vago
CREATE OR REPLACE FUNCTION public.marcar_dias_posto_vago()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- Se o posto ficou vago, marcar todos os dias futuros como vago
  IF NEW.status = 'vago' AND (OLD IS NULL OR OLD.status != 'vago') THEN
    UPDATE public.dias_trabalho
    SET status = 'dia_vago'
    WHERE posto_servico_id = NEW.id
      AND data >= CURRENT_DATE
      AND status != 'dia_vago';
  
  -- Se o posto ficou ocupado, marcar dias como ativos (exceto os que foram explicitamente marcados como vagos)
  ELSIF NEW.status = 'ocupado' AND OLD.status = 'vago' THEN
    -- Remover dias vagos que eram do posto vago
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.id
      AND motivo = 'Posto vago';
    
    -- Atualizar status dos dias_trabalho correspondentes
    UPDATE public.dias_trabalho
    SET status = 'ativo'
    WHERE posto_servico_id = NEW.id
      AND data >= CURRENT_DATE
      AND status = 'dia_vago'
      AND NOT EXISTS (
        SELECT 1 FROM public.posto_dias_vagos pdv
        WHERE pdv.posto_servico_id = dias_trabalho.posto_servico_id
          AND pdv.data = dias_trabalho.data
          AND COALESCE(pdv.colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid) = 
              COALESCE(dias_trabalho.colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid)
      );
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Trigger para marcar dias quando posto muda de status
CREATE TRIGGER marcar_dias_posto_vago_trigger
AFTER INSERT OR UPDATE OF status ON public.postos_servico
FOR EACH ROW
EXECUTE FUNCTION public.marcar_dias_posto_vago();

-- Adicionar unique constraint em posto_dias_vagos se não existir
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'posto_dias_vagos_posto_data_colaborador_unique'
  ) THEN
    CREATE UNIQUE INDEX posto_dias_vagos_posto_data_colaborador_unique 
    ON public.posto_dias_vagos(posto_servico_id, data, COALESCE(colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid));
  END IF;
END $$;