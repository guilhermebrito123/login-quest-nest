-- Ajustar regras de UPDATE em chamados:
-- Qualquer perfil interno (≠ cliente_view) pode alterar qualquer atributo, exceto solicitante_id (imutável).
-- Colaboradores continuam podendo editar campos "neutros" do próprio chamado, mas não status/responsavel/resolução/solicitante.

CREATE OR REPLACE FUNCTION public.chamados_enforce_update_rules()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_level internal_access_level;
  v_is_internal_editor boolean;
BEGIN
  v_level := current_internal_access_level();
  v_is_internal_editor := (v_level IS NOT NULL AND v_level <> 'cliente_view'::internal_access_level);

  -- 1) status: somente perfis internos (≠ cliente_view)
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF NOT v_is_internal_editor THEN
      RAISE EXCEPTION 'Apenas perfis internos podem alterar o status do chamado'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  -- 2) data_fechamento, resolvido_em, resolvido_por: somente perfis internos (≠ cliente_view)
  IF (NEW.data_fechamento IS DISTINCT FROM OLD.data_fechamento)
     OR (NEW.resolvido_em IS DISTINCT FROM OLD.resolvido_em)
     OR (NEW.resolvido_por IS DISTINCT FROM OLD.resolvido_por) THEN
    IF NOT v_is_internal_editor THEN
      RAISE EXCEPTION 'Apenas perfis internos podem alterar dados de resolução/fechamento'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  -- 3) responsavel_id: somente perfis internos (≠ cliente_view)
  IF NEW.responsavel_id IS DISTINCT FROM OLD.responsavel_id THEN
    IF NOT v_is_internal_editor THEN
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