-- Recriar a função de log de alterações com TODOS os campos
CREATE OR REPLACE FUNCTION public.log_diaria_temporaria_changes()
RETURNS TRIGGER AS $$
BEGIN
  -- Registrar alterações campo a campo
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
    VALUES (NEW.id, 'registro_criado', NULL, 'Novo registro criado', auth.uid());
    
  ELSIF TG_OP = 'UPDATE' THEN
    -- Comparar cada campo e registrar mudanças
    
    IF OLD.valor_diaria IS DISTINCT FROM NEW.valor_diaria THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'valor_diaria', OLD.valor_diaria::text, NEW.valor_diaria::text, auth.uid());
    END IF;
    
    IF OLD.diarista_id IS DISTINCT FROM NEW.diarista_id THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'diarista_id', OLD.diarista_id::text, NEW.diarista_id::text, auth.uid());
    END IF;
    
    IF OLD.status IS DISTINCT FROM NEW.status THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'status', OLD.status::text, NEW.status::text, auth.uid());
    END IF;
    
    IF OLD.data_diaria IS DISTINCT FROM NEW.data_diaria THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'data_diaria', OLD.data_diaria::text, NEW.data_diaria::text, auth.uid());
    END IF;
    
    IF OLD.posto_servico_id IS DISTINCT FROM NEW.posto_servico_id THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'posto_servico_id', OLD.posto_servico_id::text, NEW.posto_servico_id::text, auth.uid());
    END IF;
    
    IF OLD.colaborador_ausente IS DISTINCT FROM NEW.colaborador_ausente THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'colaborador_ausente', OLD.colaborador_ausente::text, NEW.colaborador_ausente::text, auth.uid());
    END IF;
    
    IF OLD.motivo_cancelamento IS DISTINCT FROM NEW.motivo_cancelamento THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'motivo_cancelamento', OLD.motivo_cancelamento, NEW.motivo_cancelamento, auth.uid());
    END IF;
    
    IF OLD.motivo_reprovacao IS DISTINCT FROM NEW.motivo_reprovacao THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'motivo_reprovacao', OLD.motivo_reprovacao::text, NEW.motivo_reprovacao::text, auth.uid());
    END IF;
    
    IF OLD.motivo_vago IS DISTINCT FROM NEW.motivo_vago THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'motivo_vago', OLD.motivo_vago::text, NEW.motivo_vago::text, auth.uid());
    END IF;
    
    IF OLD.horario_inicio IS DISTINCT FROM NEW.horario_inicio THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'horario_inicio', OLD.horario_inicio::text, NEW.horario_inicio::text, auth.uid());
    END IF;
    
    IF OLD.horario_fim IS DISTINCT FROM NEW.horario_fim THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'horario_fim', OLD.horario_fim::text, NEW.horario_fim::text, auth.uid());
    END IF;
    
    IF OLD.intervalo IS DISTINCT FROM NEW.intervalo THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'intervalo', OLD.intervalo::text, NEW.intervalo::text, auth.uid());
    END IF;
    
    IF OLD.jornada_diaria IS DISTINCT FROM NEW.jornada_diaria THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'jornada_diaria', OLD.jornada_diaria::text, NEW.jornada_diaria::text, auth.uid());
    END IF;
    
    IF OLD.demissao IS DISTINCT FROM NEW.demissao THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'demissao', OLD.demissao::text, NEW.demissao::text, auth.uid());
    END IF;
    
    IF OLD.colaborador_demitido IS DISTINCT FROM NEW.colaborador_demitido THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'colaborador_demitido', OLD.colaborador_demitido::text, NEW.colaborador_demitido::text, auth.uid());
    END IF;
    
    IF OLD.colaborador_ausente_nome IS DISTINCT FROM NEW.colaborador_ausente_nome THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'colaborador_ausente_nome', OLD.colaborador_ausente_nome, NEW.colaborador_ausente_nome, auth.uid());
    END IF;
    
    IF OLD.posto_servico IS DISTINCT FROM NEW.posto_servico THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'posto_servico', OLD.posto_servico, NEW.posto_servico, auth.uid());
    END IF;
    
    IF OLD.colaborador_demitido_nome IS DISTINCT FROM NEW.colaborador_demitido_nome THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'colaborador_demitido_nome', OLD.colaborador_demitido_nome, NEW.colaborador_demitido_nome, auth.uid());
    END IF;
    
    IF OLD.observacao IS DISTINCT FROM NEW.observacao THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'observacao', OLD.observacao, NEW.observacao, auth.uid());
    END IF;
    
    IF OLD.criado_por IS DISTINCT FROM NEW.criado_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'criado_por', OLD.criado_por::text, NEW.criado_por::text, auth.uid());
    END IF;
    
    IF OLD.confirmada_por IS DISTINCT FROM NEW.confirmada_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'confirmada_por', OLD.confirmada_por::text, NEW.confirmada_por::text, auth.uid());
    END IF;
    
    IF OLD.aprovada_por IS DISTINCT FROM NEW.aprovada_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'aprovada_por', OLD.aprovada_por::text, NEW.aprovada_por::text, auth.uid());
    END IF;
    
    IF OLD.lancada_por IS DISTINCT FROM NEW.lancada_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'lancada_por', OLD.lancada_por::text, NEW.lancada_por::text, auth.uid());
    END IF;
    
    IF OLD.aprovado_para_pgto_por IS DISTINCT FROM NEW.aprovado_para_pgto_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'aprovado_para_pgto_por', OLD.aprovado_para_pgto_por::text, NEW.aprovado_para_pgto_por::text, auth.uid());
    END IF;
    
    IF OLD.paga_por IS DISTINCT FROM NEW.paga_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'paga_por', OLD.paga_por::text, NEW.paga_por::text, auth.uid());
    END IF;
    
    IF OLD.cancelada_por IS DISTINCT FROM NEW.cancelada_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'cancelada_por', OLD.cancelada_por::text, NEW.cancelada_por::text, auth.uid());
    END IF;
    
    IF OLD.reprovada_por IS DISTINCT FROM NEW.reprovada_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'reprovada_por', OLD.reprovada_por::text, NEW.reprovada_por::text, auth.uid());
    END IF;
    
    IF OLD.cliente_id IS DISTINCT FROM NEW.cliente_id THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'cliente_id', OLD.cliente_id::text, NEW.cliente_id::text, auth.uid());
    END IF;
    
    IF OLD.colaborador_falecido IS DISTINCT FROM NEW.colaborador_falecido THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'colaborador_falecido', OLD.colaborador_falecido, NEW.colaborador_falecido, auth.uid());
    END IF;
    
    IF OLD.licenca_nojo IS DISTINCT FROM NEW.licenca_nojo THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'licenca_nojo', OLD.licenca_nojo::text, NEW.licenca_nojo::text, auth.uid());
    END IF;
    
    IF OLD.novo_posto IS DISTINCT FROM NEW.novo_posto THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'novo_posto', OLD.novo_posto::text, NEW.novo_posto::text, auth.uid());
    END IF;
    
    IF OLD.confirmada_em IS DISTINCT FROM NEW.confirmada_em THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'confirmada_em', OLD.confirmada_em::text, NEW.confirmada_em::text, auth.uid());
    END IF;
    
    IF OLD.aprovada_em IS DISTINCT FROM NEW.aprovada_em THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'aprovada_em', OLD.aprovada_em::text, NEW.aprovada_em::text, auth.uid());
    END IF;
    
    IF OLD.lancada_em IS DISTINCT FROM NEW.lancada_em THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'lancada_em', OLD.lancada_em::text, NEW.lancada_em::text, auth.uid());
    END IF;
    
    IF OLD.aprovada_para_pagamento_em IS DISTINCT FROM NEW.aprovada_para_pagamento_em THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'aprovada_para_pagamento_em', OLD.aprovada_para_pagamento_em::text, NEW.aprovada_para_pagamento_em::text, auth.uid());
    END IF;
    
    IF OLD.paga_em IS DISTINCT FROM NEW.paga_em THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'paga_em', OLD.paga_em::text, NEW.paga_em::text, auth.uid());
    END IF;
    
    IF OLD.cancelada_em IS DISTINCT FROM NEW.cancelada_em THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'cancelada_em', OLD.cancelada_em::text, NEW.cancelada_em::text, auth.uid());
    END IF;
    
    IF OLD.reprovada_em IS DISTINCT FROM NEW.reprovada_em THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'reprovada_em', OLD.reprovada_em::text, NEW.reprovada_em::text, auth.uid());
    END IF;
    
    IF OLD.pix_alternativo IS DISTINCT FROM NEW.pix_alternativo THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'pix_alternativo', OLD.pix_alternativo, NEW.pix_alternativo, auth.uid());
    END IF;
    
    IF OLD.beneficiario_alternativo IS DISTINCT FROM NEW.beneficiario_alternativo THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'beneficiario_alternativo', OLD.beneficiario_alternativo, NEW.beneficiario_alternativo, auth.uid());
    END IF;
    
    IF OLD.ok_pagamento IS DISTINCT FROM NEW.ok_pagamento THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'ok_pagamento', OLD.ok_pagamento::text, NEW.ok_pagamento::text, auth.uid());
    END IF;
    
    IF OLD.ok_pagamento_em IS DISTINCT FROM NEW.ok_pagamento_em THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'ok_pagamento_em', OLD.ok_pagamento_em::text, NEW.ok_pagamento_em::text, auth.uid());
    END IF;
    
    IF OLD.ok_pagamento_por IS DISTINCT FROM NEW.ok_pagamento_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'ok_pagamento_por', OLD.ok_pagamento_por::text, NEW.ok_pagamento_por::text, auth.uid());
    END IF;
    
    IF OLD.outros_motivos_reprovacao_pagamento IS DISTINCT FROM NEW.outros_motivos_reprovacao_pagamento THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'outros_motivos_reprovacao_pagamento', OLD.outros_motivos_reprovacao_pagamento, NEW.outros_motivos_reprovacao_pagamento, auth.uid());
    END IF;
    
    IF OLD.observacao_pagamento IS DISTINCT FROM NEW.observacao_pagamento THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'observacao_pagamento', OLD.observacao_pagamento::text, NEW.observacao_pagamento::text, auth.uid());
    END IF;
    
    IF OLD.unidade IS DISTINCT FROM NEW.unidade THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'unidade', OLD.unidade, NEW.unidade, auth.uid());
    END IF;
    
    IF OLD.motivo_reprovacao_observacao IS DISTINCT FROM NEW.motivo_reprovacao_observacao THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'motivo_reprovacao_observacao', OLD.motivo_reprovacao_observacao, NEW.motivo_reprovacao_observacao, auth.uid());
    END IF;
    
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;