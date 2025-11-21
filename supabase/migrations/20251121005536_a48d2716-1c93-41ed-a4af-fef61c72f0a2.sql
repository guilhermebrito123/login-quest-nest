-- Remove unique constraint duplicada que conflita com a constraint de exclusão
ALTER TABLE public.posto_dias_vagos
DROP CONSTRAINT IF EXISTS posto_dias_vagos_posto_servico_id_data_key;