
-- Desabilitar bloqueio de edição de campos estruturais em diarias_temporarias
CREATE OR REPLACE FUNCTION public.bloquear_edicao_diaria_temporaria()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  -- Bloqueio de campos estruturais removido - edição livre permitida
  RETURN NEW;
END;
$$;
