-- Remover constraint UNIQUE em (posto_servico_id, data) para permitir múltiplos colaboradores por posto/data
ALTER TABLE public.dias_trabalho
DROP CONSTRAINT dias_trabalho_posto_servico_id_data_key;

-- Criar nova constraint UNIQUE que inclui colaborador_id, permitindo:
-- 1. Um dia genérico do posto (colaborador_id = NULL)
-- 2. Múltiplos dias para diferentes colaboradores no mesmo posto/data
CREATE UNIQUE INDEX dias_trabalho_posto_data_colaborador_unique 
ON public.dias_trabalho(posto_servico_id, data, COALESCE(colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid));

COMMENT ON INDEX dias_trabalho_posto_data_colaborador_unique IS 'Permite um dia genérico do posto e um dia por colaborador para cada posto/data';