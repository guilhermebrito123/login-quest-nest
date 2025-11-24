-- Atualizar função calcular_dias_escala com regras corretas
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
  v_dias_desde_inicio INTEGER;
BEGIN
  -- Para escalas 5x2 e 6x1, usar dias_semana fixos
  IF p_escala IN ('5x2', '6x1') THEN
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
    
  -- Para escala 12x36: 1 dia trabalho + 1 dia folga (ciclo de 2 dias)
  ELSIF p_escala = '12x36' THEN
    v_data := GREATEST(p_data_inicio, p_primeiro_dia_atividade);
    v_dias_desde_inicio := (v_data - p_primeiro_dia_atividade);
    
    WHILE v_data <= p_data_fim LOOP
      -- Trabalha em dias pares (0, 2, 4...) desde primeiro_dia_atividade
      IF v_dias_desde_inicio % 2 = 0 THEN
        RETURN QUERY SELECT v_data;
      END IF;
      
      v_data := v_data + 1;
      v_dias_desde_inicio := v_dias_desde_inicio + 1;
    END LOOP;
    
  -- Para escala 18x36: 1 dia trabalho + 1 dia folga (ciclo de 2 dias)
  ELSIF p_escala = '18x36' THEN
    v_data := GREATEST(p_data_inicio, p_primeiro_dia_atividade);
    v_dias_desde_inicio := (v_data - p_primeiro_dia_atividade);
    
    WHILE v_data <= p_data_fim LOOP
      -- Trabalha em dias pares (0, 2, 4...) desde primeiro_dia_atividade
      IF v_dias_desde_inicio % 2 = 0 THEN
        RETURN QUERY SELECT v_data;
      END IF;
      
      v_data := v_data + 1;
      v_dias_desde_inicio := v_dias_desde_inicio + 1;
    END LOOP;
    
  -- Para escala 24x48: 1 dia trabalho + 2 dias folga (ciclo de 3 dias)
  ELSIF p_escala = '24x48' THEN
    v_data := GREATEST(p_data_inicio, p_primeiro_dia_atividade);
    v_dias_desde_inicio := (v_data - p_primeiro_dia_atividade);
    
    WHILE v_data <= p_data_fim LOOP
      -- Trabalha no primeiro dia de cada ciclo de 3 dias
      IF v_dias_desde_inicio % 3 = 0 THEN
        RETURN QUERY SELECT v_data;
      END IF;
      
      v_data := v_data + 1;
      v_dias_desde_inicio := v_dias_desde_inicio + 1;
    END LOOP;
    
  -- Para outras escalas customizadas (NxM): N dias consecutivos de trabalho + M dias consecutivos de folga
  ELSE
    BEGIN
      v_dias_trabalho := SPLIT_PART(p_escala, 'x', 1)::INTEGER;
      v_dias_folga := SPLIT_PART(p_escala, 'x', 2)::INTEGER;
      
      v_data := GREATEST(p_data_inicio, p_primeiro_dia_atividade);
      v_dias_desde_inicio := (v_data - p_primeiro_dia_atividade);
      
      -- Ajustar contador para começar no ponto correto do ciclo
      v_contador_dias := v_dias_desde_inicio % (v_dias_trabalho + v_dias_folga);
      
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

-- Atualizar trigger de validação: dias_semana obrigatório apenas para 5x2 e 6x1
CREATE OR REPLACE FUNCTION public.validar_dias_semana_escala()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- Para escalas 5x2 e 6x1, dias_semana é obrigatório
  IF NEW.escala IN ('5x2', '6x1') AND NEW.dias_semana IS NULL THEN
    RAISE EXCEPTION 'Para escalas 5x2 e 6x1, o campo dias_semana é obrigatório';
  END IF;
  
  -- Para outras escalas, dias_semana deve ser NULL
  IF NEW.escala NOT IN ('5x2', '6x1') AND NEW.dias_semana IS NOT NULL THEN
    RAISE EXCEPTION 'O campo dias_semana deve ser NULL para escalas que não sejam 5x2 ou 6x1';
  END IF;
  
  RETURN NEW;
END;
$$;