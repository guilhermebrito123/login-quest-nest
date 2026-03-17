
CREATE OR REPLACE FUNCTION public.set_cost_center_from_colaborador_cobrindo()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- On UPDATE: block changes to cost_center_id once set
  IF TG_OP = 'UPDATE' AND OLD.cost_center_id IS DISTINCT FROM NEW.cost_center_id THEN
    RAISE EXCEPTION 'O centro de custo não pode ser alterado após a criação da hora extra';
  END IF;

  RETURN NEW;
END;
$$;
