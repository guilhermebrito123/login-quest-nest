-- Função para limpar registros de presença com mais de 1 ano (timezone brasileiro)
CREATE OR REPLACE FUNCTION public.limpar_presencas_antigas()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_data_limite DATE;
BEGIN
  -- Calcular data limite (1 ano atrás a partir de hoje no timezone brasileiro)
  v_data_limite := (now() AT TIME ZONE 'America/Sao_Paulo')::DATE - INTERVAL '1 year';
  
  -- Deletar registros com data anterior ao limite
  DELETE FROM public.presencas
  WHERE data < v_data_limite;
END;
$function$;