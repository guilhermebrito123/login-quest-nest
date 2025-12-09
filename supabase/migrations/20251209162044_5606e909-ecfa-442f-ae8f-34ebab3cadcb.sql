-- Adicionar atributo colaborador_falecido na tabela diarias_temporarias
ALTER TABLE public.diarias_temporarias
ADD COLUMN colaborador_falecido text;

-- Atualizar a função de validação para incluir a lógica do colaborador_falecido
CREATE OR REPLACE FUNCTION public.validar_diarias_temporarias_motivo_vago()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Se motivo_vago é 'VAGA EM ABERTO (COBERTURA SALÁRIO)'
  IF NEW.motivo_vago = 'VAGA EM ABERTO (COBERTURA SALÁRIO)'::motivo_vago_type THEN
    -- colaborador_ausente e colaborador_ausente_nome devem ser NULL
    NEW.colaborador_ausente := NULL;
    NEW.colaborador_ausente_nome := NULL;
    -- colaborador_falecido deve ser NULL
    NEW.colaborador_falecido := NULL;
    
    -- Se demissao é false ou null, colaborador_demitido e colaborador_demitido_nome devem ser NULL
    IF NEW.demissao IS NULL OR NEW.demissao = false THEN
      NEW.colaborador_demitido := NULL;
      NEW.colaborador_demitido_nome := NULL;
    END IF;
  -- Se motivo_vago é 'LICENÇA NOJO (FALECIMENTO)'
  ELSIF NEW.motivo_vago = 'LICENÇA NOJO (FALECIMENTO)'::motivo_vago_type THEN
    -- demissao, colaborador_demitido e colaborador_demitido_nome devem ser NULL
    NEW.demissao := NULL;
    NEW.colaborador_demitido := NULL;
    NEW.colaborador_demitido_nome := NULL;
  ELSE
    -- Para outros valores de motivo_vago, demissao, colaborador_demitido, colaborador_demitido_nome e colaborador_falecido devem ser NULL
    NEW.demissao := NULL;
    NEW.colaborador_demitido := NULL;
    NEW.colaborador_demitido_nome := NULL;
    NEW.colaborador_falecido := NULL;
  END IF;
  
  RETURN NEW;
END;
$function$;