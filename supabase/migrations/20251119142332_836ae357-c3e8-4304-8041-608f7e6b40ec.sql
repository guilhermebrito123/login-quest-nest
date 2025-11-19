-- Alterar coluna dias_semana para integer[] em postos_servico
ALTER TABLE public.postos_servico 
ALTER COLUMN dias_semana TYPE integer[] 
USING dias_semana::integer[];

COMMENT ON COLUMN public.postos_servico.dias_semana IS 'Array de índices dos dias da semana (0=domingo, 1=segunda, ..., 6=sábado)';