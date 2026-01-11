-- Atualizar o trigger para usar timestamp completo (TIMESTAMPTZ) ao invés de DATE
-- nos campos de transição de status
CREATE OR REPLACE FUNCTION public.registrar_responsavel_status_diaria_temporaria()
RETURNS TRIGGER AS $$
DECLARE
  v_agora TIMESTAMPTZ;
BEGIN
  -- Usar timestamp completo com timezone brasileiro
  v_agora := now() AT TIME ZONE 'America/Sao_Paulo';

  IF OLD.status IS DISTINCT FROM NEW.status THEN
    CASE NEW.status
      WHEN 'Confirmada'::status_diaria THEN
        NEW.confirmada_por := auth.uid();
        NEW.confirmada_em := v_agora;
      WHEN 'Aprovada'::status_diaria THEN
        NEW.aprovada_por := auth.uid();
        NEW.aprovada_em := v_agora;
      WHEN 'Lançada para pagamento'::status_diaria THEN
        NEW.lancada_por := auth.uid();
        NEW.lancada_em := v_agora;
        -- Reset campos de pagamento ao transitar para Lançada
        NEW.observacao_pagamento := NULL;
        NEW.outros_motivos_reprovacao_pagamento := NULL;
      WHEN 'Paga'::status_diaria THEN
        NEW.paga_por := auth.uid();
        NEW.paga_em := v_agora;
      WHEN 'Cancelada'::status_diaria THEN
        NEW.cancelada_por := auth.uid();
        NEW.cancelada_em := v_agora;
      WHEN 'Reprovada'::status_diaria THEN
        NEW.reprovada_por := auth.uid();
        NEW.reprovada_em := v_agora;
      ELSE
        NULL;
    END CASE;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;