
CREATE OR REPLACE FUNCTION public.validar_falta_justificada_diaria()
RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  v_bypass text;
BEGIN
  v_bypass := current_setting('app.rpc_call', true);

  IF TG_OP = 'INSERT' AND NEW.motivo_vago = 'DIÁRIA - FALTA ATESTADO' THEN
    IF v_bypass IN ('justificar_falta', 'true') THEN
      RETURN NEW;
    END IF;
    RAISE EXCEPTION 'Não é permitido criar diária diretamente como DIÁRIA - FALTA ATESTADO. Crie como DIÁRIA - FALTA e justifique via RPC.';
  END IF;

  IF TG_OP = 'UPDATE' 
     AND OLD.motivo_vago = 'DIÁRIA - FALTA'
     AND NEW.motivo_vago = 'DIÁRIA - FALTA ATESTADO' THEN
    IF v_bypass IN ('justificar_falta', 'true') THEN
      RETURN NEW;
    END IF;
    RAISE EXCEPTION 'Não é permitido alterar para DIÁRIA - FALTA ATESTADO diretamente. Use a função justificar_falta_convenia com atestado.';
  END IF;

  RETURN NEW;
END;
$$;
