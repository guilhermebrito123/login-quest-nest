-- Atualizar função agendar_ocupacao_posto para atribuir posto e unidade ao colaborador imediatamente
CREATE OR REPLACE FUNCTION public.agendar_ocupacao_posto(
  p_posto_servico_id UUID,
  p_colaborador_id UUID,
  p_data DATE,
  p_usuario_id UUID DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
  
  -- NOVO: Atualizar colaborador com posto_servico_id e unidade_id imediatamente
  UPDATE public.colaboradores
  SET posto_servico_id = p_posto_servico_id,
      unidade_id = v_posto.unidade_id,
      updated_at = now()
  WHERE id = p_colaborador_id;
  
  -- Verificar se já existe dias_trabalho para esse posto nessa data
  SELECT * INTO v_dia_trabalho
  FROM public.dias_trabalho
  WHERE posto_servico_id = p_posto_servico_id
    AND data = p_data;
  
  IF FOUND THEN
    -- Se já existe e tem colaborador, é erro
    IF v_dia_trabalho.colaborador_id IS NOT NULL THEN
      RAISE EXCEPTION 'Posto já está ocupado ou agendado para esta data';
    END IF;
    
    -- Se existe mas está vago, atualizar
    UPDATE public.dias_trabalho
    SET colaborador_id = p_colaborador_id,
        status = 'ocupacao_agendada'::status_posto,
        motivo_vago = NULL,
        updated_at = now()
    WHERE posto_servico_id = p_posto_servico_id
      AND data = p_data;
  ELSE
    -- Se não existe, inserir novo registro
    INSERT INTO public.dias_trabalho (
      posto_servico_id,
      data,
      horario_inicio,
      horario_fim,
      intervalo_refeicao,
      colaborador_id,
      status
    ) VALUES (
      p_posto_servico_id,
      p_data,
      v_posto.horario_inicio,
      v_posto.horario_fim,
      v_posto.intervalo_refeicao,
      p_colaborador_id,
      'ocupacao_agendada'::status_posto
    );
  END IF;
  
  -- Atualizar status do posto para ocupacao_agendada
  UPDATE public.postos_servico
  SET status = 'ocupacao_agendada'::status_posto,
      updated_at = now()
  WHERE id = p_posto_servico_id;
  
  -- Marcar dias antes da data de alocação como vago com motivo "Posto vago"
  UPDATE public.dias_trabalho
  SET status = 'vago'::status_posto,
      motivo_vago = 'Posto vago'::motivo_vago_type,
      colaborador_id = NULL,
      updated_at = now()
  WHERE posto_servico_id = p_posto_servico_id
    AND data < p_data
    AND data >= v_hoje
    AND status != 'vago'::status_posto;
  
  -- Inserir em posto_dias_vagos os dias antes da alocação
  INSERT INTO public.posto_dias_vagos (
    posto_servico_id,
    colaborador_id,
    data,
    motivo,
    created_by
  )
  SELECT 
    p_posto_servico_id,
    NULL,
    data,
    'Posto vago',
    COALESCE(p_usuario_id, auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
  FROM public.dias_trabalho
  WHERE posto_servico_id = p_posto_servico_id
    AND data < p_data
    AND data >= v_hoje
    AND status = 'vago'::status_posto
  ON CONFLICT (posto_servico_id, data) 
  WHERE colaborador_id IS NULL
  DO UPDATE SET
    motivo = 'Posto vago',
    created_by = COALESCE(p_usuario_id, auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid);
  
  -- Atualizar dias a partir da data de alocação para ocupado
  UPDATE public.dias_trabalho
  SET status = 'ocupado'::status_posto,
      colaborador_id = p_colaborador_id,
      motivo_vago = NULL,
      updated_at = now()
  WHERE posto_servico_id = p_posto_servico_id
    AND data >= p_data
    AND colaborador_id IS NULL;
  
  -- Deletar dias vagos a partir da data de alocação
  DELETE FROM public.posto_dias_vagos
  WHERE posto_servico_id = p_posto_servico_id
    AND data >= p_data;
END;
$$;