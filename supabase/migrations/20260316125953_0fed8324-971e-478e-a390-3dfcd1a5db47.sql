CREATE OR REPLACE FUNCTION public.sync_falta_para_diaria_temporaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_prev_rpc_call text;
  v_prev_sync_running text;
BEGIN
  -- Só sincronizar se houver diária temporária vinculada
  IF NEW.diaria_temporaria_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Guarda contra recursão infinita
  v_prev_sync_running := current_setting('app.sync_falta_running', true);
  IF v_prev_sync_running = 'true' THEN
    RETURN NEW;
  END IF;

  v_prev_rpc_call := current_setting('app.rpc_call', true);

  PERFORM set_config('app.sync_falta_running', 'true', true);

  -- Só aplica bypass genérico se não houver um bypass mais específico já ativo
  IF v_prev_rpc_call IS NULL OR v_prev_rpc_call = '' THEN
    PERFORM set_config('app.rpc_call', 'true', true);
  END IF;

  UPDATE public.diarias_temporarias
  SET
    data_diaria = CASE WHEN OLD.data_falta IS DISTINCT FROM NEW.data_falta THEN NEW.data_falta ELSE data_diaria END,
    colaborador_ausente_convenia = CASE WHEN OLD.colaborador_convenia_id IS DISTINCT FROM NEW.colaborador_convenia_id THEN NEW.colaborador_convenia_id ELSE colaborador_ausente_convenia END,
    updated_at = now() AT TIME ZONE 'America/Sao_Paulo'
  WHERE id = NEW.diaria_temporaria_id;

  -- Restaura o contexto anterior da transação
  IF v_prev_rpc_call IS NULL OR v_prev_rpc_call = '' THEN
    PERFORM set_config('app.rpc_call', '', true);
  ELSE
    PERFORM set_config('app.rpc_call', v_prev_rpc_call, true);
  END IF;

  IF v_prev_sync_running IS NULL OR v_prev_sync_running = '' THEN
    PERFORM set_config('app.sync_falta_running', '', true);
  ELSE
    PERFORM set_config('app.sync_falta_running', v_prev_sync_running, true);
  END IF;

  RETURN NEW;
END;
$function$;