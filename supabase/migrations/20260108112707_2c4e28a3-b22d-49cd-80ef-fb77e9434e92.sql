-- Function to handle ok_pagamento = false and status transitions
CREATE OR REPLACE FUNCTION public.handle_ok_pagamento_false_transition()
RETURNS TRIGGER AS $$
BEGIN
  -- When ok_pagamento changes to false and status is "Lançada para pagamento", change status to "Aprovada"
  IF OLD.ok_pagamento IS DISTINCT FROM NEW.ok_pagamento 
     AND NEW.ok_pagamento = false 
     AND OLD.status = 'Lançada para pagamento' THEN
    NEW.status := 'Aprovada';
  END IF;
  
  -- When status changes from "Aprovada" to "Lançada para pagamento", clear payment observation fields
  IF OLD.status = 'Aprovada' 
     AND NEW.status = 'Lançada para pagamento' THEN
    NEW.observacao_pagamento := NULL;
    NEW.outros_motivos_reprovacao_pagamento := NULL;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS handle_ok_pagamento_false_transition_trigger ON public.diarias_temporarias;

-- Create trigger
CREATE TRIGGER handle_ok_pagamento_false_transition_trigger
BEFORE UPDATE ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.handle_ok_pagamento_false_transition();