-- Função para cancelar ocupação de posto
CREATE OR REPLACE FUNCTION public.cancelar_ocupacao_posto(
  p_posto_servico_id UUID,
  p_data DATE
)
RETURNS public.dias_trabalho
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_dia_trabalho public.dias_trabalho%ROWTYPE;
  v_colaborador_id UUID;
BEGIN
  -- Buscar o dia de trabalho com lock
  SELECT *
  INTO v_dia_trabalho
  FROM public.dias_trabalho
  WHERE posto_servico_id = p_posto_servico_id
    AND data = p_data
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Não existe agendamento para posto % na data %',
      p_posto_servico_id, p_data;
  END IF;

  -- Guardar o colaborador_id antes de limpar
  v_colaborador_id := v_dia_trabalho.colaborador_id;

  -- Atualizar o dia de trabalho para vago
  UPDATE public.dias_trabalho
  SET colaborador_id = NULL,
      status = 'vago'::status_posto,
      motivo_vago = 'Posto vago'::motivo_vago_type,
      updated_at = now()
  WHERE id = v_dia_trabalho.id
  RETURNING * INTO v_dia_trabalho;

  -- Inserir em posto_dias_vagos
  INSERT INTO public.posto_dias_vagos (
    posto_servico_id,
    colaborador_id,
    data,
    motivo,
    created_by
  ) VALUES (
    p_posto_servico_id,
    NULL,
    p_data,
    'Posto vago',
    COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
  )
  ON CONFLICT (posto_servico_id, data)
  WHERE colaborador_id IS NULL
  DO UPDATE SET
    motivo = 'Posto vago',
    created_by = COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid);

  -- Se a data for hoje ou anterior, atualizar status do posto para vago
  IF p_data <= (now() AT TIME ZONE 'America/Sao_Paulo')::DATE THEN
    UPDATE public.postos_servico
    SET status = 'vago'::status_posto,
        updated_at = now()
    WHERE id = p_posto_servico_id;
  END IF;

  -- Se tinha colaborador, limpar posto_servico_id dele se a data for futura
  IF v_colaborador_id IS NOT NULL AND p_data > (now() AT TIME ZONE 'America/Sao_Paulo')::DATE THEN
    UPDATE public.colaboradores
    SET posto_servico_id = NULL,
        updated_at = now()
    WHERE id = v_colaborador_id
      AND posto_servico_id = p_posto_servico_id;
  END IF;

  RETURN v_dia_trabalho;
END;
$$;