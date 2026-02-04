-- Adicionar valor "SERVIÇO EXTRA" ao enum motivo_vago_type
ALTER TYPE public.motivo_vago_type ADD VALUE IF NOT EXISTS 'SERVIÇO EXTRA';