-- Adicionar constraint para valores permitidos de escala em postos_servico
ALTER TABLE public.postos_servico 
DROP CONSTRAINT IF EXISTS postos_servico_escala_check;

ALTER TABLE public.postos_servico 
ADD CONSTRAINT postos_servico_escala_check 
CHECK (escala IN ('5x1', '5x2', '4x2', '6x1', '12x36', '18x36', '24x48') OR escala IS NULL);

COMMENT ON COLUMN public.postos_servico.escala IS 'Tipo de escala de trabalho: 5x1, 5x2, 4x2, 6x1, 12x36, 18x36, ou 24x48';