CREATE OR REPLACE FUNCTION public.criar_falta_colaborador_convenia()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Skip if autolink already handled it
  IF current_setting('app.falta_already_linked', true) = 'true' THEN
    PERFORM set_config('app.falta_already_linked', '', true);
    RETURN NEW;
  END IF;

  IF NEW.motivo_vago = 'DIÁRIA - FALTA'
     AND NEW.colaborador_ausente_convenia IS NOT NULL THEN
    INSERT INTO public.faltas_colaboradores_convenia (
      colaborador_convenia_id,
      diaria_temporaria_id,
      data_falta,
      motivo,
      local_falta
    ) VALUES (
      NEW.colaborador_ausente_convenia,
      NEW.id,
      NEW.data_diaria,
      'FALTA INJUSTIFICADA',
      NEW.centro_custo_id
    )
    ON CONFLICT (diaria_temporaria_id)
    WHERE diaria_temporaria_id IS NOT NULL
    DO UPDATE SET
      colaborador_convenia_id = EXCLUDED.colaborador_convenia_id,
      data_falta = EXCLUDED.data_falta,
      local_falta = EXCLUDED.local_falta,
      updated_at = now()
    WHERE public.faltas_colaboradores_convenia.motivo = 'FALTA INJUSTIFICADA';
  END IF;

  RETURN NEW;
END;
$$;