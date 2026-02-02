
-- Corrigir handle_ok_pagamento_change: paga_por = ok_pagamento_por (auth.uid())
CREATE OR REPLACE FUNCTION public.handle_ok_pagamento_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Quando ok_pagamento muda de false/null para true
  IF (OLD.ok_pagamento IS DISTINCT FROM NEW.ok_pagamento) AND NEW.ok_pagamento = true THEN
    NEW.status := 'Paga'::status_diaria;
    NEW.ok_pagamento_em := now() AT TIME ZONE 'America/Sao_Paulo';
    NEW.ok_pagamento_por := auth.uid();
    -- paga_por deve ser o mesmo que ok_pagamento_por (usuário que deu ok)
    NEW.paga_por := auth.uid();
    NEW.paga_em := (now() AT TIME ZONE 'America/Sao_Paulo')::date;
    -- Limpa observações de pagamento quando ok_pagamento é dado
    NEW.observacao_pagamento := NULL;
    NEW.outros_motivos_reprovacao_pagamento := NULL;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Corrigir registrar_responsavel_status_diaria_temporaria: remover status inválido
CREATE OR REPLACE FUNCTION public.registrar_responsavel_status_diaria_temporaria()
RETURNS TRIGGER AS $$
BEGIN
  -- Registrar quando ok_pagamento é marcado como true
  IF (OLD.ok_pagamento IS DISTINCT FROM NEW.ok_pagamento) AND NEW.ok_pagamento = true THEN
    NEW.ok_pagamento_por := auth.uid();
    NEW.ok_pagamento_em := now() AT TIME ZONE 'America/Sao_Paulo';
    NEW.paga_por := auth.uid();
    NEW.paga_em := (now() AT TIME ZONE 'America/Sao_Paulo')::date;
  END IF;

  -- Registrar responsável e data conforme o status
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    CASE NEW.status
      WHEN 'Confirmada'::status_diaria THEN
        NEW.confirmada_por := auth.uid();
        NEW.confirmada_em := (now() AT TIME ZONE 'America/Sao_Paulo')::date;
      WHEN 'Aprovada'::status_diaria THEN
        NEW.aprovada_por := auth.uid();
        NEW.aprovada_em := (now() AT TIME ZONE 'America/Sao_Paulo')::date;
      WHEN 'Lançada para pagamento'::status_diaria THEN
        NEW.lancada_por := auth.uid();
        NEW.lancada_em := (now() AT TIME ZONE 'America/Sao_Paulo')::date;
      WHEN 'Paga'::status_diaria THEN
        -- Se ok_pagamento já foi marcado, não sobrescrever paga_por/paga_em
        IF NEW.paga_por IS NULL THEN
          NEW.paga_por := auth.uid();
          NEW.paga_em := (now() AT TIME ZONE 'America/Sao_Paulo')::date;
        END IF;
      WHEN 'Reprovada'::status_diaria THEN
        NEW.reprovada_por := auth.uid();
        NEW.reprovada_em := (now() AT TIME ZONE 'America/Sao_Paulo')::date;
      WHEN 'Cancelada'::status_diaria THEN
        NEW.cancelada_por := auth.uid();
        NEW.cancelada_em := (now() AT TIME ZONE 'America/Sao_Paulo')::date;
      ELSE
        NULL;
    END CASE;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
