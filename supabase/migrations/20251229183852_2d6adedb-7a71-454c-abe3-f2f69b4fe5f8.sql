-- Atualizar funcao para resetar ok_pagamento quando status voltar para estados anteriores
CREATE OR REPLACE FUNCTION public.registrar_responsavel_status_diaria_temporaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_hoje DATE;
BEGIN
  v_hoje := (now() AT TIME ZONE 'America/Sao_Paulo')::DATE;

  IF OLD.status IS DISTINCT FROM NEW.status THEN
    -- Resetar ok_pagamento quando status voltar para estados anteriores ao pagamento
    IF NEW.status IN ('Aguardando confirmação'::status_diaria, 'Confirmada'::status_diaria, 'Aprovada'::status_diaria, 'Lançada para pagamento'::status_diaria) THEN
      IF OLD.ok_pagamento IS NOT NULL THEN
        NEW.ok_pagamento := NULL;
        NEW.ok_pagamento_em := NULL;
        NEW.ok_pagamento_por := NULL;
        NEW.observacao_pagamento := NULL;
        NEW.outros_motivos_reprovacao_pagamento := NULL;
      END IF;
    END IF;

    CASE NEW.status
      WHEN 'Confirmada'::status_diaria THEN
        NEW.confirmada_por := auth.uid();
        NEW.confirmada_em := v_hoje;
      WHEN 'Aprovada'::status_diaria THEN
        NEW.aprovada_por := auth.uid();
        NEW.aprovada_em := v_hoje;
      WHEN 'Lançada para pagamento'::status_diaria THEN
        NEW.lancada_por := auth.uid();
        NEW.lancada_em := v_hoje;
      WHEN 'Paga'::status_diaria THEN
        NEW.paga_por := auth.uid();
        NEW.paga_em := v_hoje;
      WHEN 'Cancelada'::status_diaria THEN
        NEW.cancelada_por := auth.uid();
        NEW.cancelada_em := v_hoje;
      WHEN 'Reprovada'::status_diaria THEN
        NEW.reprovada_por := auth.uid();
        NEW.reprovada_em := v_hoje;
      ELSE
        NULL;
    END CASE;
  END IF;

  RETURN NEW;
END;
$function$;