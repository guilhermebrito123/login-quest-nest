-- Função para notificar quando um colaborador com cargo de liderança é criado/atualizado
CREATE OR REPLACE FUNCTION public.notificar_cargo_lideranca()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  cargo_info RECORD;
  colaborador_email TEXT;
  user_id_target UUID;
BEGIN
  -- Buscar informações do cargo
  SELECT nome, is_lideranca INTO cargo_info
  FROM public.cargos
  WHERE id = NEW.cargo_id;
  
  -- Se o cargo for de liderança
  IF cargo_info.is_lideranca THEN
    -- Buscar o email do colaborador
    colaborador_email := NEW.email;
    
    -- Se o colaborador tiver email, buscar o user_id correspondente
    IF colaborador_email IS NOT NULL THEN
      SELECT id INTO user_id_target
      FROM auth.users
      WHERE email = colaborador_email
      LIMIT 1;
      
      -- Se encontrou o usuário, criar notificação
      IF user_id_target IS NOT NULL THEN
        INSERT INTO public.notificacoes (user_id, titulo, mensagem, tipo, link)
        VALUES (
          user_id_target,
          'Novo Cargo de Liderança',
          'Você foi designado para o cargo de ' || cargo_info.nome || '. Agora você tem responsabilidades de liderança e pode acompanhar o andamento dos contratos vinculados.',
          'info',
          '/dashboard'
        );
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Trigger para notificar quando colaborador com cargo de liderança é criado
CREATE TRIGGER trigger_notificar_cargo_lideranca_insert
  AFTER INSERT ON public.colaboradores
  FOR EACH ROW
  WHEN (NEW.cargo_id IS NOT NULL)
  EXECUTE FUNCTION public.notificar_cargo_lideranca();

-- Trigger para notificar quando cargo de colaborador é atualizado para liderança
CREATE TRIGGER trigger_notificar_cargo_lideranca_update
  AFTER UPDATE ON public.colaboradores
  FOR EACH ROW
  WHEN (
    NEW.cargo_id IS NOT NULL 
    AND (OLD.cargo_id IS NULL OR OLD.cargo_id IS DISTINCT FROM NEW.cargo_id)
  )
  EXECUTE FUNCTION public.notificar_cargo_lideranca();