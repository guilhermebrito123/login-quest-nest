-- Adicionar novo valor ao enum status_posto
ALTER TYPE status_posto ADD VALUE IF NOT EXISTS 'ocupacao_agendada';

-- Atualizar função para definir status como "ocupacao_agendada" ao agendar vinculação
CREATE OR REPLACE FUNCTION public.processar_agendamento_vinculacao()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- Processar vinculação agendada
  IF NEW.data_vinculacao IS NOT NULL AND NEW.posto_servico_id_destino IS NOT NULL THEN
    -- Atualizar posto_servico_id do colaborador imediatamente
    UPDATE public.colaboradores
    SET posto_servico_id = NEW.posto_servico_id_destino,
        updated_at = now()
    WHERE id = NEW.colaborador_id;
    
    -- Atualizar status do posto para "ocupacao_agendada"
    UPDATE public.postos_servico
    SET status = 'ocupacao_agendada'::status_posto,
        updated_at = now()
    WHERE id = NEW.posto_servico_id_destino;
    
    -- Atualizar dias_trabalho para ocupado a partir da data de vinculação
    UPDATE public.dias_trabalho
    SET colaborador_id = NEW.colaborador_id,
        status = 'ocupado'::status_posto,
        motivo_vago = NULL,
        updated_at = now()
    WHERE posto_servico_id = NEW.posto_servico_id_destino
      AND data >= NEW.data_vinculacao
      AND colaborador_id IS NULL;
    
    -- Deletar dias de posto_dias_vagos a partir da data de vinculação
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.posto_servico_id_destino
      AND data >= NEW.data_vinculacao;
  END IF;
  
  -- Processar desvinculação agendada
  IF NEW.data_desvinculacao IS NOT NULL AND NEW.posto_servico_id_origem IS NOT NULL THEN
    -- Reverter posto_servico_id se o colaborador foi associado ao posto origem imediatamente
    UPDATE public.colaboradores
    SET posto_servico_id = CASE 
      WHEN posto_servico_id = NEW.posto_servico_id_origem THEN NULL
      ELSE posto_servico_id
    END,
        updated_at = now()
    WHERE id = NEW.colaborador_id;
    
    -- Atualizar dias_trabalho para vago a partir da data de desvinculação
    UPDATE public.dias_trabalho
    SET colaborador_id = NULL,
        status = 'vago'::status_posto,
        motivo_vago = 'Posto vago'::motivo_vago_type,
        updated_at = now()
    WHERE posto_servico_id = NEW.posto_servico_id_origem
      AND colaborador_id = NEW.colaborador_id
      AND data >= NEW.data_desvinculacao;
    
    -- Inserir dias em posto_dias_vagos a partir da data de desvinculação
    INSERT INTO public.posto_dias_vagos (
      posto_servico_id,
      colaborador_id,
      data,
      motivo,
      created_by
    )
    SELECT 
      NEW.posto_servico_id_origem,
      NULL,
      data,
      'Posto vago',
      NEW.created_by
    FROM public.dias_trabalho
    WHERE posto_servico_id = NEW.posto_servico_id_origem
      AND colaborador_id IS NULL
      AND data >= NEW.data_desvinculacao
    ON CONFLICT (posto_servico_id, data) 
    WHERE colaborador_id IS NULL
    DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Atualizar função para mudar status de "ocupacao_agendada" para "ocupado" na data de vinculação
CREATE OR REPLACE FUNCTION public.processar_movimentacoes_agendadas()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_movimentacao RECORD;
  v_hoje DATE;
BEGIN
  v_hoje := (now() AT TIME ZONE 'America/Sao_Paulo')::DATE;
  
  -- Processar desvinculações agendadas para hoje
  FOR v_movimentacao IN 
    SELECT * FROM public.colaborador_movimentacoes_posto
    WHERE status = 'agendado'
      AND data_desvinculacao = v_hoje
      AND posto_servico_id_origem IS NOT NULL
  LOOP
    -- Desvincular colaborador do posto origem
    UPDATE public.colaboradores
    SET posto_servico_id = NULL,
        updated_at = now()
    WHERE id = v_movimentacao.colaborador_id
      AND posto_servico_id = v_movimentacao.posto_servico_id_origem;
    
    -- Marcar dias_trabalho futuros como vago e desvincular colaborador
    UPDATE public.dias_trabalho
    SET colaborador_id = NULL,
        status = 'vago'::status_posto,
        motivo_vago = 'Posto vago'::motivo_vago_type,
        updated_at = now()
    WHERE posto_servico_id = v_movimentacao.posto_servico_id_origem
      AND colaborador_id = v_movimentacao.colaborador_id
      AND data >= v_hoje;
    
    -- Inserir dias futuros em posto_dias_vagos
    INSERT INTO public.posto_dias_vagos (
      posto_servico_id,
      colaborador_id,
      data,
      motivo,
      created_by
    )
    SELECT 
      v_movimentacao.posto_servico_id_origem,
      NULL,
      data,
      'Posto vago',
      v_movimentacao.created_by
    FROM public.dias_trabalho
    WHERE posto_servico_id = v_movimentacao.posto_servico_id_origem
      AND colaborador_id IS NULL
      AND data >= v_hoje
    ON CONFLICT (posto_servico_id, data) 
    WHERE colaborador_id IS NULL
    DO NOTHING;
    
    -- Se não tem vinculação futura agendada, marcar como processado
    IF v_movimentacao.data_vinculacao IS NULL OR v_movimentacao.posto_servico_id_destino IS NULL THEN
      UPDATE public.colaborador_movimentacoes_posto
      SET status = 'processado',
          updated_at = now()
      WHERE id = v_movimentacao.id;
    END IF;
  END LOOP;
  
  -- Processar vinculações agendadas para hoje
  FOR v_movimentacao IN 
    SELECT * FROM public.colaborador_movimentacoes_posto
    WHERE status = 'agendado'
      AND data_vinculacao = v_hoje
      AND posto_servico_id_destino IS NOT NULL
  LOOP
    -- Vincular colaborador ao posto destino
    UPDATE public.colaboradores
    SET posto_servico_id = v_movimentacao.posto_servico_id_destino,
        updated_at = now()
    WHERE id = v_movimentacao.colaborador_id;
    
    -- Mudar status do posto de "ocupacao_agendada" para "ocupado"
    UPDATE public.postos_servico
    SET status = 'ocupado'::status_posto,
        updated_at = now()
    WHERE id = v_movimentacao.posto_servico_id_destino
      AND status = 'ocupacao_agendada'::status_posto;
    
    -- Atribuir colaborador aos dias_trabalho futuros e marcar como ocupado
    UPDATE public.dias_trabalho
    SET colaborador_id = v_movimentacao.colaborador_id,
        status = 'ocupado'::status_posto,
        motivo_vago = NULL,
        updated_at = now()
    WHERE posto_servico_id = v_movimentacao.posto_servico_id_destino
      AND colaborador_id IS NULL
      AND data >= v_hoje;
    
    -- Remover dias futuros de posto_dias_vagos
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = v_movimentacao.posto_servico_id_destino
      AND data >= v_hoje;
    
    -- Marcar movimentação como processada
    UPDATE public.colaborador_movimentacoes_posto
    SET status = 'processado',
        updated_at = now()
    WHERE id = v_movimentacao.id;
  END LOOP;
END;
$function$;