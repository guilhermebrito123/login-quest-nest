-- Add cpf column to internal_profiles
ALTER TABLE public.internal_profiles
ADD COLUMN IF NOT EXISTS cpf TEXT;

-- Update the role transition function to handle cpf sync
CREATE OR REPLACE FUNCTION public.handle_usuario_role_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_nome_completo TEXT;
  v_email TEXT;
  v_telefone TEXT;
  v_cpf TEXT;
BEGIN
  -- Only proceed if role actually changed
  IF OLD.role IS DISTINCT FROM NEW.role THEN
    
    -- Handle transition FROM candidato
    IF OLD.role = 'candidato' THEN
      -- Get data from candidatos before deletion
      SELECT nome_completo, email, telefone INTO v_nome_completo, v_email, v_telefone
      FROM candidatos WHERE user_id = NEW.id;
      
      -- Delete from candidatos
      DELETE FROM candidatos WHERE user_id = NEW.id;
      
      -- Insert into new table based on new role
      IF NEW.role = 'colaborador' THEN
        INSERT INTO colaboradores (user_id, nome_completo, email, telefone, status_colaborador)
        VALUES (NEW.id, COALESCE(v_nome_completo, NEW.nome_completo), COALESCE(v_email, NEW.email), COALESCE(v_telefone, NEW.phone), 'ativo')
        ON CONFLICT (user_id) DO NOTHING;
      ELSIF NEW.role = 'perfil_interno' THEN
        INSERT INTO internal_profiles (user_id, nome_completo, email, phone, nivel_acesso)
        VALUES (NEW.id, COALESCE(v_nome_completo, NEW.nome_completo), COALESCE(v_email, NEW.email), COALESCE(v_telefone, NEW.phone), 'cliente_view')
        ON CONFLICT (user_id) DO NOTHING;
      END IF;
    
    -- Handle transition FROM colaborador
    ELSIF OLD.role = 'colaborador' THEN
      -- Get data from colaboradores before deletion (including cpf)
      SELECT nome_completo, email, telefone, cpf INTO v_nome_completo, v_email, v_telefone, v_cpf
      FROM colaboradores WHERE user_id = NEW.id;
      
      -- Delete from colaboradores
      DELETE FROM colaboradores WHERE user_id = NEW.id;
      
      -- Insert into new table based on new role
      IF NEW.role = 'candidato' THEN
        INSERT INTO candidatos (user_id, nome_completo, email, telefone)
        VALUES (NEW.id, COALESCE(v_nome_completo, NEW.nome_completo), COALESCE(v_email, NEW.email), COALESCE(v_telefone, NEW.phone))
        ON CONFLICT (user_id) DO NOTHING;
      ELSIF NEW.role = 'perfil_interno' THEN
        INSERT INTO internal_profiles (user_id, nome_completo, email, phone, nivel_acesso, cpf)
        VALUES (NEW.id, COALESCE(v_nome_completo, NEW.nome_completo), COALESCE(v_email, NEW.email), COALESCE(v_telefone, NEW.phone), 'cliente_view', v_cpf)
        ON CONFLICT (user_id) DO NOTHING;
      END IF;
    
    -- Handle transition FROM perfil_interno
    ELSIF OLD.role = 'perfil_interno' THEN
      -- Get data from internal_profiles before deletion (including cpf)
      SELECT nome_completo, email, phone, cpf INTO v_nome_completo, v_email, v_telefone, v_cpf
      FROM internal_profiles WHERE user_id = NEW.id;
      
      -- Delete from internal_profiles
      DELETE FROM internal_profiles WHERE user_id = NEW.id;
      
      -- Insert into new table based on new role
      IF NEW.role = 'candidato' THEN
        INSERT INTO candidatos (user_id, nome_completo, email, telefone)
        VALUES (NEW.id, COALESCE(v_nome_completo, NEW.nome_completo), COALESCE(v_email, NEW.email), COALESCE(v_telefone, NEW.phone))
        ON CONFLICT (user_id) DO NOTHING;
      ELSIF NEW.role = 'colaborador' THEN
        INSERT INTO colaboradores (user_id, nome_completo, email, telefone, status_colaborador, cpf)
        VALUES (NEW.id, COALESCE(v_nome_completo, NEW.nome_completo), COALESCE(v_email, NEW.email), COALESCE(v_telefone, NEW.phone), 'ativo', v_cpf)
        ON CONFLICT (user_id) DO NOTHING;
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;