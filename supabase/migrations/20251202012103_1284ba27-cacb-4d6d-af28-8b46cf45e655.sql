-- Remover triggers duplicados
DROP TRIGGER IF EXISTS sync_dias_vagos_trigger ON public.dias_trabalho;
DROP TRIGGER IF EXISTS sync_presencas_on_dias_trabalho_update ON public.dias_trabalho;

-- Limpar duplicatas em posto_dias_vagos (manter apenas um registro por posto/data)
DELETE FROM public.posto_dias_vagos a
USING public.posto_dias_vagos b
WHERE a.id > b.id
  AND a.posto_servico_id = b.posto_servico_id
  AND a.data = b.data;