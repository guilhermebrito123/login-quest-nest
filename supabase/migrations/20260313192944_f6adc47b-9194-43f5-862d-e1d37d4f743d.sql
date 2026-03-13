-- Adicionar constraint única para impedir faltas duplicadas do mesmo colaborador na mesma data
-- Isso garante que um colaborador não tenha duas faltas registradas para o mesmo dia

-- Primeiro, limpar possíveis duplicatas existentes (mantendo o registro mais recente)
WITH duplicatas AS (
  SELECT id,
         colaborador_convenia_id,
         data_falta,
         ROW_NUMBER() OVER (
           PARTITION BY colaborador_convenia_id, data_falta 
           ORDER BY created_at DESC, id DESC
         ) as rn
  FROM public.faltas_colaboradores_convenia
  WHERE colaborador_convenia_id IS NOT NULL 
    AND data_falta IS NOT NULL
)
DELETE FROM public.faltas_colaboradores_convenia
WHERE id IN (
  SELECT id FROM duplicatas WHERE rn > 1
);

-- Criar índice único composto
CREATE UNIQUE INDEX IF NOT EXISTS ux_faltas_colaborador_data_unica
ON public.faltas_colaboradores_convenia (colaborador_convenia_id, data_falta)
WHERE colaborador_convenia_id IS NOT NULL AND data_falta IS NOT NULL;

-- Comentário explicativo
COMMENT ON INDEX public.ux_faltas_colaborador_data_unica IS 
  'Garante que um colaborador não possua duas faltas registradas para a mesma data';