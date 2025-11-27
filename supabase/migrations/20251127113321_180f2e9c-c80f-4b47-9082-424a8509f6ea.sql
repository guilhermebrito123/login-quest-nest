-- Corrigir função agendar_ocupacao_posto para verificar disponibilidade ANTES de atualizar colaborador
CREATE OR REPLACE FUNCTION public.agendar_ocupacao_posto(
  p_posto_servico_id uuid, 
  p_colaborador_id uuid, 
  p_data date, 
  p_usuario_id uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
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
  
  -- CRÍTICO: Verificar disponibilidade ANTES de atualizar colaborador
  SELECT * INTO v_dia_trabalho
  FROM public.dias_trabalho
  WHERE posto_servico_id = p_posto_servico_id
    AND data = p_data
  FOR UPDATE; -- Lock para evitar race condition
  
  IF FOUND AND v_dia_trabalho.colaborador_id IS NOT NULL THEN
    RAISE EXCEPTION 'Posto já está ocupado ou agendado para esta data';
  END IF;
  
  -- Atualizar colaborador (trigger preencherá dias automaticamente)
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
  
  -- Inserir dias vagos antes da alocação
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
  
  -- Deletar dias vagos a partir da data de alocação
  DELETE FROM public.posto_dias_vagos
  WHERE posto_servico_id = p_posto_servico_id
    AND data >= p_data;
END;
$$;