
CREATE OR REPLACE FUNCTION public.trg_proteger_observacao_lancamento()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _level internal_access_level;
BEGIN
  SELECT nivel_acesso INTO _level
  FROM internal_profiles
  WHERE user_id = auth.uid();

  IF _level IS NULL OR _level NOT IN ('admin', 'gestor_financeiro', 'assistente_financeiro') THEN
    IF TG_OP = 'INSERT' THEN
      NEW.observacao_lancamento := NULL;
    ELSIF TG_OP = 'UPDATE' THEN
      NEW.observacao_lancamento := OLD.observacao_lancamento;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_proteger_observacao_lancamento
BEFORE INSERT OR UPDATE ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.trg_proteger_observacao_lancamento();
