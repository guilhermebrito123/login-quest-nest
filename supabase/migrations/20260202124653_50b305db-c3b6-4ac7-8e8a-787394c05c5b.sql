-- Corrigir a função registrar_responsavel_status_diaria_temporaria
-- O enum usa 'Lançada para pagamento' e não 'Lancada'
CREATE OR REPLACE FUNCTION public.registrar_responsavel_status_diaria_temporaria()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
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
        -- Se ok_pagamento for verdadeiro, paga_por recebe lancada_por
        IF NEW.ok_pagamento = true THEN
          NEW.paga_por := NEW.lancada_por;
        ELSE
          NEW.paga_por := auth.uid();
        END IF;
        NEW.paga_em := (now() AT TIME ZONE 'America/Sao_Paulo')::date;
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
$$;