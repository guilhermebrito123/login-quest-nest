-- Corrigir função para usar full_name da tabela usuarios
CREATE OR REPLACE FUNCTION public.handle_usuario_role_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_nome_completo TEXT;
  v_email TEXT;
  v_phone TEXT;
  v_cpf TEXT;
  v_cargo TEXT;
BEGIN
  -- Transição de candidato para colaborador
  IF OLD.role = 'candidato' AND NEW.role = 'colaborador' THEN
    -- Buscar dados do candidato
    SELECT nome_completo, email, telefone INTO v_nome_completo, v_email, v_phone
    FROM candidatos WHERE user_id = NEW.id;
    
    -- Usar full_name da tabela usuarios como fallback
    v_nome_completo := COALESCE(NULLIF(v_nome_completo, ''), NEW.full_name, 'Nome não informado');
    v_email := COALESCE(NULLIF(v_email, ''), NEW.email);
    v_phone := COALESCE(NULLIF(v_phone, ''), NEW.phone);
    
    INSERT INTO colaboradores (user_id, nome_completo, email, telefone, status_colaborador)
    VALUES (NEW.id, v_nome_completo, v_email, v_phone, 'ativo')
    ON CONFLICT (user_id) DO UPDATE SET
      nome_completo = EXCLUDED.nome_completo,
      email = EXCLUDED.email,
      telefone = EXCLUDED.telefone,
      status_colaborador = 'ativo';
    
    DELETE FROM candidatos WHERE user_id = NEW.id;
  
  -- Transição de colaborador para candidato
  ELSIF OLD.role = 'colaborador' AND NEW.role = 'candidato' THEN
    SELECT nome_completo, email, telefone INTO v_nome_completo, v_email, v_phone
    FROM colaboradores WHERE user_id = NEW.id;
    
    v_nome_completo := COALESCE(NULLIF(v_nome_completo, ''), NEW.full_name, 'Nome não informado');
    v_email := COALESCE(NULLIF(v_email, ''), NEW.email);
    v_phone := COALESCE(NULLIF(v_phone, ''), NEW.phone);
    
    INSERT INTO candidatos (user_id, nome_completo, email, telefone)
    VALUES (NEW.id, v_nome_completo, v_email, v_phone)
    ON CONFLICT (user_id) DO UPDATE SET
      nome_completo = EXCLUDED.nome_completo,
      email = EXCLUDED.email,
      telefone = EXCLUDED.telefone;
    
    DELETE FROM colaboradores WHERE user_id = NEW.id;
  
  -- Transição de perfil_interno para colaborador
  ELSIF OLD.role = 'perfil_interno' AND NEW.role = 'colaborador' THEN
    SELECT nome_completo, email, phone, cpf, cargo INTO v_nome_completo, v_email, v_phone, v_cpf, v_cargo
    FROM internal_profiles WHERE user_id = NEW.id;
    
    v_nome_completo := COALESCE(NULLIF(v_nome_completo, ''), NEW.full_name, 'Nome não informado');
    v_email := COALESCE(NULLIF(v_email, ''), NEW.email);
    v_phone := COALESCE(NULLIF(v_phone, ''), NEW.phone);
    
    INSERT INTO colaboradores (user_id, nome_completo, email, telefone, cpf, cargo, status_colaborador)
    VALUES (NEW.id, v_nome_completo, v_email, v_phone, v_cpf, v_cargo, 'ativo')
    ON CONFLICT (user_id) DO UPDATE SET
      nome_completo = EXCLUDED.nome_completo,
      email = EXCLUDED.email,
      telefone = EXCLUDED.telefone,
      cpf = EXCLUDED.cpf,
      cargo = EXCLUDED.cargo,
      status_colaborador = 'ativo';
    
    DELETE FROM internal_profiles WHERE user_id = NEW.id;
  
  -- Transição de perfil_interno para candidato
  ELSIF OLD.role = 'perfil_interno' AND NEW.role = 'candidato' THEN
    SELECT nome_completo, email, phone INTO v_nome_completo, v_email, v_phone
    FROM internal_profiles WHERE user_id = NEW.id;
    
    v_nome_completo := COALESCE(NULLIF(v_nome_completo, ''), NEW.full_name, 'Nome não informado');
    v_email := COALESCE(NULLIF(v_email, ''), NEW.email);
    v_phone := COALESCE(NULLIF(v_phone, ''), NEW.phone);
    
    INSERT INTO candidatos (user_id, nome_completo, email, telefone)
    VALUES (NEW.id, v_nome_completo, v_email, v_phone)
    ON CONFLICT (user_id) DO UPDATE SET
      nome_completo = EXCLUDED.nome_completo,
      email = EXCLUDED.email,
      telefone = EXCLUDED.telefone;
    
    DELETE FROM internal_profiles WHERE user_id = NEW.id;
  
  -- Transição de colaborador para perfil_interno
  ELSIF OLD.role = 'colaborador' AND NEW.role = 'perfil_interno' THEN
    SELECT nome_completo, email, telefone, cpf, cargo INTO v_nome_completo, v_email, v_phone, v_cpf, v_cargo
    FROM colaboradores WHERE user_id = NEW.id;
    
    v_nome_completo := COALESCE(NULLIF(v_nome_completo, ''), NEW.full_name);
    v_email := COALESCE(NULLIF(v_email, ''), NEW.email);
    v_phone := COALESCE(NULLIF(v_phone, ''), NEW.phone);
    
    INSERT INTO internal_profiles (user_id, nome_completo, email, phone, cpf, cargo, nivel_acesso)
    VALUES (NEW.id, v_nome_completo, v_email, v_phone, v_cpf, v_cargo, 'cliente_view')
    ON CONFLICT (user_id) DO UPDATE SET
      nome_completo = EXCLUDED.nome_completo,
      email = EXCLUDED.email,
      phone = EXCLUDED.phone,
      cpf = EXCLUDED.cpf,
      cargo = EXCLUDED.cargo;
    
    DELETE FROM colaboradores WHERE user_id = NEW.id;
  
  -- Transição de candidato para perfil_interno
  ELSIF OLD.role = 'candidato' AND NEW.role = 'perfil_interno' THEN
    SELECT nome_completo, email, telefone INTO v_nome_completo, v_email, v_phone
    FROM candidatos WHERE user_id = NEW.id;
    
    v_nome_completo := COALESCE(NULLIF(v_nome_completo, ''), NEW.full_name);
    v_email := COALESCE(NULLIF(v_email, ''), NEW.email);
    v_phone := COALESCE(NULLIF(v_phone, ''), NEW.phone);
    
    INSERT INTO internal_profiles (user_id, nome_completo, email, phone, nivel_acesso)
    VALUES (NEW.id, v_nome_completo, v_email, v_phone, 'cliente_view')
    ON CONFLICT (user_id) DO UPDATE SET
      nome_completo = EXCLUDED.nome_completo,
      email = EXCLUDED.email,
      phone = EXCLUDED.phone;
    
    DELETE FROM candidatos WHERE user_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$;