-- Atualizar a função handle_ok_pagamento_change para definir paga_por = lancada_por
CREATE OR REPLACE FUNCTION public.handle_ok_pagamento_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Quando ok_pagamento muda de false/null para true
  IF (OLD.ok_pagamento IS DISTINCT FROM NEW.ok_pagamento) AND NEW.ok_pagamento = true THEN
    NEW.status := 'Paga'::status_diaria;
    NEW.ok_pagamento_em := now() AT TIME ZONE 'America/Sao_Paulo';
    NEW.ok_pagamento_por := auth.uid();
    -- paga_por deve ser o usuário que lançou para pagamento (lancada_por), não o usuário atual
    NEW.paga_por := NEW.lancada_por;
    NEW.paga_em := (now() AT TIME ZONE 'America/Sao_Paulo')::date;
    -- Limpa observações de pagamento quando ok_pagamento é dado
    NEW.observacao_pagamento := NULL;
    NEW.outros_motivos_reprovacao_pagamento := NULL;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Atualizar a função registrar_responsavel_status_diaria_temporaria para não sobrescrever paga_por quando ok_pagamento está true
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
      WHEN 'Lancada'::status_diaria THEN
        NEW.lancada_por := auth.uid();
        NEW.lancada_em := (now() AT TIME ZONE 'America/Sao_Paulo')::date;
      WHEN 'Aprovada para Pagamento'::status_diaria THEN
        NEW.aprovado_para_pgto_por := auth.uid();
        NEW.aprovada_para_pagamento_em := (now() AT TIME ZONE 'America/Sao_Paulo')::date;
      WHEN 'Paga'::status_diaria THEN
        -- Se o status mudou para Paga via ok_pagamento = true, paga_por já foi definido
        -- pela função handle_ok_pagamento_change como lancada_por
        -- Só definimos paga_por aqui se não veio do fluxo de ok_pagamento
        IF NEW.ok_pagamento IS NOT TRUE THEN
          NEW.paga_por := auth.uid();
        END IF;
        -- paga_em sempre é atualizado
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

COMMENT ON FUNCTION public.handle_ok_pagamento_change() IS 'Quando ok_pagamento = true, define status como Paga, ok_pagamento_por como usuário atual, e paga_por como lancada_por (quem lançou para pagamento)';
COMMENT ON FUNCTION public.registrar_responsavel_status_diaria_temporaria() IS 'Registra automaticamente o responsável e data de cada transição de status. Quando status = Paga via ok_pagamento, paga_por já é definido como lancada_por pela função handle_ok_pagamento_change';