-- Atualizar função para gerar dias_trabalho até o último dia do mês seguinte
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
  -- Gerar até o último dia do mês seguinte (2 meses futuros)
  v_mes_fim := (date_trunc('month', v_hoje::TIMESTAMP) + INTERVAL '2 months - 1 day')::DATE;
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