
-- Trigger to auto-set cost_center_id from colaborador_cobrindo's cost_center on INSERT
-- when operacao is demanda_extra, bonus, dobra_turno, extensao_jornada
-- and to prevent cost_center_id changes on UPDATE for all cases

CREATE OR REPLACE FUNCTION public.set_cost_center_from_colaborador_cobrindo()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cost_center_id uuid;
BEGIN
  -- On INSERT: auto-set cost_center_id for specific operacao types
  IF TG_OP = 'INSERT' AND NEW.operacao IN ('demanda_extra', 'bonus', 'dobra_turno', 'extensao_jornada') THEN
    SELECT cc.cost_center_id INTO v_cost_center_id
    FROM public.colaboradores_convenia cc
    WHERE cc.id = NEW.colaborador_cobrindo_id;

    IF v_cost_center_id IS NULL THEN
      RAISE EXCEPTION 'Colaborador cobrindo (%) não possui centro de custo cadastrado', NEW.colaborador_cobrindo_id;
    END IF;

    NEW.cost_center_id := v_cost_center_id;
  END IF;

  -- On UPDATE: prevent cost_center_id from being changed
  IF TG_OP = 'UPDATE' AND OLD.cost_center_id IS DISTINCT FROM NEW.cost_center_id THEN
    RAISE EXCEPTION 'O centro de custo não pode ser alterado após a criação da hora extra';
  END IF;

  RETURN NEW;
END;
$$;

-- Drop existing trigger if any, then create
DROP TRIGGER IF EXISTS trg_set_cost_center_colaborador_cobrindo ON public.horas_extras;

CREATE TRIGGER trg_set_cost_center_colaborador_cobrindo
  BEFORE INSERT OR UPDATE ON public.horas_extras
  FOR EACH ROW
  EXECUTE FUNCTION public.set_cost_center_from_colaborador_cobrindo();
