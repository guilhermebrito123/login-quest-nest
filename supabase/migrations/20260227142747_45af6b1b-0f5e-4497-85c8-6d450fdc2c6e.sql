
CREATE OR REPLACE FUNCTION public.sync_falta_colaborador_convenia()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Skip if called from justification RPC
  IF current_setting('app.rpc_call', true) = 'justificar_falta' THEN
    RETURN NEW;
  END IF;

  IF NEW.motivo_vago = 'DIÁRIA - FALTA' AND NEW.colaborador_ausente_convenia IS NOT NULL THEN
    INSERT INTO public.faltas_colaboradores_convenia (
      colaborador_convenia_id, diaria_temporaria_id, data_falta, motivo
    ) VALUES (
      NEW.colaborador_ausente_convenia, NEW.id, NEW.data_diaria, 'DIÁRIA - FALTA'::motivo_vago_type
    )
    ON CONFLICT (colaborador_convenia_id, data_falta, diaria_temporaria_id)
    WHERE diaria_temporaria_id IS NOT NULL
    DO UPDATE SET
      colaborador_convenia_id = EXCLUDED.colaborador_convenia_id,
      data_falta = EXCLUDED.data_falta,
      motivo = EXCLUDED.motivo,
      updated_at = now()
    WHERE faltas_colaboradores_convenia.motivo = 'DIÁRIA - FALTA';
  END IF;

  RETURN NEW;
END;
$$;
