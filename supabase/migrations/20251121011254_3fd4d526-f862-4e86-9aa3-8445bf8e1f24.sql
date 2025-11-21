
-- Corrigir função gerar_dias_trabalho_mes_corrente para usar timezone brasileiro
CREATE OR REPLACE FUNCTION public.gerar_dias_trabalho_mes_corrente()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_data DATE;
  v_mes_inicio DATE;
  v_mes_fim DATE;
  v_dia_semana INTEGER;
  v_data_atual_brasil DATE;
BEGIN
  IF NEW.dias_semana IS NULL OR array_length(NEW.dias_semana, 1) IS NULL THEN
    RETURN NEW;
  END IF;
  
  -- Usar data atual no timezone brasileiro
  v_data_atual_brasil := (now() AT TIME ZONE 'America/Sao_Paulo')::DATE;
  
  -- Calcular início e fim do mês baseado no timezone brasileiro
  v_mes_inicio := date_trunc('month', v_data_atual_brasil::TIMESTAMP)::DATE;
  v_mes_fim := (date_trunc('month', v_data_atual_brasil::TIMESTAMP) + INTERVAL '1 month - 1 day')::DATE;
  
  FOR v_data IN SELECT generate_series(v_mes_inicio, v_mes_fim, '1 day'::INTERVAL)::DATE
  LOOP
    -- Extrair dia da semana (0=domingo, 1=segunda, etc.)
    v_dia_semana := EXTRACT(DOW FROM v_data);
    
    IF v_dia_semana = ANY(NEW.dias_semana) THEN
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
    END IF;
  END LOOP;
  
  RETURN NEW;
END;
$function$;
