-- Primeiro, garantir que cliente_id não tenha valores NULL antes de torná-lo obrigatório
UPDATE public.contratos
SET cliente_id = id::text
WHERE cliente_id IS NULL;

-- Adicionar coluna conq_perd com valor padrão temporário
ALTER TABLE public.contratos
ADD COLUMN conq_perd integer;

-- Preencher com ano atual para registros existentes (pode ser ajustado depois)
UPDATE public.contratos
SET conq_perd = EXTRACT(YEAR FROM data_inicio)::integer
WHERE conq_perd IS NULL;

-- Tornar conq_perd obrigatório
ALTER TABLE public.contratos
ALTER COLUMN conq_perd SET NOT NULL;

-- Renomear coluna nome para negocio
ALTER TABLE public.contratos
RENAME COLUMN nome TO negocio;

-- Remover colunas não mais necessárias
ALTER TABLE public.contratos
DROP COLUMN codigo,
DROP COLUMN sla_alvo_pct,
DROP COLUMN nps_meta,
DROP COLUMN status;

-- Tornar cliente_id obrigatório
ALTER TABLE public.contratos
ALTER COLUMN cliente_id SET NOT NULL;