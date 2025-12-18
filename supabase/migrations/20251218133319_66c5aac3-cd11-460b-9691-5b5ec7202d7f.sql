-- Corrigir a função para DELETAR da tabela anterior ao invés de apenas limpar campos
CREATE OR REPLACE FUNCTION public.handle_usuario_role_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only process if role has changed
  IF OLD.role IS DISTINCT FROM NEW.role THEN
    
    -- Transition TO perfil_interno
    IF NEW.role = 'perfil_interno' THEN
      -- Insert into internal_profiles if not exists, or update if exists
      INSERT INTO public.internal_profiles (user_id, nome_completo, email, phone, nivel_acesso)
      VALUES (NEW.id, NEW.full_name, NEW.email, NEW.phone, 'cliente_view'::internal_access_level)
      ON CONFLICT (user_id) DO UPDATE SET
        nome_completo = EXCLUDED.nome_completo,
        email = EXCLUDED.email,
        phone = EXCLUDED.phone,
        updated_at = now();
      
      -- Delete from candidatos if exists
      DELETE FROM public.candidatos WHERE id = NEW.id;
      
      -- Delete from colaboradores if exists
      DELETE FROM public.colaboradores WHERE id = NEW.id;
    
    -- Transition FROM candidato TO colaborador
    ELSIF OLD.role = 'candidato' AND NEW.role = 'colaborador' THEN
      INSERT INTO public.colaboradores (id, nome_completo, email, telefone, status_colaborador)
      SELECT 
        c.id,
        c.nome_completo,
        c.email,
        COALESCE(c.telefone, c.celular),
        'ativo'::status_colaborador
      FROM public.candidatos c
      WHERE c.id = NEW.id
      ON CONFLICT (id) DO NOTHING;
      
      DELETE FROM public.candidatos WHERE id = NEW.id;
    
    -- Transition FROM colaborador TO candidato
    ELSIF OLD.role = 'colaborador' AND NEW.role = 'candidato' THEN
      INSERT INTO public.candidatos (id, nome_completo, email, telefone)
      SELECT 
        c.id,
        c.nome_completo,
        c.email,
        c.telefone
      FROM public.colaboradores c
      WHERE c.id = NEW.id
      ON CONFLICT (id) DO NOTHING;
      
      DELETE FROM public.colaboradores WHERE id = NEW.id;
    
    -- Transition FROM perfil_interno TO candidato
    ELSIF OLD.role = 'perfil_interno' AND NEW.role = 'candidato' THEN
      -- Get data from internal_profiles before deleting
      INSERT INTO public.candidatos (id, nome_completo, email, telefone)
      SELECT NEW.id, ip.nome_completo, ip.email, ip.phone
      FROM public.internal_profiles ip
      WHERE ip.user_id = NEW.id
      ON CONFLICT (id) DO UPDATE SET
        nome_completo = EXCLUDED.nome_completo,
        email = EXCLUDED.email,
        telefone = EXCLUDED.telefone;
      
      -- If no data in internal_profiles, use usuarios data
      INSERT INTO public.candidatos (id, nome_completo, email, telefone)
      VALUES (NEW.id, NEW.full_name, NEW.email, NEW.phone)
      ON CONFLICT (id) DO NOTHING;
      
      -- Delete from internal_profiles
      DELETE FROM public.internal_profiles WHERE user_id = NEW.id;
    
    -- Transition FROM perfil_interno TO colaborador
    ELSIF OLD.role = 'perfil_interno' AND NEW.role = 'colaborador' THEN
      -- Get data from internal_profiles before deleting
      INSERT INTO public.colaboradores (id, nome_completo, email, telefone, status_colaborador)
      SELECT NEW.id, ip.nome_completo, ip.email, ip.phone, 'ativo'::status_colaborador
      FROM public.internal_profiles ip
      WHERE ip.user_id = NEW.id
      ON CONFLICT (id) DO UPDATE SET
        nome_completo = EXCLUDED.nome_completo,
        email = EXCLUDED.email,
        telefone = EXCLUDED.telefone;
      
      -- If no data in internal_profiles, use usuarios data
      INSERT INTO public.colaboradores (id, nome_completo, email, telefone, status_colaborador)
      VALUES (NEW.id, NEW.full_name, NEW.email, NEW.phone, 'ativo'::status_colaborador)
      ON CONFLICT (id) DO NOTHING;
      
      -- Delete from internal_profiles
      DELETE FROM public.internal_profiles WHERE user_id = NEW.id;
    
    -- Transition FROM candidato TO perfil_interno
    ELSIF OLD.role = 'candidato' AND NEW.role = 'perfil_interno' THEN
      -- Get data from candidatos before deleting
      INSERT INTO public.internal_profiles (user_id, nome_completo, email, phone, nivel_acesso)
      SELECT c.id, c.nome_completo, c.email, COALESCE(c.telefone, c.celular), 'cliente_view'::internal_access_level
      FROM public.candidatos c
      WHERE c.id = NEW.id
      ON CONFLICT (user_id) DO UPDATE SET
        nome_completo = EXCLUDED.nome_completo,
        email = EXCLUDED.email,
        phone = EXCLUDED.phone,
        updated_at = now();
      
      -- If no data in candidatos, use usuarios data
      INSERT INTO public.internal_profiles (user_id, nome_completo, email, phone, nivel_acesso)
      VALUES (NEW.id, NEW.full_name, NEW.email, NEW.phone, 'cliente_view'::internal_access_level)
      ON CONFLICT (user_id) DO NOTHING;
      
      DELETE FROM public.candidatos WHERE id = NEW.id;
    
    -- Transition FROM colaborador TO perfil_interno
    ELSIF OLD.role = 'colaborador' AND NEW.role = 'perfil_interno' THEN
      -- Get data from colaboradores before deleting
      INSERT INTO public.internal_profiles (user_id, nome_completo, email, phone, nivel_acesso)
      SELECT c.id, c.nome_completo, c.email, c.telefone, 'cliente_view'::internal_access_level
      FROM public.colaboradores c
      WHERE c.id = NEW.id
      ON CONFLICT (user_id) DO UPDATE SET
        nome_completo = EXCLUDED.nome_completo,
        email = EXCLUDED.email,
        phone = EXCLUDED.phone,
        updated_at = now();
      
      -- If no data in colaboradores, use usuarios data
      INSERT INTO public.internal_profiles (user_id, nome_completo, email, phone, nivel_acesso)
      VALUES (NEW.id, NEW.full_name, NEW.email, NEW.phone, 'cliente_view'::internal_access_level)
      ON CONFLICT (user_id) DO NOTHING;
      
      DELETE FROM public.colaboradores WHERE id = NEW.id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;