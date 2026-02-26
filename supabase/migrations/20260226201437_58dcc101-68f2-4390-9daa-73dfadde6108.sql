
-- Drop the old partial index if it exists
DROP INDEX IF EXISTS public.ux_faltas_diaria_not_null;

-- Unique: same (colaborador, data, diaria) when linked to a diaria_temporaria
CREATE UNIQUE INDEX ux_faltas_com_diaria
ON public.faltas_colaboradores_convenia (colaborador_convenia_id, data_falta, diaria_temporaria_id)
WHERE diaria_temporaria_id IS NOT NULL;

-- Unique: same (colaborador, data) when NOT linked to a diaria_temporaria
CREATE UNIQUE INDEX ux_faltas_sem_diaria
ON public.faltas_colaboradores_convenia (colaborador_convenia_id, data_falta)
WHERE diaria_temporaria_id IS NULL;
