-- Renomear coluna beneficios para outros_beneficios na tabela postos_servico
ALTER TABLE public.postos_servico
RENAME COLUMN beneficios TO outros_beneficios;