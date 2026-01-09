-- Create function to block edits when status is not "Aguardando confirmacao"
CREATE OR REPLACE FUNCTION public.bloquear_edicao_diaria_temporaria()
RETURNS TRIGGER AS $$
BEGIN
  -- Only allow edits if current status is "Aguardando confirmacao"
  IF OLD.status != 'Aguardando confirmacao' THEN
    RAISE EXCEPTION 'Diária não pode ser editada quando o status é "%". Apenas diárias com status "Aguardando confirmacao" podem ser editadas.', OLD.status;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to enforce the edit restriction
DROP TRIGGER IF EXISTS bloquear_edicao_diaria_temporaria_trigger ON public.diarias_temporarias;
CREATE TRIGGER bloquear_edicao_diaria_temporaria_trigger
  BEFORE UPDATE ON public.diarias_temporarias
  FOR EACH ROW
  EXECUTE FUNCTION public.bloquear_edicao_diaria_temporaria();