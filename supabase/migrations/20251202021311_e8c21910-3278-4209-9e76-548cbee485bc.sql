-- Corrigir função confirmar_presenca para não apagar colaborador_id quando marcar dia como vago
-- O dia pode estar vago temporariamente (ausência), mas o colaborador ainda pertence ao posto

CREATE OR REPLACE FUNCTION public.confirmar_presenca(p_dia_trabalho_id uuid, p_novo_status status_posto)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_dia_trabalho RECORD;
BEGIN
  SELECT * INTO v_dia_trabalho
  FROM public.dias_trabalho
  WHERE id = p_dia_trabalho_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Dia de trabalho não encontrado';
  END IF;
  
  -- Atualizar status do dia_trabalho (mas NÃO limpar colaborador_id)
  UPDATE public.dias_trabalho
  SET status = p_novo_status,
      updated_at = now()
  WHERE id = p_dia_trabalho_id;
  
  -- Se status é presenca_confirmada, registrar presença
  IF p_novo_status = 'presenca_confirmada'::status_posto THEN
    INSERT INTO public.presencas (
      colaborador_id,
      posto_servico_id,
      data,
      horario_entrada,
      horario_saida,
      tipo,
      observacao,
      registrado_por
    )
    VALUES (
      v_dia_trabalho.colaborador_id,
      v_dia_trabalho.posto_servico_id,
      v_dia_trabalho.data,
      (v_dia_trabalho.data || ' ' || v_dia_trabalho.horario_inicio)::timestamp with time zone,
      (v_dia_trabalho.data || ' ' || v_dia_trabalho.horario_fim)::timestamp with time zone,
      'presente',
      'Presença confirmada automaticamente',
      COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
    )
    ON CONFLICT (colaborador_id, data) DO UPDATE
    SET horario_entrada = EXCLUDED.horario_entrada,
        horario_saida = EXCLUDED.horario_saida,
        tipo = EXCLUDED.tipo,
        observacao = EXCLUDED.observacao,
        posto_servico_id = EXCLUDED.posto_servico_id,
        updated_at = now();
    
    -- Remover dia de posto_dias_vagos quando presença confirmada
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = v_dia_trabalho.posto_servico_id
      AND data = v_dia_trabalho.data
      AND (
        (v_dia_trabalho.colaborador_id IS NOT NULL AND colaborador_id = v_dia_trabalho.colaborador_id)
        OR (v_dia_trabalho.colaborador_id IS NULL AND colaborador_id IS NULL)
      );
  END IF;
  
  -- Para status 'vago' ou 'vago_temporariamente', o trigger sync_dias_vagos cuidará de posto_dias_vagos
END;
$function$;

-- Revisar trigger sync_dias_vagos para NÃO apagar colaborador_id de dias_trabalho
-- Este trigger apenas gerencia posto_dias_vagos com base no status, não deve alterar dias_trabalho
CREATE OR REPLACE FUNCTION public.sync_dias_vagos()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Quando dia muda para vago: inserir em posto_dias_vagos
  IF NEW.status = 'vago'::status_posto AND (OLD IS NULL OR OLD.status != 'vago'::status_posto) THEN
    -- Verificar se já existe algum registro para este posto/data antes de inserir
    IF NOT EXISTS (
      SELECT 1 FROM public.posto_dias_vagos
      WHERE posto_servico_id = NEW.posto_servico_id
        AND data = NEW.data
    ) THEN
      -- Inserir registro baseado se há colaborador ou não
      IF NEW.colaborador_id IS NOT NULL THEN
        INSERT INTO public.posto_dias_vagos (
          posto_servico_id,
          colaborador_id,
          data,
          motivo,
          created_by
        ) VALUES (
          NEW.posto_servico_id,
          NEW.colaborador_id,
          NEW.data,
          COALESCE(NEW.motivo_vago::text, 'Dia vago'),
          COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
        )
        ON CONFLICT (posto_servico_id, data, colaborador_id)
        WHERE colaborador_id IS NOT NULL
        DO NOTHING;
      ELSE
        INSERT INTO public.posto_dias_vagos (
          posto_servico_id,
          colaborador_id,
          data,
          motivo,
          created_by
        ) VALUES (
          NEW.posto_servico_id,
          NULL,
          NEW.data,
          COALESCE(NEW.motivo_vago::text, 'Posto vago'),
          COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
        )
        ON CONFLICT (posto_servico_id, data)
        WHERE colaborador_id IS NULL
        DO NOTHING;
      END IF;
    END IF;
  
  -- Quando dia deixa de estar vago: remover de posto_dias_vagos
  ELSIF NEW.status = 'ocupado'::status_posto AND OLD.status = 'vago'::status_posto THEN
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.posto_servico_id
      AND data = NEW.data;
  END IF;
  
  RETURN NEW;
END;
$function$;