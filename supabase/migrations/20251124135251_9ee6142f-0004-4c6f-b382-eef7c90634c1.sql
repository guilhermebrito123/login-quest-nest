-- Remover o índice único problemático
DROP INDEX IF EXISTS public.posto_dias_vagos_unique_idx;

-- Criar um índice único parcial que permite múltiplos NULLs
-- O índice só se aplica quando colaborador_id NÃO é NULL
CREATE UNIQUE INDEX posto_dias_vagos_unique_with_colaborador_idx
ON public.posto_dias_vagos (posto_servico_id, data, colaborador_id)
WHERE colaborador_id IS NOT NULL;

-- Criar um índice único separado para registros sem colaborador
-- Isso permite apenas UM registro NULL por posto/data
CREATE UNIQUE INDEX posto_dias_vagos_unique_without_colaborador_idx
ON public.posto_dias_vagos (posto_servico_id, data)
WHERE colaborador_id IS NULL;