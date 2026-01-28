-- Trigger para reverter justificativa quando atestado é removido
CREATE OR REPLACE FUNCTION public.reverter_justificativa_ao_remover_atestado()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Detectar quando atestado_path muda de NOT NULL para NULL
  IF OLD.atestado_path IS NOT NULL AND NEW.atestado_path IS NULL THEN
    -- Setar configuração para bypass da trigger de bloqueio
    PERFORM set_config('app.rpc_call', 'reverter_justificativa', true);
    
    -- Reverter campos de justificativa na própria falta
    NEW.justificada_em := NULL;
    NEW.justificada_por := NULL;
    NEW.motivo := 'FALTA INJUSTIFICADA'::motivo_vago_type;
    NEW.updated_at := now();
    
    -- Reverter motivo_vago na diarias_temporarias correspondente
    UPDATE diarias_temporarias
    SET 
      motivo_vago = 'FALTA INJUSTIFICADA'::motivo_vago_type,
      updated_at = now()
    WHERE id = NEW.diaria_temporaria_id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Criar trigger BEFORE UPDATE para poder modificar NEW
DROP TRIGGER IF EXISTS trg_reverter_justificativa_ao_remover_atestado ON faltas_colaboradores_convenia;

CREATE TRIGGER trg_reverter_justificativa_ao_remover_atestado
  BEFORE UPDATE ON faltas_colaboradores_convenia
  FOR EACH ROW
  EXECUTE FUNCTION public.reverter_justificativa_ao_remover_atestado();

-- Atualizar a trigger de bloqueio para permitir reversão de justificativa
CREATE OR REPLACE FUNCTION public.bloquear_edicao_diaria_temporaria()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  status_bloqueados text[] := ARRAY['Confirmada', 'Aprovada', 'Lançada para pagamento', 'Paga', 'Cancelada', 'Reprovada'];
BEGIN
  -- Se estamos em uma chamada RPC de justificativa ou reversão, permitir a mudança de motivo_vago
  IF current_setting('app.rpc_call', true) IN ('justificar_falta', 'reverter_justificativa') THEN
    RETURN NEW;
  END IF;

  -- Se o status antigo está na lista de bloqueados E o status NÃO está mudando
  IF OLD.status::text = ANY(status_bloqueados) AND OLD.status IS NOT DISTINCT FROM NEW.status THEN
    -- Verificar se algum campo ESTRUTURAL foi alterado
    IF (
      OLD.cliente_id IS DISTINCT FROM NEW.cliente_id OR
      OLD.diarista_id IS DISTINCT FROM NEW.diarista_id OR
      OLD.unidade IS DISTINCT FROM NEW.unidade OR
      OLD.posto_servico IS DISTINCT FROM NEW.posto_servico OR
      OLD.posto_servico_id IS DISTINCT FROM NEW.posto_servico_id OR
      OLD.data_diaria IS DISTINCT FROM NEW.data_diaria OR
      OLD.horario_inicio IS DISTINCT FROM NEW.horario_inicio OR
      OLD.horario_fim IS DISTINCT FROM NEW.horario_fim OR
      OLD.intervalo IS DISTINCT FROM NEW.intervalo OR
      OLD.jornada_diaria IS DISTINCT FROM NEW.jornada_diaria OR
      OLD.valor_diaria IS DISTINCT FROM NEW.valor_diaria OR
      OLD.motivo_vago IS DISTINCT FROM NEW.motivo_vago OR
      OLD.novo_posto IS DISTINCT FROM NEW.novo_posto OR
      OLD.colaborador_ausente IS DISTINCT FROM NEW.colaborador_ausente OR
      OLD.colaborador_ausente_nome IS DISTINCT FROM NEW.colaborador_ausente_nome OR
      OLD.colaborador_demitido IS DISTINCT FROM NEW.colaborador_demitido OR
      OLD.colaborador_demitido_nome IS DISTINCT FROM NEW.colaborador_demitido_nome OR
      OLD.demissao IS DISTINCT FROM NEW.demissao OR
      OLD.observacao IS DISTINCT FROM NEW.observacao
    ) THEN
      RAISE EXCEPTION 'Campos estruturais da diária não podem ser editados quando o status é %. Para editar esses campos, o status deve ser ''Aguardando confirmacao''.', OLD.status;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;