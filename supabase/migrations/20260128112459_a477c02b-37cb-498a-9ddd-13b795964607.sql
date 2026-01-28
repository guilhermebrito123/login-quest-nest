-- Corrigir ciclo de triggers: verificar se já estamos em contexto de reversão
-- antes de sincronizar faltas de volta

-- Atualizar a trigger de sincronização para evitar ciclo
CREATE OR REPLACE FUNCTION public.sync_falta_colaborador_convenia()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- IMPORTANTE: Evitar ciclo de triggers
  -- Se estamos em contexto de reversão de justificativa, não sincronizar de volta
  IF current_setting('app.rpc_call', true) = 'reverter_justificativa' THEN
    RETURN NEW;
  END IF;

  -- Só processa se motivo_vago for um tipo de falta e colaborador_ausente_convenia estiver preenchido
  IF NEW.motivo_vago IN ('FALTA JUSTIFICADA', 'FALTA INJUSTIFICADA') 
     AND NEW.colaborador_ausente_convenia IS NOT NULL THEN
    
    -- UPSERT: criar ou atualizar registro de falta
    INSERT INTO faltas_colaboradores_convenia (
      colaborador_convenia_id,
      diaria_temporaria_id,
      data_falta,
      motivo
    ) VALUES (
      NEW.colaborador_ausente_convenia,
      NEW.id,
      NEW.data_diaria,
      NEW.motivo_vago
    )
    ON CONFLICT (diaria_temporaria_id) 
    DO UPDATE SET
      colaborador_convenia_id = EXCLUDED.colaborador_convenia_id,
      data_falta = EXCLUDED.data_falta,
      motivo = EXCLUDED.motivo,
      updated_at = now();
  END IF;
  
  RETURN NEW;
END;
$$;

-- Também atualizar a trigger de reversão para resetar o config após uso
CREATE OR REPLACE FUNCTION public.reverter_justificativa_ao_remover_atestado()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Detectar quando atestado_path muda de NOT NULL para NULL
  IF OLD.atestado_path IS NOT NULL AND NEW.atestado_path IS NULL THEN
    -- Setar configuração para bypass de ciclo de triggers
    PERFORM set_config('app.rpc_call', 'reverter_justificativa', true);
    
    -- Reverter campos de justificativa na própria falta
    NEW.justificada_em := NULL;
    NEW.justificada_por := NULL;
    NEW.motivo := 'FALTA INJUSTIFICADA'::motivo_vago_type;
    NEW.updated_at := now();
    
    -- Reverter motivo_vago na diarias_temporarias correspondente
    -- A trigger sync_falta_colaborador_convenia vai ignorar este UPDATE
    -- porque detectará o contexto 'reverter_justificativa'
    UPDATE diarias_temporarias
    SET 
      motivo_vago = 'FALTA INJUSTIFICADA'::motivo_vago_type,
      updated_at = now()
    WHERE id = NEW.diaria_temporaria_id;
  END IF;
  
  RETURN NEW;
END;
$$;