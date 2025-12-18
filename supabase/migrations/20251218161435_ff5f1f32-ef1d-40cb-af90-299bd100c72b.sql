-- Corrigir função de transição para buscar nome_completo corretamente de internal_profiles
CREATE OR REPLACE FUNCTION public.handle_usuario_role_transition()
RETURNS TRIGGER AS $$
DECLARE
  v_nome_completo TEXT;
  v_email TEXT;
  v_telefone TEXT;
  v_cpf TEXT;
  v_cargo TEXT;
BEGIN
  -- Only process when role actually changes
  IF OLD.role IS DISTINCT FROM NEW.role THEN
    
    -- Transition from candidato to colaborador
    IF OLD.role = 'candidato' AND NEW.role = 'colaborador' THEN
      -- Get data from candidatos table
      SELECT nome_completo, email, telefone
      INTO v_nome_completo, v_email, v_telefone
      FROM candidatos
      WHERE user_id = NEW.id;
      
      -- Insert into colaboradores with data from candidatos
      INSERT INTO colaboradores (user_id, nome_completo, email, telefone, status_colaborador)
      VALUES (NEW.id, COALESCE(v_nome_completo, NEW.nome_completo), COALESCE(v_email, NEW.email), COALESCE(v_telefone, NEW.phone), 'ativo')
      ON CONFLICT (user_id) DO UPDATE SET
        nome_completo = COALESCE(EXCLUDED.nome_completo, colaboradores.nome_completo),
        email = COALESCE(EXCLUDED.email, colaboradores.email),
        telefone = COALESCE(EXCLUDED.telefone, colaboradores.telefone),
        status_colaborador = 'ativo';
      
      -- Delete from candidatos
      DELETE FROM candidatos WHERE user_id = NEW.id;
    
    -- Transition from colaborador to candidato
    ELSIF OLD.role = 'colaborador' AND NEW.role = 'candidato' THEN
      -- Get data from colaboradores table
      SELECT nome_completo, email, telefone
      INTO v_nome_completo, v_email, v_telefone
      FROM colaboradores
      WHERE user_id = NEW.id;
      
      -- Insert into candidatos with data from colaboradores
      INSERT INTO candidatos (user_id, nome_completo, email, telefone)
      VALUES (NEW.id, COALESCE(v_nome_completo, NEW.nome_completo), COALESCE(v_email, NEW.email), COALESCE(v_telefone, NEW.phone))
      ON CONFLICT (user_id) DO UPDATE SET
        nome_completo = COALESCE(EXCLUDED.nome_completo, candidatos.nome_completo),
        email = COALESCE(EXCLUDED.email, candidatos.email),
        telefone = COALESCE(EXCLUDED.telefone, candidatos.telefone);
      
      -- Delete from colaboradores
      DELETE FROM colaboradores WHERE user_id = NEW.id;
    
    -- Transition to perfil_interno (from any role)
    ELSIF NEW.role = 'perfil_interno' THEN
      -- Get data from the source table based on old role
      IF OLD.role = 'candidato' THEN
        SELECT nome_completo, email, telefone
        INTO v_nome_completo, v_email, v_telefone
        FROM candidatos
        WHERE user_id = NEW.id;
        v_cpf := NULL;
        v_cargo := NULL;
      ELSIF OLD.role = 'colaborador' THEN
        SELECT nome_completo, email, telefone, cpf, cargo
        INTO v_nome_completo, v_email, v_telefone, v_cpf, v_cargo
        FROM colaboradores
        WHERE user_id = NEW.id;
      END IF;
      
      -- Insert into internal_profiles
      INSERT INTO internal_profiles (user_id, nome_completo, email, phone, cpf, cargo, nivel_acesso)
      VALUES (
        NEW.id, 
        COALESCE(v_nome_completo, NEW.nome_completo), 
        COALESCE(v_email, NEW.email), 
        COALESCE(v_telefone, NEW.phone),
        NULLIF(v_cpf, ''),
        v_cargo,
        'cliente_view'
      )
      ON CONFLICT (user_id) DO UPDATE SET
        nome_completo = COALESCE(EXCLUDED.nome_completo, internal_profiles.nome_completo),
        email = COALESCE(EXCLUDED.email, internal_profiles.email),
        phone = COALESCE(EXCLUDED.phone, internal_profiles.phone),
        cpf = COALESCE(EXCLUDED.cpf, internal_profiles.cpf),
        cargo = COALESCE(EXCLUDED.cargo, internal_profiles.cargo);
      
      -- Delete from old table
      IF OLD.role = 'candidato' THEN
        DELETE FROM candidatos WHERE user_id = NEW.id;
      ELSIF OLD.role = 'colaborador' THEN
        DELETE FROM colaboradores WHERE user_id = NEW.id;
      END IF;
    
    -- Transition from perfil_interno to candidato
    ELSIF OLD.role = 'perfil_interno' AND NEW.role = 'candidato' THEN
      -- Get data from internal_profiles
      SELECT nome_completo, email, phone
      INTO v_nome_completo, v_email, v_telefone
      FROM internal_profiles
      WHERE user_id = NEW.id;
      
      -- Insert into candidatos
      INSERT INTO candidatos (user_id, nome_completo, email, telefone)
      VALUES (
        NEW.id, 
        COALESCE(v_nome_completo, NEW.nome_completo), 
        COALESCE(v_email, NEW.email), 
        COALESCE(v_telefone, NEW.phone)
      )
      ON CONFLICT (user_id) DO UPDATE SET
        nome_completo = COALESCE(EXCLUDED.nome_completo, candidatos.nome_completo),
        email = COALESCE(EXCLUDED.email, candidatos.email),
        telefone = COALESCE(EXCLUDED.telefone, candidatos.telefone);
      
      -- Delete from internal_profiles
      DELETE FROM internal_profiles WHERE user_id = NEW.id;
    
    -- Transition from perfil_interno to colaborador
    ELSIF OLD.role = 'perfil_interno' AND NEW.role = 'colaborador' THEN
      -- Get data from internal_profiles
      SELECT nome_completo, email, phone, cpf, cargo
      INTO v_nome_completo, v_email, v_telefone, v_cpf, v_cargo
      FROM internal_profiles
      WHERE user_id = NEW.id;
      
      -- Insert into colaboradores with data from internal_profiles
      INSERT INTO colaboradores (user_id, nome_completo, email, telefone, cpf, cargo, status_colaborador)
      VALUES (
        NEW.id, 
        COALESCE(v_nome_completo, NEW.nome_completo), 
        COALESCE(v_email, NEW.email), 
        COALESCE(v_telefone, NEW.phone),
        NULLIF(v_cpf, ''),
        v_cargo,
        'ativo'
      )
      ON CONFLICT (user_id) DO UPDATE SET
        nome_completo = COALESCE(EXCLUDED.nome_completo, colaboradores.nome_completo),
        email = COALESCE(EXCLUDED.email, colaboradores.email),
        telefone = COALESCE(EXCLUDED.telefone, colaboradores.telefone),
        cpf = COALESCE(EXCLUDED.cpf, colaboradores.cpf),
        cargo = COALESCE(EXCLUDED.cargo, colaboradores.cargo),
        status_colaborador = 'ativo';
      
      -- Delete from internal_profiles
      DELETE FROM internal_profiles WHERE user_id = NEW.id;
    
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;