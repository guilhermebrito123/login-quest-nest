-- Alterar status de dias_trabalho para usar o ENUM status_posto
-- e atualizar funções para sincronização correta com posto_dias_vagos

-- 1) Dropar trigger que depende da coluna status
DROP TRIGGER IF EXISTS sync_dias_vagos_trigger ON public.dias_trabalho;

-- 2) Remover CHECK constraint existente
ALTER TABLE public.dias_trabalho DROP CONSTRAINT IF EXISTS dias_trabalho_status_check;

-- 3) Mapear valores antigos para novos
UPDATE public.dias_trabalho
SET status = CASE 
  WHEN status = 'dia_vago' THEN 'vago'
  WHEN status = 'ativo' THEN 'ocupado'
  ELSE 'vago'
END
WHERE status NOT IN ('vago', 'ocupado', 'vago_temporariamente', 'ocupado_temporariamente');

-- 4) Remover default temporariamente
ALTER TABLE public.dias_trabalho ALTER COLUMN status DROP DEFAULT;

-- 5) Converter para ENUM
ALTER TABLE public.dias_trabalho 
ALTER COLUMN status TYPE status_posto 
USING status::status_posto;

-- 6) Recriar default
ALTER TABLE public.dias_trabalho 
ALTER COLUMN status SET DEFAULT 'vago'::status_posto;

-- 7) Recriar função gerar_dias_trabalho_mes_corrente para criar dias com status 'vago'
CREATE OR REPLACE FUNCTION public.gerar_dias_trabalho_mes_corrente()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_data DATE;
  v_mes_inicio DATE;
  v_mes_fim DATE;
  v_dia_semana INTEGER;
BEGIN
  IF NEW.dias_semana IS NULL OR array_length(NEW.dias_semana, 1) IS NULL THEN
    RETURN NEW;
  END IF;
  
  v_mes_inicio := date_trunc('month', CURRENT_DATE)::DATE;
  v_mes_fim := (date_trunc('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE;
  
  FOR v_data IN SELECT generate_series(v_mes_inicio, v_mes_fim, '1 day'::INTERVAL)::DATE
  LOOP
    v_dia_semana := EXTRACT(DOW FROM v_data);
    
    IF v_dia_semana = ANY(NEW.dias_semana) THEN
      INSERT INTO public.dias_trabalho (
        posto_servico_id,
        data,
        horario_inicio,
        horario_fim,
        intervalo_refeicao,
        status
      ) VALUES (
        NEW.id,
        v_data,
        NEW.horario_inicio,
        NEW.horario_fim,
        NEW.intervalo_refeicao,
        'vago'::status_posto
      )
      ON CONFLICT ON CONSTRAINT dias_trabalho_posto_data_colaborador_unique DO NOTHING;
    END IF;
  END LOOP;
  
  RETURN NEW;
END;
$function$;

-- 8) Atualizar função sync_dias_vagos para usar ENUM status_posto
CREATE OR REPLACE FUNCTION public.sync_dias_vagos()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.status = 'vago'::status_posto AND (OLD IS NULL OR OLD.status != 'vago'::status_posto) THEN
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
        (SELECT 'Posto vago' FROM public.postos_servico WHERE id = NEW.posto_servico_id AND status = 'vago'::status_posto),
        'Dia vago'
      ),
      COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
    )
    ON CONFLICT ON CONSTRAINT posto_dias_vagos_unique_constraint
    DO UPDATE SET motivo = EXCLUDED.motivo;
  
  ELSIF NEW.status = 'ocupado'::status_posto AND OLD.status = 'vago'::status_posto THEN
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.posto_servico_id
      AND data = NEW.data
      AND COALESCE(colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid) = 
          COALESCE(NEW.colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid);
  END IF;
  
  RETURN NEW;
END;
$function$;

-- 9) Recriar trigger sync_dias_vagos
CREATE TRIGGER sync_dias_vagos_trigger
  AFTER INSERT OR UPDATE ON public.dias_trabalho
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_dias_vagos();

-- 10) Atualizar função marcar_dias_posto_vago para usar ENUM status_posto
CREATE OR REPLACE FUNCTION public.marcar_dias_posto_vago()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.status = 'vago'::status_posto AND (OLD IS NULL OR OLD.status != 'vago'::status_posto) THEN
    UPDATE public.dias_trabalho
    SET status = 'vago'::status_posto
    WHERE posto_servico_id = NEW.id
      AND data >= CURRENT_DATE
      AND status != 'vago'::status_posto;
  
  ELSIF NEW.status = 'ocupado'::status_posto AND OLD.status = 'vago'::status_posto THEN
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.id
      AND motivo = 'Posto vago';
    
    UPDATE public.dias_trabalho
    SET status = 'ocupado'::status_posto
    WHERE posto_servico_id = NEW.id
      AND data >= CURRENT_DATE
      AND status = 'vago'::status_posto
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