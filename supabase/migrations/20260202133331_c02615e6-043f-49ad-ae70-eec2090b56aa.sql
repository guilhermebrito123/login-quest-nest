-- Criar função RPC para atualizar paga_por com bypass do trigger de bloqueio
CREATE OR REPLACE FUNCTION public.sync_paga_por_com_ok_pagamento_por()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  updated_count INTEGER;
BEGIN
  -- Ativar bypass do trigger de bloqueio
  PERFORM set_config('app.rpc_call', 'true', true);
  
  UPDATE public.diarias_temporarias 
  SET paga_por = ok_pagamento_por 
  WHERE ok_pagamento_por IS NOT NULL
    AND (paga_por IS DISTINCT FROM ok_pagamento_por);
  
  GET DIAGNOSTICS updated_count = ROW_COUNT;
  
  RETURN updated_count;
END;
$$;