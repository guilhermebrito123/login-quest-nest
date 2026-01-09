-- Recreate the log function without the deleted columns pix_alternativo and beneficiario_alternativo
CREATE OR REPLACE FUNCTION public.log_diaria_temporaria_changes()
RETURNS TRIGGER AS $$
DECLARE
  usuario_id uuid;
BEGIN
  -- Obter o usuário atual
  usuario_id := auth.uid();
  
  -- Para INSERT, registrar que o registro foi criado
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
    VALUES (NEW.id, 'registro_criado', 'INSERT', NULL, 'Registro criado', usuario_id, now());
    RETURN NEW;
  END IF;
  
  -- Para UPDATE, verificar cada campo individualmente
  IF TG_OP = 'UPDATE' THEN
    -- Campo: id
    IF OLD.id IS DISTINCT FROM NEW.id THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'id', 'UPDATE', OLD.id::text, NEW.id::text, usuario_id, now());
    END IF;
    
    -- Campo: valor_diaria
    IF OLD.valor_diaria IS DISTINCT FROM NEW.valor_diaria THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'valor_diaria', 'UPDATE', OLD.valor_diaria::text, NEW.valor_diaria::text, usuario_id, now());
    END IF;
    
    -- Campo: diarista_id
    IF OLD.diarista_id IS DISTINCT FROM NEW.diarista_id THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'diarista_id', 'UPDATE', OLD.diarista_id::text, NEW.diarista_id::text, usuario_id, now());
    END IF;
    
    -- Campo: status
    IF OLD.status IS DISTINCT FROM NEW.status THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'status', 'UPDATE', OLD.status::text, NEW.status::text, usuario_id, now());
    END IF;
    
    -- Campo: data_diaria
    IF OLD.data_diaria IS DISTINCT FROM NEW.data_diaria THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'data_diaria', 'UPDATE', OLD.data_diaria::text, NEW.data_diaria::text, usuario_id, now());
    END IF;
    
    -- Campo: posto_servico_id
    IF OLD.posto_servico_id IS DISTINCT FROM NEW.posto_servico_id THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'posto_servico_id', 'UPDATE', OLD.posto_servico_id::text, NEW.posto_servico_id::text, usuario_id, now());
    END IF;
    
    -- Campo: cliente_id
    IF OLD.cliente_id IS DISTINCT FROM NEW.cliente_id THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'cliente_id', 'UPDATE', OLD.cliente_id::text, NEW.cliente_id::text, usuario_id, now());
    END IF;
    
    -- Campo: colaborador_ausente
    IF OLD.colaborador_ausente IS DISTINCT FROM NEW.colaborador_ausente THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'colaborador_ausente', 'UPDATE', OLD.colaborador_ausente::text, NEW.colaborador_ausente::text, usuario_id, now());
    END IF;
    
    -- Campo: colaborador_ausente_nome
    IF OLD.colaborador_ausente_nome IS DISTINCT FROM NEW.colaborador_ausente_nome THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'colaborador_ausente_nome', 'UPDATE', OLD.colaborador_ausente_nome, NEW.colaborador_ausente_nome, usuario_id, now());
    END IF;
    
    -- Campo: colaborador_demitido
    IF OLD.colaborador_demitido IS DISTINCT FROM NEW.colaborador_demitido THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'colaborador_demitido', 'UPDATE', OLD.colaborador_demitido::text, NEW.colaborador_demitido::text, usuario_id, now());
    END IF;
    
    -- Campo: colaborador_demitido_nome
    IF OLD.colaborador_demitido_nome IS DISTINCT FROM NEW.colaborador_demitido_nome THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'colaborador_demitido_nome', 'UPDATE', OLD.colaborador_demitido_nome, NEW.colaborador_demitido_nome, usuario_id, now());
    END IF;
    
    -- Campo: colaborador_falecido
    IF OLD.colaborador_falecido IS DISTINCT FROM NEW.colaborador_falecido THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'colaborador_falecido', 'UPDATE', OLD.colaborador_falecido, NEW.colaborador_falecido, usuario_id, now());
    END IF;
    
    -- Campo: motivo_vago
    IF OLD.motivo_vago IS DISTINCT FROM NEW.motivo_vago THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'motivo_vago', 'UPDATE', OLD.motivo_vago::text, NEW.motivo_vago::text, usuario_id, now());
    END IF;
    
    -- Campo: motivo_reprovacao
    IF OLD.motivo_reprovacao IS DISTINCT FROM NEW.motivo_reprovacao THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'motivo_reprovacao', 'UPDATE', OLD.motivo_reprovacao::text, NEW.motivo_reprovacao::text, usuario_id, now());
    END IF;
    
    -- Campo: motivo_reprovacao_observacao
    IF OLD.motivo_reprovacao_observacao IS DISTINCT FROM NEW.motivo_reprovacao_observacao THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'motivo_reprovacao_observacao', 'UPDATE', OLD.motivo_reprovacao_observacao, NEW.motivo_reprovacao_observacao, usuario_id, now());
    END IF;
    
    -- Campo: motivo_cancelamento
    IF OLD.motivo_cancelamento IS DISTINCT FROM NEW.motivo_cancelamento THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'motivo_cancelamento', 'UPDATE', OLD.motivo_cancelamento, NEW.motivo_cancelamento, usuario_id, now());
    END IF;
    
    -- Campo: unidade (NOT NULL)
    IF OLD.unidade IS DISTINCT FROM NEW.unidade THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'unidade', 'UPDATE', OLD.unidade, NEW.unidade, usuario_id, now());
    END IF;
    
    -- Campo: posto_servico
    IF OLD.posto_servico IS DISTINCT FROM NEW.posto_servico THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'posto_servico', 'UPDATE', OLD.posto_servico, NEW.posto_servico, usuario_id, now());
    END IF;
    
    -- Campo: observacao
    IF OLD.observacao IS DISTINCT FROM NEW.observacao THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'observacao', 'UPDATE', OLD.observacao, NEW.observacao, usuario_id, now());
    END IF;
    
    -- Campo: horario_inicio
    IF OLD.horario_inicio IS DISTINCT FROM NEW.horario_inicio THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'horario_inicio', 'UPDATE', OLD.horario_inicio::text, NEW.horario_inicio::text, usuario_id, now());
    END IF;
    
    -- Campo: horario_fim
    IF OLD.horario_fim IS DISTINCT FROM NEW.horario_fim THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'horario_fim', 'UPDATE', OLD.horario_fim::text, NEW.horario_fim::text, usuario_id, now());
    END IF;
    
    -- Campo: intervalo
    IF OLD.intervalo IS DISTINCT FROM NEW.intervalo THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'intervalo', 'UPDATE', OLD.intervalo::text, NEW.intervalo::text, usuario_id, now());
    END IF;
    
    -- Campo: jornada_diaria
    IF OLD.jornada_diaria IS DISTINCT FROM NEW.jornada_diaria THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'jornada_diaria', 'UPDATE', OLD.jornada_diaria::text, NEW.jornada_diaria::text, usuario_id, now());
    END IF;
    
    -- Campo: demissao
    IF OLD.demissao IS DISTINCT FROM NEW.demissao THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'demissao', 'UPDATE', OLD.demissao::text, NEW.demissao::text, usuario_id, now());
    END IF;
    
    -- Campo: licenca_nojo
    IF OLD.licenca_nojo IS DISTINCT FROM NEW.licenca_nojo THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'licenca_nojo', 'UPDATE', OLD.licenca_nojo::text, NEW.licenca_nojo::text, usuario_id, now());
    END IF;
    
    -- Campo: novo_posto
    IF OLD.novo_posto IS DISTINCT FROM NEW.novo_posto THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'novo_posto', 'UPDATE', OLD.novo_posto::text, NEW.novo_posto::text, usuario_id, now());
    END IF;
    
    -- Campo: ok_pagamento
    IF OLD.ok_pagamento IS DISTINCT FROM NEW.ok_pagamento THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'ok_pagamento', 'UPDATE', OLD.ok_pagamento::text, NEW.ok_pagamento::text, usuario_id, now());
    END IF;
    
    -- Campo: observacao_pagamento
    IF OLD.observacao_pagamento IS DISTINCT FROM NEW.observacao_pagamento THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'observacao_pagamento', 'UPDATE', OLD.observacao_pagamento::text, NEW.observacao_pagamento::text, usuario_id, now());
    END IF;
    
    -- Campo: outros_motivos_reprovacao_pagamento
    IF OLD.outros_motivos_reprovacao_pagamento IS DISTINCT FROM NEW.outros_motivos_reprovacao_pagamento THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'outros_motivos_reprovacao_pagamento', 'UPDATE', OLD.outros_motivos_reprovacao_pagamento, NEW.outros_motivos_reprovacao_pagamento, usuario_id, now());
    END IF;
    
    -- Campos de auditoria (quem fez o que e quando)
    -- Campo: criado_por
    IF OLD.criado_por IS DISTINCT FROM NEW.criado_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'criado_por', 'UPDATE', OLD.criado_por::text, NEW.criado_por::text, usuario_id, now());
    END IF;
    
    -- Campo: confirmada_por
    IF OLD.confirmada_por IS DISTINCT FROM NEW.confirmada_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'confirmada_por', 'UPDATE', OLD.confirmada_por::text, NEW.confirmada_por::text, usuario_id, now());
    END IF;
    
    -- Campo: confirmada_em
    IF OLD.confirmada_em IS DISTINCT FROM NEW.confirmada_em THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'confirmada_em', 'UPDATE', OLD.confirmada_em::text, NEW.confirmada_em::text, usuario_id, now());
    END IF;
    
    -- Campo: aprovada_por
    IF OLD.aprovada_por IS DISTINCT FROM NEW.aprovada_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'aprovada_por', 'UPDATE', OLD.aprovada_por::text, NEW.aprovada_por::text, usuario_id, now());
    END IF;
    
    -- Campo: aprovada_em
    IF OLD.aprovada_em IS DISTINCT FROM NEW.aprovada_em THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'aprovada_em', 'UPDATE', OLD.aprovada_em::text, NEW.aprovada_em::text, usuario_id, now());
    END IF;
    
    -- Campo: lancada_por
    IF OLD.lancada_por IS DISTINCT FROM NEW.lancada_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'lancada_por', 'UPDATE', OLD.lancada_por::text, NEW.lancada_por::text, usuario_id, now());
    END IF;
    
    -- Campo: lancada_em
    IF OLD.lancada_em IS DISTINCT FROM NEW.lancada_em THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'lancada_em', 'UPDATE', OLD.lancada_em::text, NEW.lancada_em::text, usuario_id, now());
    END IF;
    
    -- Campo: aprovada_para_pagamento_em
    IF OLD.aprovada_para_pagamento_em IS DISTINCT FROM NEW.aprovada_para_pagamento_em THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'aprovada_para_pagamento_em', 'UPDATE', OLD.aprovada_para_pagamento_em::text, NEW.aprovada_para_pagamento_em::text, usuario_id, now());
    END IF;
    
    -- Campo: aprovado_para_pgto_por
    IF OLD.aprovado_para_pgto_por IS DISTINCT FROM NEW.aprovado_para_pgto_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'aprovado_para_pgto_por', 'UPDATE', OLD.aprovado_para_pgto_por::text, NEW.aprovado_para_pgto_por::text, usuario_id, now());
    END IF;
    
    -- Campo: paga_por
    IF OLD.paga_por IS DISTINCT FROM NEW.paga_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'paga_por', 'UPDATE', OLD.paga_por::text, NEW.paga_por::text, usuario_id, now());
    END IF;
    
    -- Campo: paga_em
    IF OLD.paga_em IS DISTINCT FROM NEW.paga_em THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'paga_em', 'UPDATE', OLD.paga_em::text, NEW.paga_em::text, usuario_id, now());
    END IF;
    
    -- Campo: cancelada_por
    IF OLD.cancelada_por IS DISTINCT FROM NEW.cancelada_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'cancelada_por', 'UPDATE', OLD.cancelada_por::text, NEW.cancelada_por::text, usuario_id, now());
    END IF;
    
    -- Campo: cancelada_em
    IF OLD.cancelada_em IS DISTINCT FROM NEW.cancelada_em THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'cancelada_em', 'UPDATE', OLD.cancelada_em::text, NEW.cancelada_em::text, usuario_id, now());
    END IF;
    
    -- Campo: reprovada_por
    IF OLD.reprovada_por IS DISTINCT FROM NEW.reprovada_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'reprovada_por', 'UPDATE', OLD.reprovada_por::text, NEW.reprovada_por::text, usuario_id, now());
    END IF;
    
    -- Campo: reprovada_em
    IF OLD.reprovada_em IS DISTINCT FROM NEW.reprovada_em THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'reprovada_em', 'UPDATE', OLD.reprovada_em::text, NEW.reprovada_em::text, usuario_id, now());
    END IF;
    
    -- Campo: ok_pagamento_por
    IF OLD.ok_pagamento_por IS DISTINCT FROM NEW.ok_pagamento_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'ok_pagamento_por', 'UPDATE', OLD.ok_pagamento_por::text, NEW.ok_pagamento_por::text, usuario_id, now());
    END IF;
    
    -- Campo: ok_pagamento_em
    IF OLD.ok_pagamento_em IS DISTINCT FROM NEW.ok_pagamento_em THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_id, campo, operacao, valor_antigo, valor_novo, usuario_responsavel, operacao_em)
      VALUES (NEW.id, 'ok_pagamento_em', 'UPDATE', OLD.ok_pagamento_em::text, NEW.ok_pagamento_em::text, usuario_id, now());
    END IF;
    
    RETURN NEW;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;