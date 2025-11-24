-- Adicionar coluna posto_servico_id na tabela presencas
ALTER TABLE public.presencas 
ADD COLUMN posto_servico_id uuid;

-- Adicionar foreign key para postos_servico
ALTER TABLE public.presencas
ADD CONSTRAINT presencas_posto_servico_id_fkey 
FOREIGN KEY (posto_servico_id) 
REFERENCES public.postos_servico(id) 
ON DELETE SET NULL;

-- Atualizar função arquivar_dias_trabalho_em_presencas para incluir posto_servico_id
CREATE OR REPLACE FUNCTION public.arquivar_dias_trabalho_em_presencas()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_data_ontem DATE;
BEGIN
  v_data_ontem := (now() AT TIME ZONE 'America/Sao_Paulo')::DATE - INTERVAL '1 day';
  
  INSERT INTO public.presencas (
    colaborador_id,
    posto_servico_id,
    data,
    horario_entrada,
    horario_saida,
    tipo,
    observacao,
    registrado_por
  )
  SELECT 
    dt.colaborador_id,
    dt.posto_servico_id,
    dt.data,
    (dt.data || ' ' || dt.horario_inicio)::timestamp with time zone,
    (dt.data || ' ' || dt.horario_fim)::timestamp with time zone,
    'presente',
    'Arquivado automaticamente - Status: ' || dt.status::text,
    '00000000-0000-0000-0000-000000000000'::uuid
  FROM public.dias_trabalho dt
  WHERE dt.data = v_data_ontem
    AND dt.colaborador_id IS NOT NULL
    AND dt.status IN ('ocupado'::status_posto, 'ocupado_temporariamente'::status_posto, 'presenca_confirmada'::status_posto)
  ON CONFLICT (colaborador_id, data) DO NOTHING;
END;
$function$;

-- Atualizar função confirmar_presenca para incluir posto_servico_id
CREATE OR REPLACE FUNCTION public.confirmar_presenca(p_dia_trabalho_id uuid, p_novo_status status_posto)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_dia_trabalho RECORD;
BEGIN
  SELECT * INTO v_dia_trabalho
  FROM public.dias_trabalho
  WHERE id = p_dia_trabalho_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Dia de trabalho não encontrado';
  END IF;
  
  UPDATE public.dias_trabalho
  SET status = p_novo_status,
      updated_at = now()
  WHERE id = p_dia_trabalho_id;
  
  IF p_novo_status = 'presenca_confirmada'::status_posto THEN
    INSERT INTO public.presencas (
      colaborador_id,
      posto_servico_id,
      data,
      horario_entrada,
      horario_saida,
      tipo,
      observacao,
      registrado_por
    )
    VALUES (
      v_dia_trabalho.colaborador_id,
      v_dia_trabalho.posto_servico_id,
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
        posto_servico_id = EXCLUDED.posto_servico_id,
        updated_at = now();
    
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = v_dia_trabalho.posto_servico_id
      AND data = v_dia_trabalho.data
      AND (
        (v_dia_trabalho.colaborador_id IS NOT NULL AND colaborador_id = v_dia_trabalho.colaborador_id)
        OR (v_dia_trabalho.colaborador_id IS NULL AND colaborador_id IS NULL)
      );
  END IF;
  
  IF p_novo_status IN ('vago'::status_posto, 'vago_temporariamente'::status_posto) THEN
    IF v_dia_trabalho.colaborador_id IS NOT NULL THEN
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
        COALESCE(v_dia_trabalho.motivo_vago::text, 'Dia vago'),
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
      )
      VALUES (
        v_dia_trabalho.posto_servico_id,
        NULL,
        v_dia_trabalho.data,
        COALESCE(v_dia_trabalho.motivo_vago::text, 'Posto vago'),
        COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
      )
      ON CONFLICT (posto_servico_id, data)
      WHERE colaborador_id IS NULL
      DO NOTHING;
    END IF;
  END IF;
END;
$function$;