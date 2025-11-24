-- Criar função para confirmar presença
CREATE OR REPLACE FUNCTION public.confirmar_presenca(
  p_dia_trabalho_id UUID,
  p_novo_status status_posto
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_dia_trabalho RECORD;
BEGIN
  -- Buscar informações do dia de trabalho
  SELECT * INTO v_dia_trabalho
  FROM public.dias_trabalho
  WHERE id = p_dia_trabalho_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Dia de trabalho não encontrado';
  END IF;
  
  -- Atualizar status do dia de trabalho
  UPDATE public.dias_trabalho
  SET status = p_novo_status,
      updated_at = now()
  WHERE id = p_dia_trabalho_id;
  
  -- Se o novo status for 'presenca_confirmada', inserir na tabela presencas
  IF p_novo_status = 'presenca_confirmada'::status_posto THEN
    INSERT INTO public.presencas (
      colaborador_id,
      data,
      horario_entrada,
      horario_saida,
      tipo,
      observacao,
      registrado_por
    )
    VALUES (
      v_dia_trabalho.colaborador_id,
      v_dia_trabalho.data,
      (v_dia_trabalho.data || ' ' || v_dia_trabalho.horario_inicio)::timestamp with time zone,
      (v_dia_trabalho.data || ' ' || v_dia_trabalho.horario_fim)::timestamp with time zone,
      'presente',
      'Presença confirmada automaticamente',
      COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
    )
    ON CONFLICT (colaborador_id, data) DO UPDATE
    SET horario_entrada = EXCLUDED.horario_entrada,
        horario_saida = EXCLUDED.horario_saida,
        tipo = EXCLUDED.tipo,
        observacao = EXCLUDED.observacao,
        updated_at = now();
    
    -- Remover de posto_dias_vagos se existir
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = v_dia_trabalho.posto_servico_id
      AND data = v_dia_trabalho.data
      AND COALESCE(colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid) = 
          COALESCE(v_dia_trabalho.colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid);
  END IF;
  
  -- Se o status for 'vago' ou 'vago_temporariamente', inserir em posto_dias_vagos
  IF p_novo_status IN ('vago'::status_posto, 'vago_temporariamente'::status_posto) THEN
    INSERT INTO public.posto_dias_vagos (
      posto_servico_id,
      colaborador_id,
      data,
      motivo,
      created_by
    )
    VALUES (
      v_dia_trabalho.posto_servico_id,
      v_dia_trabalho.colaborador_id,
      v_dia_trabalho.data,
      CASE 
        WHEN v_dia_trabalho.motivo_vago IS NOT NULL THEN v_dia_trabalho.motivo_vago::text
        ELSE 'Dia vago'
      END,
      COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
    )
    ON CONFLICT ON CONSTRAINT posto_dias_vagos_unique_constraint DO NOTHING;
  END IF;
END;
$function$;