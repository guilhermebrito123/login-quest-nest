-- Fix the sync trigger to bypass during RPC execution and not handle FALTA JUSTIFICADA directly
CREATE OR REPLACE FUNCTION sync_falta_colaborador_convenia()
RETURNS TRIGGER AS $$
BEGIN
  -- Bypass if called from the justificar_falta RPC
  IF current_setting('app.rpc_call', true) = 'justificar_falta' THEN
    RETURN NEW;
  END IF;

  -- Only handle FALTA INJUSTIFICADA - FALTA JUSTIFICADA is handled exclusively by the RPC
  IF NEW.motivo_vago = 'FALTA INJUSTIFICADA' AND NEW.colaborador_ausente_convenia IS NOT NULL THEN
    INSERT INTO public.faltas_colaboradores_convenia (
      colaborador_convenia_id,
      diaria_temporaria_id,
      data_falta,
      motivo
    )
    VALUES (
      NEW.colaborador_ausente_convenia,
      NEW.id,
      NEW.data_diaria,
      'FALTA INJUSTIFICADA'::motivo_vago_type
    )
    ON CONFLICT (diaria_temporaria_id) 
    DO UPDATE SET
      colaborador_convenia_id = EXCLUDED.colaborador_convenia_id,
      data_falta = EXCLUDED.data_falta,
      motivo = EXCLUDED.motivo,
      updated_at = now()
    -- Only update if current motivo is FALTA INJUSTIFICADA (don't overwrite justified absences)
    WHERE faltas_colaboradores_convenia.motivo = 'FALTA INJUSTIFICADA';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;