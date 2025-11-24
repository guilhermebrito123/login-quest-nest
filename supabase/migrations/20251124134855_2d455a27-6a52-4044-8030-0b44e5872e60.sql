-- Corrigir foreign key em posto_dias_vagos para permitir exclusão de colaboradores
-- Remover a constraint atual e recriar com ON DELETE SET NULL

ALTER TABLE public.posto_dias_vagos
DROP CONSTRAINT IF EXISTS posto_dias_vagos_colaborador_id_fkey;

ALTER TABLE public.posto_dias_vagos
ADD CONSTRAINT posto_dias_vagos_colaborador_id_fkey
FOREIGN KEY (colaborador_id)
REFERENCES public.colaboradores(id)
ON DELETE SET NULL;

-- Também garantir que a constraint unique permite múltiplos NULLs
-- Remover constraint antiga se existir
ALTER TABLE public.posto_dias_vagos
DROP CONSTRAINT IF EXISTS posto_dias_vagos_unique_constraint;

-- Criar índice único que permite múltiplos NULLs em colaborador_id
CREATE UNIQUE INDEX IF NOT EXISTS posto_dias_vagos_unique_idx
ON public.posto_dias_vagos (posto_servico_id, data, COALESCE(colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid));