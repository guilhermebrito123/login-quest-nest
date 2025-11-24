-- Criar função para limpar registros antigos de posto_dias_vagos
CREATE OR REPLACE FUNCTION public.limpar_posto_dias_vagos_antigos()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_data_limite DATE;
BEGIN
  -- Calcular data limite (1 ano atrás a partir de hoje no timezone brasileiro)
  v_data_limite := (now() AT TIME ZONE 'America/Sao_Paulo')::DATE - INTERVAL '1 year';
  
  -- Deletar registros com data anterior ao limite
  DELETE FROM public.posto_dias_vagos
  WHERE data < v_data_limite;
END;
$$;