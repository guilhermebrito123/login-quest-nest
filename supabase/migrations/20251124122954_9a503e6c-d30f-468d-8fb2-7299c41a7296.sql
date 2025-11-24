-- Atualizar trigger de geração de dias_trabalho para também inserir em posto_dias_vagos
CREATE OR REPLACE FUNCTION public.gerar_dias_trabalho_mes_corrente()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_data DATE;
  v_mes_inicio DATE;
  v_mes_fim DATE;
  v_hoje DATE;
  v_primeiro_dia DATE;
BEGIN
  -- Usar timezone brasileiro para todas as operações
  v_hoje := (now() AT TIME ZONE 'America/Sao_Paulo')::DATE;
  
  -- Usar primeiro_dia_atividade ou hoje como referência
  v_primeiro_dia := COALESCE(NEW.primeiro_dia_atividade, v_hoje);
  
  -- Calcular início e fim do mês corrente no timezone brasileiro
  v_mes_inicio := date_trunc('month', v_hoje::TIMESTAMP)::DATE;
  v_mes_fim := (date_trunc('month', v_hoje::TIMESTAMP) + INTERVAL '1 month - 1 day')::DATE;
  
  -- Garantir que não geramos dias anteriores ao hoje
  v_mes_inicio := GREATEST(v_mes_inicio, v_hoje);
  
  -- Gerar dias de trabalho baseado na escala
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
    -- Inserir em dias_trabalho
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
    
    -- Inserir em posto_dias_vagos com motivo "Posto vago"
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
    ON CONFLICT ON CONSTRAINT posto_dias_vagos_unique_constraint DO NOTHING;
  END LOOP;
  
  RETURN NEW;
END;
$$;

-- Atualizar trigger de atribuição para remover de posto_dias_vagos
CREATE OR REPLACE FUNCTION public.atribuir_dias_trabalho_colaborador()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- Caso o colaborador tenha sido atribuído a um posto (INSERT ou UPDATE trocando de posto)
  IF NEW.posto_servico_id IS NOT NULL AND (TG_OP = 'INSERT' OR OLD.posto_servico_id IS DISTINCT FROM NEW.posto_servico_id) THEN
    
    -- Se está mudando de um posto antigo para um novo posto
    IF TG_OP = 'UPDATE' AND OLD.posto_servico_id IS NOT NULL THEN
      -- Reverter dias do posto antigo para "vago" e desvincular do colaborador
      UPDATE public.dias_trabalho
      SET colaborador_id = NULL,
          status = 'vago'::status_posto,
          motivo_vago = 'Posto vago'::motivo_vago_type
      WHERE posto_servico_id = OLD.posto_servico_id
        AND colaborador_id = NEW.id
        AND data >= CURRENT_DATE;
      
      -- Inserir dias vagos em posto_dias_vagos com motivo "Posto vago"
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
      ON CONFLICT ON CONSTRAINT posto_dias_vagos_unique_constraint
      DO NOTHING;
    END IF;
    
    -- Atualizar dias_trabalho do novo posto para ocupado e vincular ao colaborador
    UPDATE public.dias_trabalho
    SET colaborador_id = NEW.id,
        status = 'ocupado'::status_posto,
        motivo_vago = NULL
    WHERE posto_servico_id = NEW.posto_servico_id
      AND data >= CURRENT_DATE
      AND colaborador_id IS NULL;
    
    -- Remover dias vagos do novo posto em posto_dias_vagos
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.posto_servico_id
      AND data >= CURRENT_DATE;
  
  -- Caso o colaborador tenha sido removido de um posto (NEW.posto_servico_id IS NULL)
  ELSIF NEW.posto_servico_id IS NULL AND TG_OP = 'UPDATE' AND OLD.posto_servico_id IS NOT NULL THEN
    -- Não fazemos nada aqui: a função desvincular_colaborador_posto()
    -- (chamada pelo trigger correspondente) já trata este cenário
    RETURN NEW;
  END IF;
  
  RETURN NEW;
END;
$$;