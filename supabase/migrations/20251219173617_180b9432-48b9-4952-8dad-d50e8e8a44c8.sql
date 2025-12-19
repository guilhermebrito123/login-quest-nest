-- Add itens_adicionais to clientes table
ALTER TABLE public.clientes 
ADD COLUMN itens_adicionais TEXT;

-- Add adc_insalubridade_percentual and acumulo_funcao_percentual to postos_servico table
ALTER TABLE public.postos_servico 
ADD COLUMN adc_insalubridade_percentual NUMERIC,
ADD COLUMN acumulo_funcao_percentual NUMERIC;