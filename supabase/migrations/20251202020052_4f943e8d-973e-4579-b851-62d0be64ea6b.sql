-- Ajustar função agendar_ocupacao_posto para não duplicar inserções em posto_dias_vagos
CREATE OR REPLACE FUNCTION public.agendar_ocupacao_posto(
  p_posto_servico_id uuid,
  p_colaborador_id uuid,
  p_data date,
  p_usuario_id uuid DEFAULT NULL::uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_posto RECORD;
  v_colaborador RECORD;
  v_dia_trabalho RECORD;
  v_hoje DATE;
BEGIN
  v_hoje := (now() AT TIME ZONE 'America/Sao_Paulo')::DATE;
  
  -- Validar se o posto existe e não está inativo
  SELECT * INTO v_posto
  FROM public.postos_servico
  WHERE id = p_posto_servico_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Posto de serviço não encontrado';
  END IF;
  
  IF v_posto.status = 'inativo'::status_posto THEN
    RAISE EXCEPTION 'Posto de serviço está inativo';
  END IF;
  
  -- Validar se o colaborador existe e está ativo
  SELECT * INTO v_colaborador
  FROM public.colaboradores
  WHERE id = p_colaborador_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Colaborador não encontrado';
  END IF;
  
  IF v_colaborador.status_colaborador != 'ativo'::status_colaborador THEN
    RAISE EXCEPTION 'Colaborador não está ativo';
  END IF;
  
  -- Verificar disponibilidade ANTES de atualizar colaborador
  SELECT * INTO v_dia_trabalho
  FROM public.dias_trabalho
  WHERE posto_servico_id = p_posto_servico_id
    AND data = p_data
  FOR UPDATE;

  IF FOUND AND v_dia_trabalho.colaborador_id IS NOT NULL THEN
    RAISE EXCEPTION 'Posto já está ocupado ou agendado para esta data';
  END IF;
  
  -- Atualizar colaborador (trigger vai preencher dias automaticamente)
  UPDATE public.colaboradores
  SET posto_servico_id = p_posto_servico_id,
      unidade_id = v_posto.unidade_id,
      updated_at = now()
  WHERE id = p_colaborador_id;
  
  -- Atualizar status do posto para ocupado
  UPDATE public.postos_servico
  SET status = 'ocupado'::status_posto,
      updated_at = now()
  WHERE id = p_posto_servico_id;
  
  -- Marcar dias ANTES da data de alocação como vago
  UPDATE public.dias_trabalho
  SET colaborador_id = NULL,
      status = 'vago'::status_posto,
      motivo_vago = 'Posto vago'::motivo_vago_type,
      updated_at = now()
  WHERE posto_servico_id = p_posto_servico_id
    AND data < p_data
    AND data >= v_hoje;
  
  -- IMPORTANTE: não inserir manualmente em posto_dias_vagos aqui.
  -- O trigger sync_dias_vagos será responsável por criar os registros
  -- correspondentes em posto_dias_vagos a partir da mudança de status
  -- em dias_trabalho.
  
  -- Remover dias vagos a partir da data de alocação (não deve haver vaga em dia ocupado)
  DELETE FROM public.posto_dias_vagos
  WHERE posto_servico_id = p_posto_servico_id
    AND data >= p_data;
END;
$function$;

-- Ajustar trigger sync_dias_vagos para remover QUALQUER vaga quando o dia fica ocupado
CREATE OR REPLACE FUNCTION public.sync_dias_vagos()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.status = 'vago'::status_posto AND (OLD IS NULL OR OLD.status != 'vago'::status_posto) THEN
    -- Verificar se já existe algum registro para este posto/data antes de inserir
    IF NOT EXISTS (
      SELECT 1 FROM public.posto_dias_vagos
      WHERE posto_servico_id = NEW.posto_servico_id
        AND data = NEW.data
    ) THEN
      -- Só inserir se não existe nenhum registro ainda
      IF NEW.colaborador_id IS NOT NULL THEN
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
          COALESCE(NEW.motivo_vago::text, 'Dia vago'),
          COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
        )
        ON CONFLICT (posto_servico_id, data, colaborador_id)
        WHERE colaborador_id IS NOT NULL
        DO NOTHING;
      ELSE
        INSERT INTO public.posto_dias_vagos (
          posto_servico_id,
          colaborador_id,
          data,
          motivo,
          created_by
        ) VALUES (
          NEW.posto_servico_id,
          NULL,
          NEW.data,
          COALESCE(NEW.motivo_vago::text, 'Posto vago'),
          COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
        )
        ON CONFLICT (posto_servico_id, data)
        WHERE colaborador_id IS NULL
        DO NOTHING;
      END IF;
    END IF;
  
  ELSIF NEW.status = 'ocupado'::status_posto AND OLD.status = 'vago'::status_posto THEN
    -- Dia deixou de estar vago: remover QUALQUER registro de vaga (genérico ou específico)
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.posto_servico_id
      AND data = NEW.data;
  END IF;
  
  RETURN NEW;
END;
$function$;