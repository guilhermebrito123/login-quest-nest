-- Atualizar função para inserir em posto_dias_vagos quando posto estiver vago
CREATE OR REPLACE FUNCTION public.gerar_dias_trabalho_proximo_mes()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
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
  
  -- Para cada posto, gerar dias do próximo mês
  FOR v_posto IN 
    SELECT id, escala, horario_inicio, horario_fim, intervalo_refeicao, 
           dias_semana, primeiro_dia_atividade, status, ultimo_dia_atividade
    FROM public.postos_servico
    WHERE status != 'inativo'::status_posto
  LOOP
    -- Determinar data limite para gerar dias
    DECLARE
      v_data_limite DATE;
    BEGIN
      IF v_posto.ultimo_dia_atividade IS NOT NULL THEN
        v_data_limite := LEAST(v_proximo_mes_fim, v_posto.ultimo_dia_atividade);
      ELSE
        v_data_limite := v_proximo_mes_fim;
      END IF;
      
      -- Gerar dias de trabalho baseado na escala
      FOR v_data IN 
        SELECT data_trabalho 
        FROM public.calcular_dias_escala(
          v_posto.escala,
          v_proximo_mes_inicio,
          v_data_limite,
          v_posto.dias_semana,
          COALESCE(v_posto.primeiro_dia_atividade, v_hoje)
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
          v_posto.id,
          v_data,
          v_posto.horario_inicio,
          v_posto.horario_fim,
          v_posto.intervalo_refeicao,
          CASE 
            WHEN v_posto.status = 'vago'::status_posto THEN 'vago'::status_posto
            ELSE 'ocupado'::status_posto
          END
        )
        ON CONFLICT ON CONSTRAINT dias_trabalho_posto_data_colaborador_unique DO NOTHING;
        
        -- Se posto estiver vago, inserir em posto_dias_vagos
        IF v_posto.status = 'vago'::status_posto THEN
          INSERT INTO public.posto_dias_vagos (
            posto_servico_id,
            colaborador_id,
            data,
            motivo,
            created_by
          ) VALUES (
            v_posto.id,
            NULL,
            v_data,
            'Posto vago',
            '00000000-0000-0000-0000-000000000000'::uuid
          )
          ON CONFLICT (posto_servico_id, data) 
          WHERE colaborador_id IS NULL
          DO NOTHING;
        END IF;
      END LOOP;
    END;
  END LOOP;
END;
$function$;