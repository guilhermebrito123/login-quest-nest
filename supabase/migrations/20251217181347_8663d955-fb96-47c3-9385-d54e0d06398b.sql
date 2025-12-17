
-- Update the handle_usuario_role_transition function to handle transition to perfil_interno
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
      -- Update internal_profiles with data from usuarios
      UPDATE public.internal_profiles
      SET 
        nome_completo = NEW.full_name,
        email = NEW.email,
        phone = NEW.phone,
        updated_at = now()
      WHERE user_id = NEW.id;
      
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
      INSERT INTO public.candidatos (id, nome_completo, email, telefone)
      VALUES (NEW.id, NEW.full_name, NEW.email, NEW.phone)
      ON CONFLICT (id) DO NOTHING;
      
      -- Clear internal_profiles data
      UPDATE public.internal_profiles
      SET 
        nome_completo = NULL,
        email = NULL,
        phone = NULL,
        updated_at = now()
      WHERE user_id = NEW.id;
    
    -- Transition FROM perfil_interno TO colaborador
    ELSIF OLD.role = 'perfil_interno' AND NEW.role = 'colaborador' THEN
      INSERT INTO public.colaboradores (id, nome_completo, email, telefone, status_colaborador)
      VALUES (NEW.id, NEW.full_name, NEW.email, NEW.phone, 'ativo'::status_colaborador)
      ON CONFLICT (id) DO NOTHING;
      
      -- Clear internal_profiles data
      UPDATE public.internal_profiles
      SET 
        nome_completo = NULL,
        email = NULL,
        phone = NULL,
        updated_at = now()
      WHERE user_id = NEW.id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;
