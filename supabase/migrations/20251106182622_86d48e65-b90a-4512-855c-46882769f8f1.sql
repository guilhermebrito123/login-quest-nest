-- Remover constraint antiga
ALTER TABLE chamados DROP CONSTRAINT IF EXISTS chamados_status_check;

-- Adicionar constraint com os valores corretos
ALTER TABLE chamados 
ADD CONSTRAINT chamados_status_check 
CHECK (status IN ('aberto', 'em_andamento', 'pendente', 'concluido'));