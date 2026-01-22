-- Adiciona coluna JSONB para armazenar o payload bruto do centro de custo
ALTER TABLE colaboradores_convenia
ADD COLUMN cost_center JSONB NULL;