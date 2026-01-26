-- Atualizar função para remover obrigatoriedade de colaborador_demitido_nome e colaborador_ausente_nome
CREATE OR REPLACE FUNCTION public.validate_diarias_temporarias_required_fields()
RETURNS TRIGGER AS $$
BEGIN
  -- VALIDAÇÃO 1: Quando motivo_vago = 'VAGA EM ABERTO (COBERTURA SALÁRIO)', demissao é obrigatório
  IF NEW.motivo_vago = 'VAGA EM ABERTO (COBERTURA SALÁRIO)' THEN
    IF NEW.demissao IS NULL THEN
      RAISE EXCEPTION 'O campo "demissao" é obrigatório quando o motivo da vaga for "VAGA EM ABERTO (COBERTURA SALÁRIO)"';
    END IF;
    
    -- Se demissao = true, ajustar novo_posto para false
    IF NEW.demissao = TRUE THEN
      NEW.novo_posto := FALSE;
    ELSE
      -- Se demissao = false (novo posto), ajustar novo_posto para true
      NEW.novo_posto := TRUE;
    END IF;
    
    -- Limpar campos que não se aplicam a este motivo
    NEW.colaborador_ausente_nome := NULL;
    NEW.colaborador_ausente := NULL;
    NEW.colaborador_ausente_convenia := NULL;
    
  ELSIF NEW.motivo_vago IS NOT NULL THEN
    -- Para qualquer OUTRO valor de motivo_vago, limpar campos que só se aplicam a "VAGA EM ABERTO (COBERTURA SALÁRIO)"
    NEW.demissao := NULL;
    NEW.colaborador_demitido_nome := NULL;
    NEW.colaborador_demitido := NULL;
    NEW.colaborador_demitido_convenia := NULL;
    NEW.novo_posto := NULL;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;