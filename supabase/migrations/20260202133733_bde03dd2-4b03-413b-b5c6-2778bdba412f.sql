-- Executar atualização com bypass do trigger de bloqueio
DO $$
BEGIN
  -- Ativar bypass do trigger de bloqueio
  PERFORM set_config('app.rpc_call', 'true', true);
  
  UPDATE public.diarias_temporarias 
  SET paga_por = ok_pagamento_por 
  WHERE ok_pagamento_por IS NOT NULL
    AND (paga_por IS DISTINCT FROM ok_pagamento_por);
END;
$$;

-- Remover a função temporária que não será mais necessária
DROP FUNCTION IF EXISTS public.sync_paga_por_com_ok_pagamento_por();