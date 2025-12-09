-- Definir novo_posto com default false
ALTER TABLE public.diarias_temporarias
ALTER COLUMN novo_posto SET DEFAULT false;

-- Atualizar registros existentes com novo_posto NULL para false
UPDATE public.diarias_temporarias
SET novo_posto = false
WHERE novo_posto IS NULL;

-- Atualizar a função de validação com a nova lógica condicional
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
    
    -- Se demissao é true
    IF NEW.demissao = true THEN
      -- colaborador_falecido deve ser NULL
      NEW.colaborador_falecido := NULL;
      -- licenca_nojo deve ser false
      NEW.licenca_nojo := false;
      -- novo_posto deve ser false
      NEW.novo_posto := false;
      -- colaborador_demitido_nome deve ser preenchido (validação feita no frontend)
    
    -- Se demissao é false ou null
    ELSE
      -- colaborador_demitido e colaborador_demitido_nome devem ser NULL
      NEW.colaborador_demitido := NULL;
      NEW.colaborador_demitido_nome := NULL;
      
      -- Se licenca_nojo é true
      IF NEW.licenca_nojo = true THEN
        -- novo_posto deve ser false
        NEW.novo_posto := false;
        -- colaborador_falecido deve ser preenchido (validação feita no frontend)
      
      -- Se licenca_nojo é false ou null
      ELSE
        -- colaborador_falecido deve ser NULL
        NEW.colaborador_falecido := NULL;
        -- licenca_nojo deve ser false
        NEW.licenca_nojo := false;
        -- novo_posto deve ser true
        NEW.novo_posto := true;
      END IF;
    END IF;
    
  -- Se motivo_vago é 'LICENÇA NOJO (FALECIMENTO)'
  ELSIF NEW.motivo_vago = 'LICENÇA NOJO (FALECIMENTO)'::motivo_vago_type THEN
    -- demissao, colaborador_demitido, colaborador_demitido_nome devem ser NULL
    NEW.demissao := NULL;
    NEW.colaborador_demitido := NULL;
    NEW.colaborador_demitido_nome := NULL;
    -- novo_posto deve ser false
    NEW.novo_posto := false;
    -- licenca_nojo deve ser false (já é licença nojo pelo motivo_vago)
    NEW.licenca_nojo := false;
    
  -- Para outros valores de motivo_vago
  ELSE
    -- demissao, colaborador_demitido, colaborador_demitido_nome, colaborador_falecido devem ser NULL
    NEW.demissao := NULL;
    NEW.colaborador_demitido := NULL;
    NEW.colaborador_demitido_nome := NULL;
    NEW.colaborador_falecido := NULL;
    -- licenca_nojo e novo_posto devem ser false
    NEW.licenca_nojo := false;
    NEW.novo_posto := false;
  END IF;
  
  RETURN NEW;
END;
$function$;