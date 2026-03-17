
CREATE OR REPLACE FUNCTION public.set_cost_center_from_colaborador_cobrindo()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cost_center_id uuid;
BEGIN
  -- On INSERT: auto-fill cost_center_id only for specific operations (from colaborador_cobrindo)
  IF TG_OP = 'INSERT' AND NEW.operacao IN ('demanda_extra', 'bonus', 'dobra_turno', 'extensao_jornada') THEN
    SELECT cc.cost_center_id INTO v_cost_center_id
    FROM public.colaboradores_convenia cc
    WHERE cc.id = NEW.colaborador_cobrindo_id;

    IF v_cost_center_id IS NULL THEN
      RAISE EXCEPTION 'Colaborador cobrindo (%) não possui centro de custo definido', NEW.colaborador_cobrindo_id;
    END IF;

    NEW.cost_center_id := v_cost_center_id;
  END IF;

  -- On UPDATE: block changes to cost_center_id once set
  IF TG_OP = 'UPDATE' AND OLD.cost_center_id IS DISTINCT FROM NEW.cost_center_id THEN
    RAISE EXCEPTION 'O centro de custo não pode ser alterado após a criação da hora extra';
  END IF;

  RETURN NEW;
END;
$$;
