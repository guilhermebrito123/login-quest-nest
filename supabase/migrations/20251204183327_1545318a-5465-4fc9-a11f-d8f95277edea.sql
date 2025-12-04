-- Função para limpar registros antigos da tabela diarias
CREATE OR REPLACE FUNCTION public.limpar_diarias_antigas()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_data_limite DATE;
BEGIN
  -- Calcular data limite (1 ano atrás a partir de hoje no timezone brasileiro)
  v_data_limite := ((now() AT TIME ZONE 'America/Sao_Paulo')::DATE - INTERVAL '1 year')::DATE;
  
  -- Deletar registros com created_at anterior ao limite
  DELETE FROM public.diarias
  WHERE (created_at AT TIME ZONE 'America/Sao_Paulo')::DATE < v_data_limite;
END;
$$;

-- Função para limpar registros antigos da tabela diarias_temporarias
CREATE OR REPLACE FUNCTION public.limpar_diarias_temporarias_antigas()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_data_limite DATE;
BEGIN
  -- Calcular data limite (1 ano atrás a partir de hoje no timezone brasileiro)
  v_data_limite := ((now() AT TIME ZONE 'America/Sao_Paulo')::DATE - INTERVAL '1 year')::DATE;
  
  -- Deletar registros com created_at anterior ao limite
  DELETE FROM public.diarias_temporarias
  WHERE (created_at AT TIME ZONE 'America/Sao_Paulo')::DATE < v_data_limite;
END;
$$;