-- Alterar dias_semana de text[] para integer[] em postos_servico
ALTER TABLE public.postos_servico 
ALTER COLUMN dias_semana TYPE integer[] USING dias_semana::integer[];

-- Comentário para documentação
COMMENT ON COLUMN public.postos_servico.dias_semana IS 'Dias da semana em que o posto opera (0=domingo, 1=segunda, ..., 6=sábado)';