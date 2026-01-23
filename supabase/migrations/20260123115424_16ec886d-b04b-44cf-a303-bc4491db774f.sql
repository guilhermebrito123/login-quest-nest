-- Criar foreign key entre colaboradores_convenia.cost_center_id e cost_center.convenia_id
-- Primeiro, garantir que cost_center_id em colaboradores_convenia referencie corretamente cost_center.convenia_id

ALTER TABLE colaboradores_convenia
ADD CONSTRAINT colaboradores_convenia_cost_center_fk 
FOREIGN KEY (cost_center_id) 
REFERENCES cost_center(convenia_id)
ON UPDATE CASCADE
ON DELETE SET NULL;