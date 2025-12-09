-- Remover a constraint existente
ALTER TABLE public.diarias_temporarias
DROP CONSTRAINT IF EXISTS diarias_temporarias_diarista_id_fkey;

-- Adicionar nova constraint com ON DELETE CASCADE
ALTER TABLE public.diarias_temporarias
ADD CONSTRAINT diarias_temporarias_diarista_id_fkey
FOREIGN KEY (diarista_id) REFERENCES public.diaristas(id) ON DELETE CASCADE;