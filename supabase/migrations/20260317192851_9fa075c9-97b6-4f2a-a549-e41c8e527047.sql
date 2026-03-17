
CREATE OR REPLACE FUNCTION public.fn_faltas_convenia_cascade_data_hora_extra()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_diff interval;
BEGIN
  IF NEW.data_falta IS DISTINCT FROM OLD.data_falta THEN
    v_diff := (NEW.data_falta - OLD.data_falta) * interval '1 day';

    UPDATE public.horas_extras
    SET
      inicio_em            = inicio_em + v_diff,
      fim_em               = fim_em + v_diff,
      intervalo_inicio_em  = CASE
                               WHEN intervalo_inicio_em IS NOT NULL
                               THEN intervalo_inicio_em + v_diff
                               ELSE NULL
                             END,
      intervalo_fim_em     = CASE
                               WHEN intervalo_fim_em IS NOT NULL
                               THEN intervalo_fim_em + v_diff
                               ELSE NULL
                             END,
      data_hora_extra      = NEW.data_falta,
      updated_at           = now()
    WHERE falta_id = NEW.id
      AND status NOT IN ('cancelada', 'reprovada');
  END IF;

  RETURN NEW;
END;
$$;
