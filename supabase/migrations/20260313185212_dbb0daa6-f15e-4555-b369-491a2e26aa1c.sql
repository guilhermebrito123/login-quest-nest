
CREATE OR REPLACE FUNCTION public.sync_falta_para_diaria_temporaria()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Só sincronizar se houver diaria_temporaria vinculada
  IF NEW.diaria_temporaria_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Guarda contra recursão infinita
  IF current_setting('app.sync_falta_running', true) = 'true' THEN
    RETURN NEW;
  END IF;

  PERFORM set_config('app.sync_falta_running', 'true', true);

  -- Bypass do trigger de bloqueio estrutural
  PERFORM set_config('app.rpc_call', 'true', true);

  UPDATE diarias_temporarias
  SET
    data_diaria = CASE WHEN OLD.data_falta IS DISTINCT FROM NEW.data_falta THEN NEW.data_falta ELSE data_diaria END,
    colaborador_ausente_convenia = CASE WHEN OLD.colaborador_convenia_id IS DISTINCT FROM NEW.colaborador_convenia_id THEN NEW.colaborador_convenia_id ELSE colaborador_ausente_convenia END,
    updated_at = now() AT TIME ZONE 'America/Sao_Paulo'
  WHERE id = NEW.diaria_temporaria_id;

  PERFORM set_config('app.rpc_call', '', true);
  PERFORM set_config('app.sync_falta_running', '', true);

  RETURN NEW;
END;
$$;
