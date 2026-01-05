-- Atualizar função de log para considerar TODOS os atributos da tabela diarias_temporarias
CREATE OR REPLACE FUNCTION public.log_diaria_temporaria_changes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_usuario_id uuid;
  v_old_value text;
  v_new_value text;
BEGIN
  -- Obter usuário atual
  v_usuario_id := auth.uid();
  
  -- Para INSERT, logar a criação
  IF TG_OP = 'INSERT' THEN
    INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
    VALUES (NEW.id, 'INSERT', 'registro', NULL, 'Registro criado', v_usuario_id);
    RETURN NEW;
  END IF;
  
  -- Para DELETE, logar a exclusão
  IF TG_OP = 'DELETE' THEN
    INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
    VALUES (OLD.id, 'DELETE', 'registro', 'Registro existente', 'Registro excluído', v_usuario_id);
    RETURN OLD;
  END IF;
  
  -- Para UPDATE, logar cada campo alterado
  IF TG_OP = 'UPDATE' THEN
    -- valor_diaria
    IF OLD.valor_diaria IS DISTINCT FROM NEW.valor_diaria THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'valor_diaria', OLD.valor_diaria::text, NEW.valor_diaria::text, v_usuario_id);
    END IF;
    
    -- diarista_id
    IF OLD.diarista_id IS DISTINCT FROM NEW.diarista_id THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'diarista_id', OLD.diarista_id::text, NEW.diarista_id::text, v_usuario_id);
    END IF;
    
    -- status
    IF OLD.status IS DISTINCT FROM NEW.status THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'status', OLD.status::text, NEW.status::text, v_usuario_id);
    END IF;
    
    -- data_diaria
    IF OLD.data_diaria IS DISTINCT FROM NEW.data_diaria THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'data_diaria', OLD.data_diaria::text, NEW.data_diaria::text, v_usuario_id);
    END IF;
    
    -- posto_servico_id
    IF OLD.posto_servico_id IS DISTINCT FROM NEW.posto_servico_id THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'posto_servico_id', OLD.posto_servico_id::text, NEW.posto_servico_id::text, v_usuario_id);
    END IF;
    
    -- colaborador_ausente
    IF OLD.colaborador_ausente IS DISTINCT FROM NEW.colaborador_ausente THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'colaborador_ausente', OLD.colaborador_ausente::text, NEW.colaborador_ausente::text, v_usuario_id);
    END IF;
    
    -- colaborador_ausente_nome
    IF OLD.colaborador_ausente_nome IS DISTINCT FROM NEW.colaborador_ausente_nome THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'colaborador_ausente_nome', OLD.colaborador_ausente_nome, NEW.colaborador_ausente_nome, v_usuario_id);
    END IF;
    
    -- motivo_reprovacao
    IF OLD.motivo_reprovacao IS DISTINCT FROM NEW.motivo_reprovacao THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'motivo_reprovacao', OLD.motivo_reprovacao::text, NEW.motivo_reprovacao::text, v_usuario_id);
    END IF;
    
    -- motivo_reprovacao_observacao
    IF OLD.motivo_reprovacao_observacao IS DISTINCT FROM NEW.motivo_reprovacao_observacao THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'motivo_reprovacao_observacao', OLD.motivo_reprovacao_observacao, NEW.motivo_reprovacao_observacao, v_usuario_id);
    END IF;
    
    -- motivo_cancelamento
    IF OLD.motivo_cancelamento IS DISTINCT FROM NEW.motivo_cancelamento THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'motivo_cancelamento', OLD.motivo_cancelamento, NEW.motivo_cancelamento, v_usuario_id);
    END IF;
    
    -- motivo_vago
    IF OLD.motivo_vago IS DISTINCT FROM NEW.motivo_vago THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'motivo_vago', OLD.motivo_vago::text, NEW.motivo_vago::text, v_usuario_id);
    END IF;
    
    -- horario_inicio
    IF OLD.horario_inicio IS DISTINCT FROM NEW.horario_inicio THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'horario_inicio', OLD.horario_inicio::text, NEW.horario_inicio::text, v_usuario_id);
    END IF;
    
    -- horario_fim
    IF OLD.horario_fim IS DISTINCT FROM NEW.horario_fim THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'horario_fim', OLD.horario_fim::text, NEW.horario_fim::text, v_usuario_id);
    END IF;
    
    -- intervalo
    IF OLD.intervalo IS DISTINCT FROM NEW.intervalo THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'intervalo', OLD.intervalo::text, NEW.intervalo::text, v_usuario_id);
    END IF;
    
    -- jornada_diaria
    IF OLD.jornada_diaria IS DISTINCT FROM NEW.jornada_diaria THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'jornada_diaria', OLD.jornada_diaria::text, NEW.jornada_diaria::text, v_usuario_id);
    END IF;
    
    -- demissao
    IF OLD.demissao IS DISTINCT FROM NEW.demissao THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'demissao', OLD.demissao::text, NEW.demissao::text, v_usuario_id);
    END IF;
    
    -- colaborador_demitido
    IF OLD.colaborador_demitido IS DISTINCT FROM NEW.colaborador_demitido THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'colaborador_demitido', OLD.colaborador_demitido::text, NEW.colaborador_demitido::text, v_usuario_id);
    END IF;
    
    -- colaborador_demitido_nome
    IF OLD.colaborador_demitido_nome IS DISTINCT FROM NEW.colaborador_demitido_nome THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'colaborador_demitido_nome', OLD.colaborador_demitido_nome, NEW.colaborador_demitido_nome, v_usuario_id);
    END IF;
    
    -- colaborador_falecido
    IF OLD.colaborador_falecido IS DISTINCT FROM NEW.colaborador_falecido THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'colaborador_falecido', OLD.colaborador_falecido, NEW.colaborador_falecido, v_usuario_id);
    END IF;
    
    -- cliente_id
    IF OLD.cliente_id IS DISTINCT FROM NEW.cliente_id THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'cliente_id', OLD.cliente_id::text, NEW.cliente_id::text, v_usuario_id);
    END IF;
    
    -- licenca_nojo
    IF OLD.licenca_nojo IS DISTINCT FROM NEW.licenca_nojo THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'licenca_nojo', OLD.licenca_nojo::text, NEW.licenca_nojo::text, v_usuario_id);
    END IF;
    
    -- novo_posto
    IF OLD.novo_posto IS DISTINCT FROM NEW.novo_posto THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'novo_posto', OLD.novo_posto::text, NEW.novo_posto::text, v_usuario_id);
    END IF;
    
    -- posto_servico
    IF OLD.posto_servico IS DISTINCT FROM NEW.posto_servico THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'posto_servico', OLD.posto_servico, NEW.posto_servico, v_usuario_id);
    END IF;
    
    -- unidade
    IF OLD.unidade IS DISTINCT FROM NEW.unidade THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'unidade', OLD.unidade, NEW.unidade, v_usuario_id);
    END IF;
    
    -- observacao
    IF OLD.observacao IS DISTINCT FROM NEW.observacao THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'observacao', OLD.observacao, NEW.observacao, v_usuario_id);
    END IF;
    
    -- pix_alternativo
    IF OLD.pix_alternativo IS DISTINCT FROM NEW.pix_alternativo THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'pix_alternativo', OLD.pix_alternativo, NEW.pix_alternativo, v_usuario_id);
    END IF;
    
    -- beneficiario_alternativo
    IF OLD.beneficiario_alternativo IS DISTINCT FROM NEW.beneficiario_alternativo THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'beneficiario_alternativo', OLD.beneficiario_alternativo, NEW.beneficiario_alternativo, v_usuario_id);
    END IF;
    
    -- ok_pagamento
    IF OLD.ok_pagamento IS DISTINCT FROM NEW.ok_pagamento THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'ok_pagamento', OLD.ok_pagamento::text, NEW.ok_pagamento::text, v_usuario_id);
    END IF;
    
    -- ok_pagamento_em
    IF OLD.ok_pagamento_em IS DISTINCT FROM NEW.ok_pagamento_em THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'ok_pagamento_em', OLD.ok_pagamento_em::text, NEW.ok_pagamento_em::text, v_usuario_id);
    END IF;
    
    -- ok_pagamento_por
    IF OLD.ok_pagamento_por IS DISTINCT FROM NEW.ok_pagamento_por THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'ok_pagamento_por', OLD.ok_pagamento_por::text, NEW.ok_pagamento_por::text, v_usuario_id);
    END IF;
    
    -- observacao_pagamento (array)
    IF OLD.observacao_pagamento IS DISTINCT FROM NEW.observacao_pagamento THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'observacao_pagamento', array_to_string(OLD.observacao_pagamento, ', '), array_to_string(NEW.observacao_pagamento, ', '), v_usuario_id);
    END IF;
    
    -- outros_motivos_reprovacao_pagamento
    IF OLD.outros_motivos_reprovacao_pagamento IS DISTINCT FROM NEW.outros_motivos_reprovacao_pagamento THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'outros_motivos_reprovacao_pagamento', OLD.outros_motivos_reprovacao_pagamento, NEW.outros_motivos_reprovacao_pagamento, v_usuario_id);
    END IF;
    
    -- criado_por
    IF OLD.criado_por IS DISTINCT FROM NEW.criado_por THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'criado_por', OLD.criado_por::text, NEW.criado_por::text, v_usuario_id);
    END IF;
    
    -- confirmada_por
    IF OLD.confirmada_por IS DISTINCT FROM NEW.confirmada_por THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'confirmada_por', OLD.confirmada_por::text, NEW.confirmada_por::text, v_usuario_id);
    END IF;
    
    -- confirmada_em
    IF OLD.confirmada_em IS DISTINCT FROM NEW.confirmada_em THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'confirmada_em', OLD.confirmada_em::text, NEW.confirmada_em::text, v_usuario_id);
    END IF;
    
    -- aprovada_por
    IF OLD.aprovada_por IS DISTINCT FROM NEW.aprovada_por THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'aprovada_por', OLD.aprovada_por::text, NEW.aprovada_por::text, v_usuario_id);
    END IF;
    
    -- aprovada_em
    IF OLD.aprovada_em IS DISTINCT FROM NEW.aprovada_em THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'aprovada_em', OLD.aprovada_em::text, NEW.aprovada_em::text, v_usuario_id);
    END IF;
    
    -- lancada_por
    IF OLD.lancada_por IS DISTINCT FROM NEW.lancada_por THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'lancada_por', OLD.lancada_por::text, NEW.lancada_por::text, v_usuario_id);
    END IF;
    
    -- lancada_em
    IF OLD.lancada_em IS DISTINCT FROM NEW.lancada_em THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'lancada_em', OLD.lancada_em::text, NEW.lancada_em::text, v_usuario_id);
    END IF;
    
    -- aprovado_para_pgto_por
    IF OLD.aprovado_para_pgto_por IS DISTINCT FROM NEW.aprovado_para_pgto_por THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'aprovado_para_pgto_por', OLD.aprovado_para_pgto_por::text, NEW.aprovado_para_pgto_por::text, v_usuario_id);
    END IF;
    
    -- aprovada_para_pagamento_em
    IF OLD.aprovada_para_pagamento_em IS DISTINCT FROM NEW.aprovada_para_pagamento_em THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'aprovada_para_pagamento_em', OLD.aprovada_para_pagamento_em::text, NEW.aprovada_para_pagamento_em::text, v_usuario_id);
    END IF;
    
    -- paga_por
    IF OLD.paga_por IS DISTINCT FROM NEW.paga_por THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'paga_por', OLD.paga_por::text, NEW.paga_por::text, v_usuario_id);
    END IF;
    
    -- paga_em
    IF OLD.paga_em IS DISTINCT FROM NEW.paga_em THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'paga_em', OLD.paga_em::text, NEW.paga_em::text, v_usuario_id);
    END IF;
    
    -- cancelada_por
    IF OLD.cancelada_por IS DISTINCT FROM NEW.cancelada_por THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'cancelada_por', OLD.cancelada_por::text, NEW.cancelada_por::text, v_usuario_id);
    END IF;
    
    -- cancelada_em
    IF OLD.cancelada_em IS DISTINCT FROM NEW.cancelada_em THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'cancelada_em', OLD.cancelada_em::text, NEW.cancelada_em::text, v_usuario_id);
    END IF;
    
    -- reprovada_por
    IF OLD.reprovada_por IS DISTINCT FROM NEW.reprovada_por THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'reprovada_por', OLD.reprovada_por::text, NEW.reprovada_por::text, v_usuario_id);
    END IF;
    
    -- reprovada_em
    IF OLD.reprovada_em IS DISTINCT FROM NEW.reprovada_em THEN
      INSERT INTO diarias_temporarias_logs (diaria_id, operacao, campo, valor_antigo, valor_novo, usuario_responsavel)
      VALUES (NEW.id, 'UPDATE', 'reprovada_em', OLD.reprovada_em::text, NEW.reprovada_em::text, v_usuario_id);
    END IF;
    
    RETURN NEW;
  END IF;
  
  RETURN NULL;
END;
$function$;