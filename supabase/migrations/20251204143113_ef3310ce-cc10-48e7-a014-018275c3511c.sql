-- Adicionar valor "paga" ao enum status_diaria
ALTER TYPE status_diaria ADD VALUE IF NOT EXISTS 'Paga';