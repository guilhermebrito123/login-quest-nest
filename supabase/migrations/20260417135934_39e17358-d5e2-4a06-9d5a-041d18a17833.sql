-- Trigger para impedir que campos sensíveis sejam alterados por quem não é o responsável (interno ≠ cliente_view)
-- Campos sensíveis: status, responsavel_id, solicitante_id, data_fechamento, resolvido_em, resolvido_por

CREATE OR REPLACE FUNCTION public.chamados_enforce_update_rules()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_level internal_access_level;
  v_is_responsavel boolean;
  v_is_solicitante boolean;
  v_is_colaborador boolean;
BEGIN
  v_level := current_internal_access_level();
  v_is_responsavel := (OLD.responsavel_id IS NOT NULL AND OLD.responsavel_id = auth.uid());
  v_is_solicitante := (OLD.solicitante_id = auth.uid());

  SELECT EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = auth.uid() AND u.role = 'colaborador'::user_type
  ) INTO v_is_colaborador;

  -- Campos que NUNCA podem ser alterados via UPDATE pelo solicitante colaborador
  -- Internos só podem alterar status/resolução se forem o responsável
  
  -- 1) status: só o responsável (interno ≠ cliente_view) pode alterar
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF NOT (
      v_level IS NOT NULL
      AND v_level <> 'cliente_view'::internal_access_level
      AND v_is_responsavel
    ) THEN
      RAISE EXCEPTION 'Apenas o responsável pelo chamado (perfil interno) pode alterar o status'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  -- 2) data_fechamento, resolvido_em, resolvido_por: só o responsável pode alterar
  IF (NEW.data_fechamento IS DISTINCT FROM OLD.data_fechamento)
     OR (NEW.resolvido_em IS DISTINCT FROM OLD.resolvido_em)
     OR (NEW.resolvido_por IS DISTINCT FROM OLD.resolvido_por) THEN
    IF NOT (
      v_level IS NOT NULL
      AND v_level <> 'cliente_view'::internal_access_level
      AND v_is_responsavel
    ) THEN
      RAISE EXCEPTION 'Apenas o responsável pelo chamado pode alterar dados de resolução/fechamento'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  -- 3) responsavel_id: somente perfil interno (≠ cliente_view) pode alterar
  IF NEW.responsavel_id IS DISTINCT FROM OLD.responsavel_id THEN
    IF NOT (
      v_level IS NOT NULL
      AND v_level <> 'cliente_view'::internal_access_level
    ) THEN
      RAISE EXCEPTION 'Apenas perfis internos podem alterar o responsável pelo chamado'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  -- 4) solicitante_id: nunca pode ser alterado
  IF NEW.solicitante_id IS DISTINCT FROM OLD.solicitante_id THEN
    RAISE EXCEPTION 'O solicitante de um chamado não pode ser alterado'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS chamados_enforce_update_rules_trg ON public.chamados;
CREATE TRIGGER chamados_enforce_update_rules_trg
BEFORE UPDATE ON public.chamados
FOR EACH ROW
EXECUTE FUNCTION public.chamados_enforce_update_rules();