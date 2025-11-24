-- Atualizar função sync_dias_vagos
CREATE OR REPLACE FUNCTION public.sync_dias_vagos()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.status = 'vago'::status_posto AND (OLD IS NULL OR OLD.status != 'vago'::status_posto) THEN
    -- Se tem colaborador, usa índice com colaborador
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
      -- Se não tem colaborador, usa índice sem colaborador
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
        COALESCE(
          NEW.motivo_vago::text,
          (SELECT 'Posto vago' FROM public.postos_servico WHERE id = NEW.posto_servico_id AND status = 'vago'::status_posto),
          'Dia vago'
        ),
        COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
      )
      ON CONFLICT (posto_servico_id, data) 
      WHERE colaborador_id IS NULL
      DO NOTHING;
    END IF;
  
  ELSIF NEW.status = 'ocupado'::status_posto AND OLD.status = 'vago'::status_posto THEN
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.posto_servico_id
      AND data = NEW.data
      AND (
        (NEW.colaborador_id IS NOT NULL AND colaborador_id = NEW.colaborador_id)
        OR (NEW.colaborador_id IS NULL AND colaborador_id IS NULL)
      );
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Atualizar função gerar_dias_trabalho_mes_corrente
CREATE OR REPLACE FUNCTION public.gerar_dias_trabalho_mes_corrente()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_data DATE;
  v_mes_inicio DATE;
  v_mes_fim DATE;
  v_hoje DATE;
  v_primeiro_dia DATE;
BEGIN
  v_hoje := (now() AT TIME ZONE 'America/Sao_Paulo')::DATE;
  v_primeiro_dia := COALESCE(NEW.primeiro_dia_atividade, v_hoje);
  v_mes_inicio := date_trunc('month', v_hoje::TIMESTAMP)::DATE;
  v_mes_fim := (date_trunc('month', v_hoje::TIMESTAMP) + INTERVAL '1 month - 1 day')::DATE;
  v_mes_inicio := GREATEST(v_mes_inicio, v_hoje);
  
  FOR v_data IN 
    SELECT data_trabalho 
    FROM public.calcular_dias_escala(
      NEW.escala,
      v_mes_inicio,
      v_mes_fim,
      NEW.dias_semana,
      v_primeiro_dia
    )
  LOOP
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
    
    INSERT INTO public.posto_dias_vagos (
      posto_servico_id,
      colaborador_id,
      data,
      motivo,
      created_by
    ) VALUES (
      NEW.id,
      NULL,
      v_data,
      'Posto vago',
      COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
    )
    ON CONFLICT (posto_servico_id, data) 
    WHERE colaborador_id IS NULL
    DO NOTHING;
  END LOOP;
  
  RETURN NEW;
END;
$function$;

-- Atualizar função atribuir_dias_trabalho_colaborador
CREATE OR REPLACE FUNCTION public.atribuir_dias_trabalho_colaborador()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.posto_servico_id IS NOT NULL AND (TG_OP = 'INSERT' OR OLD.posto_servico_id IS DISTINCT FROM NEW.posto_servico_id) THEN
    
    IF TG_OP = 'UPDATE' AND OLD.posto_servico_id IS NOT NULL THEN
      UPDATE public.dias_trabalho
      SET colaborador_id = NULL,
          status = 'vago'::status_posto,
          motivo_vago = 'Posto vago'::motivo_vago_type
      WHERE posto_servico_id = OLD.posto_servico_id
        AND colaborador_id = NEW.id
        AND data >= CURRENT_DATE;
      
      INSERT INTO public.posto_dias_vagos (
        posto_servico_id,
        colaborador_id,
        data,
        motivo,
        created_by
      )
      SELECT 
        OLD.posto_servico_id,
        NULL,
        data,
        'Posto vago',
        COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
      FROM public.dias_trabalho
      WHERE posto_servico_id = OLD.posto_servico_id
        AND colaborador_id IS NULL
        AND data >= CURRENT_DATE
      ON CONFLICT (posto_servico_id, data) 
      WHERE colaborador_id IS NULL
      DO NOTHING;
    END IF;
    
    UPDATE public.dias_trabalho
    SET colaborador_id = NEW.id,
        status = 'ocupado'::status_posto,
        motivo_vago = NULL
    WHERE posto_servico_id = NEW.posto_servico_id
      AND data >= CURRENT_DATE
      AND colaborador_id IS NULL;
    
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.posto_servico_id
      AND data >= CURRENT_DATE;
  
  ELSIF NEW.posto_servico_id IS NULL AND TG_OP = 'UPDATE' AND OLD.posto_servico_id IS NOT NULL THEN
    RETURN NEW;
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Atualizar função confirmar_presenca
CREATE OR REPLACE FUNCTION public.confirmar_presenca(p_dia_trabalho_id UUID, p_novo_status status_posto)
RETURNS VOID
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
    
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = v_dia_trabalho.posto_servico_id
      AND data = v_dia_trabalho.data
      AND (
        (v_dia_trabalho.colaborador_id IS NOT NULL AND colaborador_id = v_dia_trabalho.colaborador_id)
        OR (v_dia_trabalho.colaborador_id IS NULL AND colaborador_id IS NULL)
      );
  END IF;
  
  IF p_novo_status IN ('vago'::status_posto, 'vago_temporariamente'::status_posto) THEN
    -- Se tem colaborador específico
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
      -- Posto inteiro vago
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