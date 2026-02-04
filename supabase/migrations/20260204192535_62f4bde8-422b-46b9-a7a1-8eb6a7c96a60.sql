-- Adicionar coluna reserva_tecnica à tabela diaristas
ALTER TABLE public.diaristas 
ADD COLUMN IF NOT EXISTS reserva_tecnica boolean DEFAULT false;

-- Atualizar todos os registros existentes para false
UPDATE public.diaristas SET reserva_tecnica = false WHERE reserva_tecnica IS NULL;