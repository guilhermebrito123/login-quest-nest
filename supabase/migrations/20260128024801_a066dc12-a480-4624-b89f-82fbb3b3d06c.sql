-- 1. Atualizar a RPC para setar a configuração antes do UPDATE
CREATE OR REPLACE FUNCTION public.justificar_falta_convenia(
  p_diaria_temporaria_id bigint,
  p_atestado_path text,
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Validar que o atestado foi fornecido
  IF p_atestado_path IS NULL OR p_atestado_path = '' THEN
    RAISE EXCEPTION 'Atestado médico é obrigatório para justificar falta';
  END IF;

  -- Verificar se existe uma falta para essa diária
  IF NOT EXISTS (
    SELECT 1 FROM faltas_colaboradores_convenia 
    WHERE diaria_temporaria_id = p_diaria_temporaria_id
  ) THEN
    RAISE EXCEPTION 'Não existe registro de falta para esta diária';
  END IF;

  -- Setar configuração para indicar que estamos na RPC (permite bypass da trigger)
  PERFORM set_config('app.rpc_call', 'justificar_falta', true);

  -- Atualizar a falta para justificada
  UPDATE faltas_colaboradores_convenia
  SET 
    motivo = 'FALTA JUSTIFICADA'::motivo_vago_type,
    atestado_path = p_atestado_path,
    justificada_em = now(),
    justificada_por = p_user_id,
    updated_at = now()
  WHERE diaria_temporaria_id = p_diaria_temporaria_id;

  -- Atualizar o motivo_vago da diarias_temporarias para FALTA JUSTIFICADA
  UPDATE diarias_temporarias
  SET 
    motivo_vago = 'FALTA JUSTIFICADA'::motivo_vago_type,
    updated_at = now()
  WHERE id = p_diaria_temporaria_id;

END;
$$;

-- 2. Atualizar a trigger de bloqueio para permitir mudança de motivo_vago via RPC
CREATE OR REPLACE FUNCTION public.bloquear_edicao_diaria_temporaria()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  status_bloqueados text[] := ARRAY['Confirmada', 'Aprovada', 'Lançada para pagamento', 'Paga', 'Cancelada', 'Reprovada'];
BEGIN
  -- Se estamos em uma chamada RPC de justificativa, permitir a mudança de motivo_vago
  IF current_setting('app.rpc_call', true) = 'justificar_falta' THEN
    RETURN NEW;
  END IF;

  -- Se o status antigo está na lista de bloqueados E o status NÃO está mudando
  -- (se o status está mudando, permitimos as alterações automáticas dos outros triggers)
  IF OLD.status::text = ANY(status_bloqueados) AND OLD.status IS NOT DISTINCT FROM NEW.status THEN
    -- Verificar se algum campo ESTRUTURAL foi alterado (campos que definem a diária)
    IF (
      -- Identidade e vínculo
      OLD.cliente_id IS DISTINCT FROM NEW.cliente_id OR
      OLD.diarista_id IS DISTINCT FROM NEW.diarista_id OR
      OLD.unidade IS DISTINCT FROM NEW.unidade OR
      OLD.posto_servico IS DISTINCT FROM NEW.posto_servico OR
      OLD.posto_servico_id IS DISTINCT FROM NEW.posto_servico_id OR
      
      -- Datas e jornada
      OLD.data_diaria IS DISTINCT FROM NEW.data_diaria OR
      OLD.horario_inicio IS DISTINCT FROM NEW.horario_inicio OR
      OLD.horario_fim IS DISTINCT FROM NEW.horario_fim OR
      OLD.intervalo IS DISTINCT FROM NEW.intervalo OR
      OLD.jornada_diaria IS DISTINCT FROM NEW.jornada_diaria OR
      
      -- Valor
      OLD.valor_diaria IS DISTINCT FROM NEW.valor_diaria OR
      
      -- Motivo da vaga / contexto
      OLD.motivo_vago IS DISTINCT FROM NEW.motivo_vago OR
      OLD.novo_posto IS DISTINCT FROM NEW.novo_posto OR
      
      -- Situação do colaborador (causa da vaga)
      OLD.colaborador_ausente IS DISTINCT FROM NEW.colaborador_ausente OR
      OLD.colaborador_ausente_nome IS DISTINCT FROM NEW.colaborador_ausente_nome OR
      OLD.colaborador_demitido IS DISTINCT FROM NEW.colaborador_demitido OR
      OLD.colaborador_demitido_nome IS DISTINCT FROM NEW.colaborador_demitido_nome OR
      
      -- Flags de contexto da vaga
      OLD.demissao IS DISTINCT FROM NEW.demissao OR
      
      -- Observação geral
      OLD.observacao IS DISTINCT FROM NEW.observacao
    ) THEN
      RAISE EXCEPTION 'Campos estruturais da diária não podem ser editados quando o status é %. Para editar esses campos, o status deve ser ''Aguardando confirmacao''.', OLD.status;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;