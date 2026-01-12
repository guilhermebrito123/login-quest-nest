
-- Remove columns that are no longer needed
ALTER TABLE public.diarias_temporarias DROP COLUMN IF EXISTS colaborador_falecido;
ALTER TABLE public.diarias_temporarias DROP COLUMN IF EXISTS licenca_nojo;

-- Update the validation trigger with the new simplified logic
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
  ELSE
    -- For any other motivo_vago, clear all these fields
    NEW.demissao := NULL;
    NEW.colaborador_demitido_nome := NULL;
    NEW.novo_posto := NULL;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Ensure trigger exists
DROP TRIGGER IF EXISTS validar_motivos_diaria_temporaria_trigger ON public.diarias_temporarias;
CREATE TRIGGER validar_motivos_diaria_temporaria_trigger
  BEFORE INSERT OR UPDATE ON public.diarias_temporarias
  FOR EACH ROW
  EXECUTE FUNCTION public.validar_motivos_diaria_temporaria();

-- Update audit trigger to remove references to deleted columns
CREATE OR REPLACE FUNCTION public.fn_audit_diarias_temporarias_granular()
RETURNS TRIGGER AS $$
DECLARE
  campos_monitorados TEXT[] := ARRAY[
    'cliente_id', 'diarista_id', 'unidade', 'posto_servico', 'posto_servico_id',
    'data_diaria', 'horario_inicio', 'horario_fim', 'intervalo', 'jornada_diaria',
    'valor_diaria', 'motivo_vago', 'novo_posto', 'colaborador_ausente',
    'colaborador_ausente_nome', 'colaborador_demitido', 'colaborador_demitido_nome',
    'demissao', 'observacao', 'status', 'confirmado_por', 'confirmado_em',
    'aprovado_por', 'aprovado_em', 'lancado_pagamento_por', 'lancado_pagamento_em',
    'pago_por', 'pago_em', 'cancelado_por', 'cancelado_em', 'reprovado_por',
    'reprovado_em', 'motivo_reprovacao', 'motivo_reprovacao_observacao',
    'ok_pagamento', 'observacao_pagamento', 'outros_motivos_reprovacao_pagamento'
  ];
  campo TEXT;
  valor_antigo TEXT;
  valor_novo TEXT;
  usuario_id UUID;
BEGIN
  -- Get current user
  usuario_id := COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::UUID);
  
  -- Only log on INSERT and UPDATE (not DELETE to avoid FK issues)
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  
  FOREACH campo IN ARRAY campos_monitorados LOOP
    IF TG_OP = 'INSERT' THEN
      EXECUTE format('SELECT ($1).%I::TEXT', campo)
        INTO valor_novo
        USING NEW;
      
      IF valor_novo IS NOT NULL THEN
        INSERT INTO public.diarias_temporarias_logs (
          diaria_temporaria_id,
          campo_alterado,
          valor_anterior,
          valor_novo,
          alterado_por
        ) VALUES (
          NEW.id,
          campo,
          NULL,
          valor_novo,
          usuario_id
        );
      END IF;
    ELSIF TG_OP = 'UPDATE' THEN
      EXECUTE format('SELECT ($1).%I::TEXT, ($2).%I::TEXT', campo, campo)
        INTO valor_antigo, valor_novo
        USING OLD, NEW;
      
      IF valor_antigo IS DISTINCT FROM valor_novo THEN
        INSERT INTO public.diarias_temporarias_logs (
          diaria_temporaria_id,
          campo_alterado,
          valor_anterior,
          valor_novo,
          alterado_por
        ) VALUES (
          NEW.id,
          campo,
          valor_antigo,
          valor_novo,
          usuario_id
        );
      END IF;
    END IF;
  END LOOP;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
