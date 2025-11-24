-- Adicionar novo valor ao enum status_posto
ALTER TYPE status_posto ADD VALUE IF NOT EXISTS 'presenca_confirmada';

-- Criar função auxiliar para calcular dias trabalhados baseado na escala
CREATE OR REPLACE FUNCTION public.calcular_dias_escala(
  p_escala TEXT,
  p_data_inicio DATE,
  p_data_fim DATE,
  p_dias_semana INTEGER[],
  p_primeiro_dia_atividade DATE
)
RETURNS TABLE(data_trabalho DATE)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_data DATE;
  v_dia_semana INTEGER;
  v_contador_dias INTEGER := 0;
  v_dias_trabalho INTEGER;
  v_dias_folga INTEGER;
BEGIN
  -- Para escalas 12x36, gerar todos os dias considerando o padrão
  IF p_escala = '12x36' THEN
    v_data := GREATEST(p_data_inicio, p_primeiro_dia_atividade);
    
    -- Calcular quantos dias desde o primeiro_dia_atividade
    v_contador_dias := (v_data - p_primeiro_dia_atividade);
    
    WHILE v_data <= p_data_fim LOOP
      -- Trabalha em dias pares (0, 2, 4...) desde primeiro_dia_atividade
      IF v_contador_dias % 2 = 0 THEN
        RETURN QUERY SELECT v_data;
      END IF;
      
      v_data := v_data + 1;
      v_contador_dias := v_contador_dias + 1;
    END LOOP;
    
  -- Para escalas 5x2 e 6x1, usar dias_semana
  ELSIF p_escala IN ('5x2', '6x1') THEN
    FOR v_data IN SELECT generate_series(
      GREATEST(p_data_inicio, p_primeiro_dia_atividade),
      p_data_fim,
      '1 day'::INTERVAL
    )::DATE
    LOOP
      v_dia_semana := EXTRACT(DOW FROM v_data);
      
      IF p_dias_semana IS NOT NULL AND v_dia_semana = ANY(p_dias_semana) THEN
        RETURN QUERY SELECT v_data;
      END IF;
    END LOOP;
    
  -- Para outras escalas customizadas (NxM)
  ELSE
    -- Extrair N (dias trabalhados) e M (dias de folga) do formato "NxM"
    BEGIN
      v_dias_trabalho := SPLIT_PART(p_escala, 'x', 1)::INTEGER;
      v_dias_folga := SPLIT_PART(p_escala, 'x', 2)::INTEGER;
      
      v_data := GREATEST(p_data_inicio, p_primeiro_dia_atividade);
      v_contador_dias := 0;
      
      WHILE v_data <= p_data_fim LOOP
        -- Trabalha nos primeiros N dias do ciclo
        IF v_contador_dias < v_dias_trabalho THEN
          RETURN QUERY SELECT v_data;
        END IF;
        
        v_contador_dias := (v_contador_dias + 1) % (v_dias_trabalho + v_dias_folga);
        v_data := v_data + 1;
      END LOOP;
      
    EXCEPTION WHEN OTHERS THEN
      -- Se não conseguir parsear, não gera dias
      RETURN;
    END;
  END IF;
END;
$$;

-- Recriar função para gerar dias_trabalho do mês corrente com timezone brasileiro
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
  END LOOP;
  
  RETURN NEW;
END;
$$;

-- Criar função para gerar dias_trabalho do próximo mês (pode ser chamada manualmente ou via edge function)
CREATE OR REPLACE FUNCTION public.gerar_dias_trabalho_proximo_mes()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_posto RECORD;
  v_data DATE;
  v_proximo_mes_inicio DATE;
  v_proximo_mes_fim DATE;
  v_hoje DATE;
BEGIN
  -- Usar timezone brasileiro
  v_hoje := (now() AT TIME ZONE 'America/Sao_Paulo')::DATE;
  
  -- Calcular início e fim do próximo mês
  v_proximo_mes_inicio := (date_trunc('month', v_hoje::TIMESTAMP) + INTERVAL '1 month')::DATE;
  v_proximo_mes_fim := (date_trunc('month', v_hoje::TIMESTAMP) + INTERVAL '2 months - 1 day')::DATE;
  
  -- Para cada posto ativo, gerar dias do próximo mês
  FOR v_posto IN 
    SELECT id, escala, horario_inicio, horario_fim, intervalo_refeicao, 
           dias_semana, primeiro_dia_atividade
    FROM public.postos_servico
    WHERE status != 'vago'::status_posto OR status IS NULL
  LOOP
    -- Gerar dias de trabalho baseado na escala
    FOR v_data IN 
      SELECT data_trabalho 
      FROM public.calcular_dias_escala(
        v_posto.escala,
        v_proximo_mes_inicio,
        v_proximo_mes_fim,
        v_posto.dias_semana,
        COALESCE(v_posto.primeiro_dia_atividade, v_hoje)
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
        v_posto.id,
        v_data,
        v_posto.horario_inicio,
        v_posto.horario_fim,
        v_posto.intervalo_refeicao,
        'vago'::status_posto
      )
      ON CONFLICT ON CONSTRAINT dias_trabalho_posto_data_colaborador_unique DO NOTHING;
    END LOOP;
  END LOOP;
END;
$$;