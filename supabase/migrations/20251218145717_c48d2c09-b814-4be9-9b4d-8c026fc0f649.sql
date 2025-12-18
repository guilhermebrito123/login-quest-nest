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
  v_cargo TEXT;
BEGIN
  -- Only process if role actually changed
  IF OLD.role IS DISTINCT FROM NEW.role THEN
    
    -- Transition FROM candidato
    IF OLD.role = 'candidato' THEN
      -- Get data from candidatos
      SELECT nome_completo, email, telefone 
      INTO v_nome_completo, v_email, v_telefone
      FROM candidatos WHERE user_id = NEW.id;
      
      -- Delete from candidatos
      DELETE FROM candidatos WHERE user_id = NEW.id;
      
      -- Insert into new role table
      IF NEW.role = 'colaborador' THEN
        INSERT INTO colaboradores (user_id, nome_completo, email, telefone, status_colaborador)
        VALUES (NEW.id, v_nome_completo, v_email, v_telefone, 'ativo')
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, colaboradores.nome_completo),
          email = COALESCE(EXCLUDED.email, colaboradores.email),
          telefone = COALESCE(EXCLUDED.telefone, colaboradores.telefone);
      ELSIF NEW.role = 'perfil_interno' THEN
        INSERT INTO internal_profiles (user_id, nome_completo, email, phone)
        VALUES (NEW.id, v_nome_completo, v_email, v_telefone)
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, internal_profiles.nome_completo),
          email = COALESCE(EXCLUDED.email, internal_profiles.email),
          phone = COALESCE(EXCLUDED.phone, internal_profiles.phone);
      END IF;
    
    -- Transition FROM colaborador
    ELSIF OLD.role = 'colaborador' THEN
      -- Get data from colaboradores (including cpf and cargo)
      SELECT nome_completo, email, telefone, cpf, cargo
      INTO v_nome_completo, v_email, v_telefone, v_cpf, v_cargo
      FROM colaboradores WHERE user_id = NEW.id;
      
      -- Delete from colaboradores
      DELETE FROM colaboradores WHERE user_id = NEW.id;
      
      -- Insert into new role table
      IF NEW.role = 'candidato' THEN
        INSERT INTO candidatos (user_id, nome_completo, email, telefone)
        VALUES (NEW.id, v_nome_completo, v_email, v_telefone)
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, candidatos.nome_completo),
          email = COALESCE(EXCLUDED.email, candidatos.email),
          telefone = COALESCE(EXCLUDED.telefone, candidatos.telefone);
      ELSIF NEW.role = 'perfil_interno' THEN
        INSERT INTO internal_profiles (user_id, nome_completo, email, phone, cpf, cargo)
        VALUES (NEW.id, v_nome_completo, v_email, v_telefone, NULLIF(v_cpf, ''), v_cargo)
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, internal_profiles.nome_completo),
          email = COALESCE(EXCLUDED.email, internal_profiles.email),
          phone = COALESCE(EXCLUDED.phone, internal_profiles.phone),
          cpf = COALESCE(EXCLUDED.cpf, internal_profiles.cpf),
          cargo = COALESCE(EXCLUDED.cargo, internal_profiles.cargo);
      END IF;
    
    -- Transition FROM perfil_interno
    ELSIF OLD.role = 'perfil_interno' THEN
      -- Get data from internal_profiles (including cpf and cargo)
      SELECT nome_completo, email, phone, cpf, cargo
      INTO v_nome_completo, v_email, v_telefone, v_cpf, v_cargo
      FROM internal_profiles WHERE user_id = NEW.id;
      
      -- Delete from internal_profiles
      DELETE FROM internal_profiles WHERE user_id = NEW.id;
      
      -- Insert into new role table
      IF NEW.role = 'candidato' THEN
        INSERT INTO candidatos (user_id, nome_completo, email, telefone)
        VALUES (NEW.id, v_nome_completo, v_email, v_telefone)
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, candidatos.nome_completo),
          email = COALESCE(EXCLUDED.email, candidatos.email),
          telefone = COALESCE(EXCLUDED.telefone, candidatos.telefone);
      ELSIF NEW.role = 'colaborador' THEN
        INSERT INTO colaboradores (user_id, nome_completo, email, telefone, cpf, cargo, status_colaborador)
        VALUES (NEW.id, v_nome_completo, v_email, v_telefone, NULLIF(v_cpf, ''), v_cargo, 'ativo')
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, colaboradores.nome_completo),
          email = COALESCE(EXCLUDED.email, colaboradores.email),
          telefone = COALESCE(EXCLUDED.telefone, colaboradores.telefone),
          cpf = COALESCE(EXCLUDED.cpf, colaboradores.cpf),
          cargo = COALESCE(EXCLUDED.cargo, colaboradores.cargo);
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;