
-- Ensure CPF is correctly preserved when transitioning from perfil_interno -> colaborador
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
  IF OLD.role IS DISTINCT FROM NEW.role THEN

    IF OLD.role = 'candidato' THEN
      SELECT nome_completo, email, telefone
        INTO v_nome_completo, v_email, v_telefone
      FROM candidatos
      WHERE user_id = NEW.id;

      DELETE FROM candidatos WHERE user_id = NEW.id;

      IF NEW.role = 'colaborador' THEN
        INSERT INTO colaboradores (user_id, nome_completo, email, telefone, status_colaborador, cpf)
        VALUES (
          NEW.id,
          COALESCE(v_nome_completo, NEW.full_name),
          COALESCE(v_email, NEW.email),
          COALESCE(v_telefone, NEW.phone),
          'ativo',
          ''
        )
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, colaboradores.nome_completo),
          email = COALESCE(EXCLUDED.email, colaboradores.email),
          telefone = COALESCE(EXCLUDED.telefone, colaboradores.telefone);

      ELSIF NEW.role = 'perfil_interno' THEN
        INSERT INTO internal_profiles (user_id, nome_completo, email, phone, nivel_acesso)
        VALUES (
          NEW.id,
          COALESCE(v_nome_completo, NEW.full_name),
          COALESCE(v_email, NEW.email),
          COALESCE(v_telefone, NEW.phone),
          'cliente_view'
        )
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, internal_profiles.nome_completo),
          email = COALESCE(EXCLUDED.email, internal_profiles.email),
          phone = COALESCE(EXCLUDED.phone, internal_profiles.phone);
      END IF;

    ELSIF OLD.role = 'colaborador' THEN
      SELECT nome_completo, email, telefone, cpf
        INTO v_nome_completo, v_email, v_telefone, v_cpf
      FROM colaboradores
      WHERE user_id = NEW.id;

      DELETE FROM colaboradores WHERE user_id = NEW.id;

      IF NEW.role = 'candidato' THEN
        INSERT INTO candidatos (user_id, nome_completo, email, telefone)
        VALUES (
          NEW.id,
          COALESCE(v_nome_completo, NEW.full_name),
          COALESCE(v_email, NEW.email),
          COALESCE(v_telefone, NEW.phone)
        )
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, candidatos.nome_completo),
          email = COALESCE(EXCLUDED.email, candidatos.email),
          telefone = COALESCE(EXCLUDED.telefone, candidatos.telefone);

      ELSIF NEW.role = 'perfil_interno' THEN
        INSERT INTO internal_profiles (user_id, nome_completo, email, phone, nivel_acesso, cpf)
        VALUES (
          NEW.id,
          COALESCE(v_nome_completo, NEW.full_name),
          COALESCE(v_email, NEW.email),
          COALESCE(v_telefone, NEW.phone),
          'cliente_view',
          NULLIF(v_cpf, '')
        )
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, internal_profiles.nome_completo),
          email = COALESCE(EXCLUDED.email, internal_profiles.email),
          phone = COALESCE(EXCLUDED.phone, internal_profiles.phone),
          cpf = COALESCE(EXCLUDED.cpf, internal_profiles.cpf);
      END IF;

    ELSIF OLD.role = 'perfil_interno' THEN
      SELECT nome_completo, email, phone, cpf
        INTO v_nome_completo, v_email, v_telefone, v_cpf
      FROM internal_profiles
      WHERE user_id = NEW.id;

      DELETE FROM internal_profiles WHERE user_id = NEW.id;

      IF NEW.role = 'candidato' THEN
        INSERT INTO candidatos (user_id, nome_completo, email, telefone)
        VALUES (
          NEW.id,
          COALESCE(v_nome_completo, NEW.full_name),
          COALESCE(v_email, NEW.email),
          COALESCE(v_telefone, NEW.phone)
        )
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, candidatos.nome_completo),
          email = COALESCE(EXCLUDED.email, candidatos.email),
          telefone = COALESCE(EXCLUDED.telefone, candidatos.telefone);

      ELSIF NEW.role = 'colaborador' THEN
        INSERT INTO colaboradores (user_id, nome_completo, email, telefone, status_colaborador, cpf)
        VALUES (
          NEW.id,
          COALESCE(v_nome_completo, NEW.full_name),
          COALESCE(v_email, NEW.email),
          COALESCE(v_telefone, NEW.phone),
          'ativo',
          COALESCE(NULLIF(v_cpf, ''), '')
        )
        ON CONFLICT (user_id) DO UPDATE SET
          nome_completo = COALESCE(EXCLUDED.nome_completo, colaboradores.nome_completo),
          email = COALESCE(EXCLUDED.email, colaboradores.email),
          telefone = COALESCE(EXCLUDED.telefone, colaboradores.telefone),
          cpf = COALESCE(NULLIF(EXCLUDED.cpf, ''), colaboradores.cpf);
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;
