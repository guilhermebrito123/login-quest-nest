
CREATE OR REPLACE FUNCTION public.set_cost_center_from_colaborador_cobrindo()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rpc_call text;
BEGIN
  -- Check session variable for cascade bypass
  BEGIN
    v_rpc_call := current_setting('app.rpc_call', true);
  EXCEPTION WHEN OTHERS THEN
    v_rpc_call := '';
  END;

  -- On UPDATE: block changes to local_hora_extra once set, unless cascading from falta
  IF TG_OP = 'UPDATE' AND OLD.local_hora_extra IS DISTINCT FROM NEW.local_hora_extra THEN
    IF v_rpc_call IS DISTINCT FROM 'cascade_falta_local' THEN
      RAISE EXCEPTION 'O centro de custo não pode ser alterado após a criação da hora extra';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;
