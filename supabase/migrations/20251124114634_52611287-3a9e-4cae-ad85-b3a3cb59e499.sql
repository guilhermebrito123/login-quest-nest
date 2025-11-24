-- Corrigir função calcular_dias_escala para incluir search_path
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