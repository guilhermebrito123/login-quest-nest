
-- Recriar a função bloquear_edicao_diaria_temporaria() 
-- para bloquear todos os campos exceto 'status' quando o status for um dos bloqueados
CREATE OR REPLACE FUNCTION public.bloquear_edicao_diaria_temporaria()
RETURNS TRIGGER AS $$
DECLARE
  status_bloqueados text[] := ARRAY['Confirmada', 'Aprovada', 'Lançada para pagamento', 'Paga', 'Cancelada', 'Reprovada'];
BEGIN
  -- Se o status antigo está na lista de bloqueados
  IF OLD.status = ANY(status_bloqueados) THEN
    -- Verificar se algum campo além do status foi alterado
    IF (
      OLD.aprovada_em IS DISTINCT FROM NEW.aprovada_em OR
      OLD.aprovada_para_pagamento_em IS DISTINCT FROM NEW.aprovada_para_pagamento_em OR
      OLD.aprovada_por IS DISTINCT FROM NEW.aprovada_por OR
      OLD.aprovado_para_pgto_por IS DISTINCT FROM NEW.aprovado_para_pgto_por OR
      OLD.cancelada_em IS DISTINCT FROM NEW.cancelada_em OR
      OLD.cancelada_por IS DISTINCT FROM NEW.cancelada_por OR
      OLD.cliente_id IS DISTINCT FROM NEW.cliente_id OR
      OLD.colaborador_ausente IS DISTINCT FROM NEW.colaborador_ausente OR
      OLD.colaborador_ausente_nome IS DISTINCT FROM NEW.colaborador_ausente_nome OR
      OLD.colaborador_demitido IS DISTINCT FROM NEW.colaborador_demitido OR
      OLD.colaborador_demitido_nome IS DISTINCT FROM NEW.colaborador_demitido_nome OR
      OLD.colaborador_falecido IS DISTINCT FROM NEW.colaborador_falecido OR
      OLD.confirmada_em IS DISTINCT FROM NEW.confirmada_em OR
      OLD.confirmada_por IS DISTINCT FROM NEW.confirmada_por OR
      OLD.criado_por IS DISTINCT FROM NEW.criado_por OR
      OLD.data_diaria IS DISTINCT FROM NEW.data_diaria OR
      OLD.demissao IS DISTINCT FROM NEW.demissao OR
      OLD.diarista_id IS DISTINCT FROM NEW.diarista_id OR
      OLD.horario_fim IS DISTINCT FROM NEW.horario_fim OR
      OLD.horario_inicio IS DISTINCT FROM NEW.horario_inicio OR
      OLD.intervalo IS DISTINCT FROM NEW.intervalo OR
      OLD.jornada_diaria IS DISTINCT FROM NEW.jornada_diaria OR
      OLD.lancada_em IS DISTINCT FROM NEW.lancada_em OR
      OLD.lancada_por IS DISTINCT FROM NEW.lancada_por OR
      OLD.licenca_nojo IS DISTINCT FROM NEW.licenca_nojo OR
      OLD.motivo_cancelamento IS DISTINCT FROM NEW.motivo_cancelamento OR
      OLD.motivo_reprovacao IS DISTINCT FROM NEW.motivo_reprovacao OR
      OLD.motivo_reprovacao_observacao IS DISTINCT FROM NEW.motivo_reprovacao_observacao OR
      OLD.motivo_vago IS DISTINCT FROM NEW.motivo_vago OR
      OLD.novo_posto IS DISTINCT FROM NEW.novo_posto OR
      OLD.observacao IS DISTINCT FROM NEW.observacao OR
      OLD.observacao_pagamento IS DISTINCT FROM NEW.observacao_pagamento OR
      OLD.ok_pagamento IS DISTINCT FROM NEW.ok_pagamento OR
      OLD.ok_pagamento_em IS DISTINCT FROM NEW.ok_pagamento_em OR
      OLD.ok_pagamento_por IS DISTINCT FROM NEW.ok_pagamento_por OR
      OLD.outros_motivos_reprovacao_pagamento IS DISTINCT FROM NEW.outros_motivos_reprovacao_pagamento OR
      OLD.paga_em IS DISTINCT FROM NEW.paga_em OR
      OLD.paga_por IS DISTINCT FROM NEW.paga_por OR
      OLD.posto_servico IS DISTINCT FROM NEW.posto_servico OR
      OLD.posto_servico_id IS DISTINCT FROM NEW.posto_servico_id OR
      OLD.reprovada_em IS DISTINCT FROM NEW.reprovada_em OR
      OLD.reprovada_por IS DISTINCT FROM NEW.reprovada_por OR
      OLD.unidade IS DISTINCT FROM NEW.unidade OR
      OLD.valor_diaria IS DISTINCT FROM NEW.valor_diaria
    ) THEN
      RAISE EXCEPTION 'Diária não pode ser editada quando o status é %. Apenas o campo status pode ser alterado. Para editar outros campos, o status deve ser ''Aguardando confirmacao''.', OLD.status;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Garantir que o trigger existe
DROP TRIGGER IF EXISTS bloquear_edicao_diaria_temporaria_trigger ON public.diarias_temporarias;
CREATE TRIGGER bloquear_edicao_diaria_temporaria_trigger
  BEFORE UPDATE ON public.diarias_temporarias
  FOR EACH ROW
  EXECUTE FUNCTION public.bloquear_edicao_diaria_temporaria();
