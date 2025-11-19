-- Ajustar unicidade de dias_trabalho para funcionar com ON CONFLICT
DROP INDEX IF EXISTS public.dias_trabalho_posto_data_colaborador_unique;

ALTER TABLE public.dias_trabalho
DROP CONSTRAINT IF EXISTS dias_trabalho_posto_data_colaborador_unique;

ALTER TABLE public.dias_trabalho
ADD CONSTRAINT dias_trabalho_posto_data_colaborador_unique
EXCLUDE USING btree (
  posto_servico_id WITH =,
  data WITH =,
  (COALESCE(colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid)) WITH =
);

-- Atualizar função gerar_dias_trabalho_mes_corrente para usar a nova constraint
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
BEGIN
  -- Se não há dias_semana configurados, retornar
  IF NEW.dias_semana IS NULL OR array_length(NEW.dias_semana, 1) IS NULL THEN
    RETURN NEW;
  END IF;
  
  -- Definir início e fim do mês corrente
  v_mes_inicio := date_trunc('month', CURRENT_DATE)::DATE;
  v_mes_fim := (date_trunc('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE;
  
  -- Iterar pelos dias do mês
  FOR v_data IN SELECT generate_series(v_mes_inicio, v_mes_fim, '1 day'::INTERVAL)::DATE
  LOOP
    -- Obter dia da semana (0=domingo, 1=segunda, ..., 6=sábado)
    v_dia_semana := EXTRACT(DOW FROM v_data);
    
    -- Se o dia da semana está na lista dias_semana, inserir
    IF v_dia_semana = ANY(NEW.dias_semana) THEN
      INSERT INTO public.dias_trabalho (
        posto_servico_id,
        data,
        horario_inicio,
        horario_fim,
        intervalo_refeicao
      ) VALUES (
        NEW.id,
        v_data,
        NEW.horario_inicio,
        NEW.horario_fim,
        NEW.intervalo_refeicao
      )
      ON CONFLICT ON CONSTRAINT dias_trabalho_posto_data_colaborador_unique DO NOTHING;
    END IF;
  END LOOP;
  
  RETURN NEW;
END;
$function$;