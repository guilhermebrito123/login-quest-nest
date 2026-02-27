
-- Fix criar_falta_colaborador_convenia to use new text value instead of old enum value
CREATE OR REPLACE FUNCTION public.criar_falta_colaborador_convenia()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.motivo_vago = 'DIÁRIA - FALTA'
     AND NEW.colaborador_ausente_convenia IS NOT NULL THEN
    INSERT INTO public.faltas_colaboradores_convenia (
      colaborador_convenia_id, diaria_temporaria_id, data_falta, motivo
    ) VALUES (
      NEW.colaborador_ausente_convenia, NEW.id, NEW.data_diaria, 'FALTA INJUSTIFICADA'
    );
  END IF;
  RETURN NEW;
END;
$$;
