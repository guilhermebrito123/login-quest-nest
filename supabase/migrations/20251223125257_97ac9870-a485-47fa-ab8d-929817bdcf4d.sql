-- Adicionar campo para verificar se o PIX pertence ao próprio diarista
ALTER TABLE public.diaristas 
ADD COLUMN pix_pertence_beneficiario boolean DEFAULT NULL;