
CREATE OR REPLACE FUNCTION public.sync_falta_colaborador_convenia()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
    ON CONFLICT (diaria_temporaria_id) WHERE diaria_temporaria_id IS NOT NULL
    DO UPDATE SET
      colaborador_convenia_id = EXCLUDED.colaborador_convenia_id,
      data_falta = EXCLUDED.data_falta,
      motivo = EXCLUDED.motivo,
      updated_at = now()
    WHERE faltas_colaboradores_convenia.motivo = 'FALTA INJUSTIFICADA';
  END IF;

  RETURN NEW;
END;
$$;
