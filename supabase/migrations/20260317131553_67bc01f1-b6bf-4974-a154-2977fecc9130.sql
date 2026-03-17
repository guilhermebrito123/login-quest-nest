
-- Trigger: sync hora_extra operacao when falta motivo changes
CREATE OR REPLACE FUNCTION public.sync_hora_extra_operacao_on_falta_motivo()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only act when motivo actually changed
  IF OLD.motivo IS DISTINCT FROM NEW.motivo THEN
    IF NEW.motivo = 'FALTA JUSTIFICADA' AND OLD.motivo = 'FALTA INJUSTIFICADA' THEN
      UPDATE public.horas_extras
      SET operacao = 'cobertura_falta_atestado',
          updated_at = now()
      WHERE falta_id = NEW.id
        AND status IN ('pendente', 'confirmada', 'aprovada');
    ELSIF NEW.motivo = 'FALTA INJUSTIFICADA' AND OLD.motivo = 'FALTA JUSTIFICADA' THEN
      UPDATE public.horas_extras
      SET operacao = 'cobertura_falta',
          updated_at = now()
      WHERE falta_id = NEW.id
        AND status IN ('pendente', 'confirmada', 'aprovada');
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_hora_extra_operacao_on_falta_motivo ON public.faltas_colaboradores_convenia;

CREATE TRIGGER trg_sync_hora_extra_operacao_on_falta_motivo
  AFTER UPDATE OF motivo ON public.faltas_colaboradores_convenia
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_hora_extra_operacao_on_falta_motivo();
