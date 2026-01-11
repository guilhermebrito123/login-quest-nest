
-- Ajustar o trigger bloquear_edicao_diaria_temporaria para ignorar 
-- mudanças automáticas em campos quando o status está sendo alterado
CREATE OR REPLACE FUNCTION public.bloquear_edicao_diaria_temporaria()
RETURNS TRIGGER AS $$
DECLARE
  status_bloqueados text[] := ARRAY['Confirmada', 'Aprovada', 'Lançada para pagamento', 'Paga', 'Cancelada', 'Reprovada'];
BEGIN
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
