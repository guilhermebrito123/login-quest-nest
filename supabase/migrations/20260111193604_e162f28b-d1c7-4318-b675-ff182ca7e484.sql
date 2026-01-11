
-- Recriar a função bloquear_edicao_diaria_temporaria() 
-- para bloquear apenas campos ESTRUTURAIS quando status não for "Aguardando confirmacao"
CREATE OR REPLACE FUNCTION public.bloquear_edicao_diaria_temporaria()
RETURNS TRIGGER AS $$
DECLARE
  status_bloqueados text[] := ARRAY['Confirmada', 'Aprovada', 'Lançada para pagamento', 'Paga', 'Cancelada', 'Reprovada'];
BEGIN
  -- Se o status antigo está na lista de bloqueados
  IF OLD.status = ANY(status_bloqueados) THEN
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
      OLD.colaborador_falecido IS DISTINCT FROM NEW.colaborador_falecido OR
      
      -- Flags de contexto da vaga
      OLD.demissao IS DISTINCT FROM NEW.demissao OR
      OLD.licenca_nojo IS DISTINCT FROM NEW.licenca_nojo OR
      
      -- Observação geral
      OLD.observacao IS DISTINCT FROM NEW.observacao
    ) THEN
      RAISE EXCEPTION 'Campos estruturais da diária não podem ser editados quando o status é %. Para editar esses campos, o status deve ser ''Aguardando confirmacao''.', OLD.status;
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
