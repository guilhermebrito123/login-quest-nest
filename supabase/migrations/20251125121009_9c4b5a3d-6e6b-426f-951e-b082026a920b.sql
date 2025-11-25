-- Adicionar valor 'inativo' ao enum status_posto
ALTER TYPE status_posto ADD VALUE IF NOT EXISTS 'inativo';

-- Adicionar coluna ultimo_dia_atividade na tabela postos_servico
ALTER TABLE public.postos_servico 
ADD COLUMN IF NOT EXISTS ultimo_dia_atividade DATE;

-- Modificar função gerar_dias_trabalho_mes_corrente para considerar ultimo_dia_atividade
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
  v_hoje DATE;
  v_primeiro_dia DATE;
  v_data_limite DATE;
BEGIN
  v_hoje := (now() AT TIME ZONE 'America/Sao_Paulo')::DATE;
  v_primeiro_dia := COALESCE(NEW.primeiro_dia_atividade, v_hoje);
  v_mes_inicio := date_trunc('month', v_hoje::TIMESTAMP)::DATE;
  -- Gerar até o último dia do mês seguinte (2 meses futuros)
  v_mes_fim := (date_trunc('month', v_hoje::TIMESTAMP) + INTERVAL '2 months - 1 day')::DATE;
  v_mes_inicio := GREATEST(v_mes_inicio, v_hoje);
  
  -- Se ultimo_dia_atividade existe, limitar até essa data
  IF NEW.ultimo_dia_atividade IS NOT NULL THEN
    v_data_limite := NEW.ultimo_dia_atividade;
  ELSE
    v_data_limite := v_mes_fim;
  END IF;
  
  FOR v_data IN 
    SELECT data_trabalho 
    FROM public.calcular_dias_escala(
      NEW.escala,
      v_mes_inicio,
      LEAST(v_mes_fim, v_data_limite),
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

-- Criar função para gerenciar ultimo_dia_atividade
CREATE OR REPLACE FUNCTION public.gerenciar_ultimo_dia_atividade()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_hoje DATE;
  v_data DATE;
  v_mes_inicio DATE;
  v_mes_fim DATE;
  v_colaborador_id UUID;
BEGIN
  v_hoje := (now() AT TIME ZONE 'America/Sao_Paulo')::DATE;
  
  -- Se ultimo_dia_atividade foi adicionado (antes NULL, agora tem valor)
  IF OLD.ultimo_dia_atividade IS NULL AND NEW.ultimo_dia_atividade IS NOT NULL THEN
    -- Deletar todos os dias_trabalho posteriores a ultimo_dia_atividade
    DELETE FROM public.dias_trabalho
    WHERE posto_servico_id = NEW.id
      AND data > NEW.ultimo_dia_atividade;
    
    -- Deletar posto_dias_vagos posteriores
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.id
      AND data > NEW.ultimo_dia_atividade;
    
    -- Obter colaborador vinculado
    SELECT id INTO v_colaborador_id
    FROM public.colaboradores
    WHERE posto_servico_id = NEW.id
    LIMIT 1;
    
    -- Desvincular colaborador se houver
    IF v_colaborador_id IS NOT NULL THEN
      UPDATE public.colaboradores
      SET posto_servico_id = NULL,
          updated_at = now()
      WHERE id = v_colaborador_id;
    END IF;
    
    -- Marcar posto como inativo
    NEW.status := 'inativo'::status_posto;
  
  -- Se ultimo_dia_atividade foi removido (antes tinha valor, agora NULL)
  ELSIF OLD.ultimo_dia_atividade IS NOT NULL AND NEW.ultimo_dia_atividade IS NULL THEN
    -- Regenerar dias_trabalho a partir do dia seguinte ao antigo ultimo_dia_atividade
    v_mes_inicio := OLD.ultimo_dia_atividade + 1;
    v_mes_fim := (date_trunc('month', v_hoje::TIMESTAMP) + INTERVAL '2 months - 1 day')::DATE;
    
    -- Só gerar se ainda estivermos dentro do período futuro
    IF v_mes_inicio <= v_mes_fim THEN
      FOR v_data IN 
        SELECT data_trabalho 
        FROM public.calcular_dias_escala(
          NEW.escala,
          v_mes_inicio,
          v_mes_fim,
          NEW.dias_semana,
          COALESCE(NEW.primeiro_dia_atividade, v_hoje)
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
    END IF;
    
    -- Marcar posto como vago
    NEW.status := 'vago'::status_posto;
  
  -- Se ultimo_dia_atividade foi modificado (tinha valor e mudou para outro valor)
  ELSIF OLD.ultimo_dia_atividade IS NOT NULL AND NEW.ultimo_dia_atividade IS NOT NULL 
        AND OLD.ultimo_dia_atividade != NEW.ultimo_dia_atividade THEN
    
    -- Se novo valor é anterior ao antigo, deletar dias entre o novo e o antigo
    IF NEW.ultimo_dia_atividade < OLD.ultimo_dia_atividade THEN
      DELETE FROM public.dias_trabalho
      WHERE posto_servico_id = NEW.id
        AND data > NEW.ultimo_dia_atividade;
      
      DELETE FROM public.posto_dias_vagos
      WHERE posto_servico_id = NEW.id
        AND data > NEW.ultimo_dia_atividade;
    
    -- Se novo valor é posterior ao antigo, gerar dias entre o antigo e o novo
    ELSIF NEW.ultimo_dia_atividade > OLD.ultimo_dia_atividade THEN
      v_mes_inicio := OLD.ultimo_dia_atividade + 1;
      v_mes_fim := NEW.ultimo_dia_atividade;
      
      FOR v_data IN 
        SELECT data_trabalho 
        FROM public.calcular_dias_escala(
          NEW.escala,
          v_mes_inicio,
          v_mes_fim,
          NEW.dias_semana,
          COALESCE(NEW.primeiro_dia_atividade, v_hoje)
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
    END IF;
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Criar trigger para gerenciar ultimo_dia_atividade
DROP TRIGGER IF EXISTS trigger_gerenciar_ultimo_dia_atividade ON public.postos_servico;
CREATE TRIGGER trigger_gerenciar_ultimo_dia_atividade
  BEFORE UPDATE ON public.postos_servico
  FOR EACH ROW
  WHEN (OLD.ultimo_dia_atividade IS DISTINCT FROM NEW.ultimo_dia_atividade)
  EXECUTE FUNCTION public.gerenciar_ultimo_dia_atividade();