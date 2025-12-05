-- Add required CPF column to diaristas table
ALTER TABLE public.diaristas
ADD COLUMN cpf text NOT NULL DEFAULT '';