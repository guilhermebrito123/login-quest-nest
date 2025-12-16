-- Add date tracking columns to diarias_temporarias
ALTER TABLE public.diarias_temporarias
ADD COLUMN confirmada_em DATE,
ADD COLUMN aprovada_em DATE,
ADD COLUMN lancada_em DATE,
ADD COLUMN aprovada_para_pagamento_em DATE,
ADD COLUMN paga_em DATE,
ADD COLUMN cancelada_em DATE,
ADD COLUMN reprovada_em DATE;

-- Update the trigger function to also set the date fields
CREATE OR REPLACE FUNCTION public.registrar_responsavel_status_diaria_temporaria()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_hoje DATE;
BEGIN
  -- Get current date in Brazilian timezone
  v_hoje := (now() AT TIME ZONE 'America/Sao_Paulo')::DATE;
  
  -- Track who changed the status and when based on status transition
  IF OLD.status IS DISTINCT FROM NEW.status THEN
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
      WHEN 'Aprovada para pagamento'::status_diaria THEN
        NEW.aprovado_para_pgto_por := auth.uid();
        NEW.aprovada_para_pagamento_em := v_hoje;
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