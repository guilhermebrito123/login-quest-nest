-- Corrigir função validar_dias_semana_escala para incluir search_path
CREATE OR REPLACE FUNCTION public.validar_dias_semana_escala()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- Se a escala for 5x2 ou 6x1, dias_semana é obrigatório
  IF NEW.escala IN ('5x2', '6x1') AND NEW.dias_semana IS NULL THEN
    RAISE EXCEPTION 'Para escalas 5x2 e 6x1, o campo dias_semana é obrigatório';
  END IF;
  
  RETURN NEW;
END;
$$;