-- Change default role to 'candidato' for new users
ALTER TABLE public.usuarios 
ALTER COLUMN role SET DEFAULT 'candidato'::user_type;

-- Create trigger function to insert into candidatos when a new user with role 'candidato' is created
CREATE OR REPLACE FUNCTION public.handle_new_candidato()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- Only insert into candidatos if the user role is 'candidato'
  IF NEW.role = 'candidato'::user_type THEN
    INSERT INTO public.candidatos (
      id,
      nome_completo,
      email,
      cidade,
      estado,
      telefone,
      celular,
      curriculo_path,
      experiencia_relevante
    ) VALUES (
      NEW.id,
      COALESCE(NEW.full_name, 'Nome não informado'),
      NEW.email,
      'Não informada',
      'Não informado',
      COALESCE(NEW.phone, 'Não informado'),
      COALESCE(NEW.phone, 'Não informado'),
      '',
      ARRAY[]::text[]
    )
    ON CONFLICT (id) DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Create trigger on usuarios table to auto-insert into candidatos
DROP TRIGGER IF EXISTS on_new_candidato_user ON public.usuarios;
CREATE TRIGGER on_new_candidato_user
  AFTER INSERT ON public.usuarios
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_candidato();