
-- Update the validation trigger to require colaborador_ausente_nome for other motivo_vago values
CREATE OR REPLACE FUNCTION public.validar_motivos_diaria_temporaria()
RETURNS TRIGGER AS $$
BEGIN
  -- When motivo_vago is "VAGA EM ABERTO (COBERTURA SALÁRIO)"
  IF NEW.motivo_vago = 'VAGA EM ABERTO (COBERTURA SALÁRIO)' THEN
    -- demissao must be set (true or false)
    IF NEW.demissao IS NULL THEN
      RAISE EXCEPTION 'O campo "demissao" deve ser informado quando o motivo é VAGA EM ABERTO (COBERTURA SALÁRIO)';
    END IF;
    
    -- If demissao = true, colaborador_demitido_nome is required
    IF NEW.demissao = TRUE THEN
      IF NEW.colaborador_demitido_nome IS NULL OR TRIM(NEW.colaborador_demitido_nome) = '' THEN
        RAISE EXCEPTION 'O campo "colaborador demitido" é obrigatório quando for demissão';
      END IF;
      -- novo_posto should be false when it's a dismissal
      NEW.novo_posto := FALSE;
    ELSE
      -- If demissao = false, novo_posto must be true
      NEW.novo_posto := TRUE;
      -- Clear colaborador_demitido_nome since it's not a dismissal
      NEW.colaborador_demitido_nome := NULL;
    END IF;
    
    -- Clear colaborador_ausente_nome since it's not applicable for this motivo
    NEW.colaborador_ausente_nome := NULL;
    
  ELSIF NEW.motivo_vago IS NOT NULL THEN
    -- For any OTHER motivo_vago value, colaborador_ausente_nome is required
    IF NEW.colaborador_ausente_nome IS NULL OR TRIM(NEW.colaborador_ausente_nome) = '' THEN
      RAISE EXCEPTION 'O campo "colaborador ausente" é obrigatório para este motivo de vaga';
    END IF;
    
    -- Clear fields that only apply to "VAGA EM ABERTO (COBERTURA SALÁRIO)"
    NEW.demissao := NULL;
    NEW.colaborador_demitido_nome := NULL;
    NEW.novo_posto := NULL;
  ELSE
    -- If motivo_vago is NULL, clear all related fields
    NEW.demissao := NULL;
    NEW.colaborador_demitido_nome := NULL;
    NEW.novo_posto := NULL;
    NEW.colaborador_ausente_nome := NULL;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
