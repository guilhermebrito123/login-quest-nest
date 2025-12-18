-- Corrigir função handle_usuario_role_transition para usar COALESCE no CPF
CREATE OR REPLACE FUNCTION public.handle_usuario_role_transition()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_nome_completo TEXT;
  v_email TEXT;
  v_telefone TEXT;
  v_cpf TEXT;
  v_cargo TEXT;
  v_old_role user_type;
  v_new_role user_type;
BEGIN
  v_old_role := OLD.role;
  v_new_role := NEW.role;
  
  -- Se a role não mudou, não fazer nada
  IF v_old_role = v_new_role THEN
    RETURN NEW;
  END IF;
  
  -- Buscar dados da tabela de origem baseado na role antiga
  IF v_old_role = 'candidato' THEN
    SELECT nome_completo, email, telefone, NULL, NULL
    INTO v_nome_completo, v_email, v_telefone, v_cpf, v_cargo
    FROM public.candidatos
    WHERE id = NEW.id OR user_id = NEW.id;
    
  ELSIF v_old_role = 'colaborador' THEN
    SELECT nome_completo, email, telefone, cpf, cargo
    INTO v_nome_completo, v_email, v_telefone, v_cpf, v_cargo
    FROM public.colaboradores
    WHERE id = NEW.id OR user_id = NEW.id;
    
  ELSIF v_old_role = 'perfil_interno' THEN
    SELECT nome_completo, email, phone, cpf, cargo
    INTO v_nome_completo, v_email, v_telefone, v_cpf, v_cargo
    FROM public.internal_profiles
    WHERE user_id = NEW.id;
  END IF;
  
  -- Usar dados do usuarios como fallback se não encontrou na tabela de origem
  v_nome_completo := COALESCE(v_nome_completo, NEW.full_name, '');
  v_email := COALESCE(v_email, NEW.email, '');
  v_telefone := COALESCE(v_telefone, NEW.phone, '');
  v_cpf := COALESCE(v_cpf, '');
  v_cargo := COALESCE(v_cargo, '');
  
  -- Criar registro na tabela de destino baseado na nova role
  IF v_new_role = 'candidato' THEN
    INSERT INTO public.candidatos (
      id, user_id, nome_completo, email, telefone, celular, cidade, estado
    ) VALUES (
      NEW.id, NEW.id, v_nome_completo, v_email, v_telefone, v_telefone, 'Não informada', 'Não informado'
    )
    ON CONFLICT (id) DO UPDATE SET
      nome_completo = EXCLUDED.nome_completo,
      email = EXCLUDED.email,
      telefone = EXCLUDED.telefone,
      updated_at = now();
      
  ELSIF v_new_role = 'colaborador' THEN
    INSERT INTO public.colaboradores (
      id, user_id, nome_completo, email, telefone, cpf, cargo, status_colaborador
    ) VALUES (
      NEW.id, NEW.id, v_nome_completo, v_email, v_telefone, v_cpf, v_cargo, 'ativo'
    )
    ON CONFLICT (id) DO UPDATE SET
      nome_completo = EXCLUDED.nome_completo,
      email = EXCLUDED.email,
      telefone = EXCLUDED.telefone,
      cpf = EXCLUDED.cpf,
      cargo = EXCLUDED.cargo,
      updated_at = now();
      
  ELSIF v_new_role = 'perfil_interno' THEN
    INSERT INTO public.internal_profiles (
      user_id, nome_completo, email, phone, cpf, cargo, nivel_acesso
    ) VALUES (
      NEW.id, v_nome_completo, v_email, v_telefone, v_cpf, v_cargo, 'cliente_view'
    )
    ON CONFLICT (user_id) DO UPDATE SET
      nome_completo = EXCLUDED.nome_completo,
      email = EXCLUDED.email,
      phone = EXCLUDED.phone,
      cpf = EXCLUDED.cpf,
      cargo = EXCLUDED.cargo,
      updated_at = now();
  END IF;
  
  RETURN NEW;
END;
$function$;