-- Atualizar o trigger para aceitar bypass genérico via app.rpc_call = 'true'
CREATE OR REPLACE FUNCTION public.bloquear_edicao_diaria_temporaria()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  status_bloqueados text[] := ARRAY['Confirmada', 'Aprovada', 'Lançada para pagamento', 'Paga', 'Cancelada', 'Reprovada'];
BEGIN
  -- Se estamos em uma chamada RPC autorizada, permitir a edição
  IF current_setting('app.rpc_call', true) IN ('true', 'justificar_falta', 'reverter_justificativa') THEN
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