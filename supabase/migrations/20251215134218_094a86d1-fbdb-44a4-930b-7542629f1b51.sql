-- Create function to validate superior field updates
CREATE OR REPLACE FUNCTION public.validate_superior_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- If superior is being changed and user is not admin, reject
  IF (OLD.superior IS DISTINCT FROM NEW.superior) THEN
    IF NOT has_role(auth.uid(), 'admin'::app_role) THEN
      RAISE EXCEPTION 'Apenas administradores podem definir o superior de um usuário';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger to enforce the validation
CREATE TRIGGER validate_superior_update_trigger
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_superior_update();