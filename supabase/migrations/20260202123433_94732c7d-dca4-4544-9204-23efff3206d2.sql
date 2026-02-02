-- Desabilitar temporariamente o trigger de bloqueio
ALTER TABLE public.diarias_temporarias DISABLE TRIGGER bloquear_edicao_diaria_temporaria_trigger;

-- Atualizar todos os registros onde lancada_por não é nulo
UPDATE public.diarias_temporarias 
SET paga_por = lancada_por 
WHERE lancada_por IS NOT NULL;

-- Reabilitar o trigger
ALTER TABLE public.diarias_temporarias ENABLE TRIGGER bloquear_edicao_diaria_temporaria_trigger;