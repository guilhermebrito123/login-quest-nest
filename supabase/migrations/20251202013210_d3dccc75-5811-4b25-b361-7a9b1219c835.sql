-- Remover constraint antiga e adicionar com CASCADE
ALTER TABLE public.diarias_temporarias
DROP CONSTRAINT IF EXISTS diarias_temporarias_posto_servico_id_fkey;

ALTER TABLE public.diarias_temporarias
ADD CONSTRAINT diarias_temporarias_posto_servico_id_fkey
FOREIGN KEY (posto_servico_id)
REFERENCES public.postos_servico(id)
ON DELETE CASCADE;