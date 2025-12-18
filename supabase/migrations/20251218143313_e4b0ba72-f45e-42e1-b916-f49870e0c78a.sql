
-- Drop and recreate the trigger function to properly handle CPF on role transitions
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
  -- Only handle role changes
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
        INSERT INTO colaboradores (user_id, nome_completo, email, telefone, status_colaborador, cpf)
        VALUES (NEW.id, COALESCE(v_nome_completo, NEW.full_name), COALESCE(v_email, NEW.email), COALESCE(v_telefone, NEW.phone), 'ativo', '')
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, colaboradores.nome_completo),
          email = COALESCE(EXCLUDED.email, colaboradores.email),
          telefone = COALESCE(EXCLUDED.telefone, colaboradores.telefone);
      ELSIF NEW.role = 'perfil_interno' THEN
        INSERT INTO internal_profiles (user_id, nome_completo, email, phone, nivel_acesso)
        VALUES (NEW.id, COALESCE(v_nome_completo, NEW.full_name), COALESCE(v_email, NEW.email), COALESCE(v_telefone, NEW.phone), 'cliente_view')
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, internal_profiles.nome_completo),
          email = COALESCE(EXCLUDED.email, internal_profiles.email),
          phone = COALESCE(EXCLUDED.phone, internal_profiles.phone);
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
        VALUES (NEW.id, COALESCE(v_nome_completo, NEW.full_name), COALESCE(v_email, NEW.email), COALESCE(v_telefone, NEW.phone))
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, candidatos.nome_completo),
          email = COALESCE(EXCLUDED.email, candidatos.email),
          telefone = COALESCE(EXCLUDED.telefone, candidatos.telefone);
      ELSIF NEW.role = 'perfil_interno' THEN
        INSERT INTO internal_profiles (user_id, nome_completo, email, phone, nivel_acesso, cpf)
        VALUES (NEW.id, COALESCE(v_nome_completo, NEW.full_name), COALESCE(v_email, NEW.email), COALESCE(v_telefone, NEW.phone), 'cliente_view', v_cpf)
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, internal_profiles.nome_completo),
          email = COALESCE(EXCLUDED.email, internal_profiles.email),
          phone = COALESCE(EXCLUDED.phone, internal_profiles.phone),
          cpf = COALESCE(EXCLUDED.cpf, internal_profiles.cpf);
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
        VALUES (NEW.id, COALESCE(v_nome_completo, NEW.full_name), COALESCE(v_email, NEW.email), COALESCE(v_telefone, NEW.phone))
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, candidatos.nome_completo),
          email = COALESCE(EXCLUDED.email, candidatos.email),
          telefone = COALESCE(EXCLUDED.telefone, candidatos.telefone);
      ELSIF NEW.role = 'colaborador' THEN
        INSERT INTO colaboradores (user_id, nome_completo, email, telefone, status_colaborador, cpf)
        VALUES (NEW.id, COALESCE(v_nome_completo, NEW.full_name), COALESCE(v_email, NEW.email), COALESCE(v_telefone, NEW.phone), 'ativo', COALESCE(v_cpf, ''))
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, colaboradores.nome_completo),
          email = COALESCE(EXCLUDED.email, colaboradores.email),
          telefone = COALESCE(EXCLUDED.telefone, colaboradores.telefone),
          cpf = COALESCE(EXCLUDED.cpf, colaboradores.cpf);
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;
