-- Make unidade NOT NULL
ALTER TABLE public.diarias_temporarias 
ALTER COLUMN unidade SET NOT NULL;

-- Function to validate required fields conditionally
CREATE OR REPLACE FUNCTION public.validate_diarias_temporarias_required_fields()
RETURNS TRIGGER AS $$
BEGIN
  -- colaborador_demitido_nome is required when demissao = true
  IF NEW.demissao = true AND (NEW.colaborador_demitido_nome IS NULL OR NEW.colaborador_demitido_nome = '') THEN
    RAISE EXCEPTION 'O campo "colaborador demitido" é obrigatório quando for demissão';
  END IF;
  
  -- colaborador_falecido is required when licenca_nojo = true
  IF NEW.licenca_nojo = true AND (NEW.colaborador_falecido IS NULL OR NEW.colaborador_falecido = '') THEN
    RAISE EXCEPTION 'O campo "colaborador_falecido" é obrigatório quando for licença nojo (falecimento)';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS validate_diarias_temporarias_required_fields_trigger ON public.diarias_temporarias;

-- Create trigger
CREATE TRIGGER validate_diarias_temporarias_required_fields_trigger
BEFORE INSERT OR UPDATE ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.validate_diarias_temporarias_required_fields();