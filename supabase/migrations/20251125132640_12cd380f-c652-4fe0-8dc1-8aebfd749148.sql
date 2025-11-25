-- Atualizar função para deletar presencas quando ultimo_dia_atividade é editado
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
  v_status_dia status_posto;
BEGIN
  v_hoje := (now() AT TIME ZONE 'America/Sao_Paulo')::DATE;
  
  -- Obter colaborador vinculado ao posto
  SELECT id INTO v_colaborador_id
  FROM public.colaboradores
  WHERE posto_servico_id = NEW.id
  AND status = 'ativo'
  LIMIT 1;
  
  -- Determinar status baseado na existência de colaborador
  IF v_colaborador_id IS NOT NULL THEN
    v_status_dia := 'ocupado'::status_posto;
  ELSE
    v_status_dia := 'vago'::status_posto;
  END IF;
  
  -- Se ultimo_dia_atividade foi adicionado (antes NULL, agora tem valor)
  IF OLD.ultimo_dia_atividade IS NULL AND NEW.ultimo_dia_atividade IS NOT NULL THEN
    -- Deletar presencas posteriores a ultimo_dia_atividade
    DELETE FROM public.presencas
    WHERE posto_servico_id = NEW.id
      AND data > NEW.ultimo_dia_atividade;
    
    -- Deletar todos os dias_trabalho posteriores a ultimo_dia_atividade
    DELETE FROM public.dias_trabalho
    WHERE posto_servico_id = NEW.id
      AND data > NEW.ultimo_dia_atividade;
    
    -- Deletar posto_dias_vagos posteriores
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.id
      AND data > NEW.ultimo_dia_atividade;
    
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
          colaborador_id,
          status
        ) VALUES (
          NEW.id,
          v_data,
          NEW.horario_inicio,
          NEW.horario_fim,
          NEW.intervalo_refeicao,
          v_colaborador_id,
          v_status_dia
        )
        ON CONFLICT ON CONSTRAINT dias_trabalho_posto_data_colaborador_unique DO NOTHING;
        
        -- Só inserir em posto_dias_vagos se não houver colaborador
        IF v_colaborador_id IS NULL THEN
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
        END IF;
      END LOOP;
    END IF;
    
    -- Marcar posto como vago ou ocupado baseado em colaborador
    IF v_colaborador_id IS NOT NULL THEN
      NEW.status := 'ocupado'::status_posto;
    ELSE
      NEW.status := 'vago'::status_posto;
    END IF;
  
  -- Se ultimo_dia_atividade foi modificado (tinha valor e mudou para outro valor)
  ELSIF OLD.ultimo_dia_atividade IS NOT NULL AND NEW.ultimo_dia_atividade IS NOT NULL 
        AND OLD.ultimo_dia_atividade != NEW.ultimo_dia_atividade THEN
    
    -- Se novo valor é anterior ao antigo, deletar dias entre o novo e o antigo
    IF NEW.ultimo_dia_atividade < OLD.ultimo_dia_atividade THEN
      -- Deletar presencas posteriores ao novo ultimo_dia_atividade
      DELETE FROM public.presencas
      WHERE posto_servico_id = NEW.id
        AND data > NEW.ultimo_dia_atividade;
      
      DELETE FROM public.dias_trabalho
      WHERE posto_servico_id = NEW.id
        AND data > NEW.ultimo_dia_atividade;
      
      DELETE FROM public.posto_dias_vagos
      WHERE posto_servico_id = NEW.id
        AND data > NEW.ultimo_dia_atividade;
    
    -- Se novo valor é posterior ao antigo, primeiro deletar dias além do novo limite
    -- e depois gerar dias entre o antigo e o novo
    ELSIF NEW.ultimo_dia_atividade > OLD.ultimo_dia_atividade THEN
      -- Deletar presencas além do novo ultimo_dia_atividade (caso existam)
      DELETE FROM public.presencas
      WHERE posto_servico_id = NEW.id
        AND data > NEW.ultimo_dia_atividade;
      
      -- Deletar dias além do novo ultimo_dia_atividade (caso existam)
      DELETE FROM public.dias_trabalho
      WHERE posto_servico_id = NEW.id
        AND data > NEW.ultimo_dia_atividade;
      
      DELETE FROM public.posto_dias_vagos
      WHERE posto_servico_id = NEW.id
        AND data > NEW.ultimo_dia_atividade;
      
      -- Gerar dias entre o antigo e o novo ultimo_dia_atividade
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
          colaborador_id,
          status
        ) VALUES (
          NEW.id,
          v_data,
          NEW.horario_inicio,
          NEW.horario_fim,
          NEW.intervalo_refeicao,
          v_colaborador_id,
          v_status_dia
        )
        ON CONFLICT ON CONSTRAINT dias_trabalho_posto_data_colaborador_unique DO NOTHING;
        
        -- Só inserir em posto_dias_vagos se não houver colaborador
        IF v_colaborador_id IS NULL THEN
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
        END IF;
      END LOOP;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$function$;