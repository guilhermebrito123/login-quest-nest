
-- Trigger para sincronizar alterações em faltas_colaboradores_convenia com diarias_temporarias vinculada
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

  -- Bypass do trigger de bloqueio estrutural (caso ainda exista alguma validação)
  PERFORM set_config('app.rpc_call', 'true', true);

  UPDATE diarias_temporarias
  SET
    data_diaria = CASE WHEN OLD.data_falta IS DISTINCT FROM NEW.data_falta THEN NEW.data_falta ELSE data_diaria END,
    colaborador_ausente_convenia = CASE WHEN OLD.colaborador_convenia_id IS DISTINCT FROM NEW.colaborador_convenia_id THEN NEW.colaborador_convenia_id ELSE colaborador_ausente_convenia END,
    updated_at = now() AT TIME ZONE 'America/Sao_Paulo'
  WHERE id = NEW.diaria_temporaria_id;

  -- Limpar bypass
  PERFORM set_config('app.rpc_call', '', true);

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_falta_para_diaria ON public.faltas_colaboradores_convenia;

CREATE TRIGGER trg_sync_falta_para_diaria
  AFTER UPDATE ON public.faltas_colaboradores_convenia
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_falta_para_diaria_temporaria();
