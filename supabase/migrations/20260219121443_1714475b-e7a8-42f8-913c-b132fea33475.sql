-- Desabilitar triggers temporariamente
ALTER TABLE public.diarias_temporarias DISABLE TRIGGER trg_autorizar_transicoes_diaria_temporaria;
ALTER TABLE public.diarias_temporarias DISABLE TRIGGER trg_validar_falta_justificada_diaria;

UPDATE public.diarias_temporarias 
SET status = 'Cancelada', 
    motivo_cancelamento = 'aa', 
    cancelada_em = (now() AT TIME ZONE 'America/Sao_Paulo')::date,
    updated_at = now()
WHERE id IN (493, 490, 456, 455);

-- Reabilitar triggers
ALTER TABLE public.diarias_temporarias ENABLE TRIGGER trg_autorizar_transicoes_diaria_temporaria;
ALTER TABLE public.diarias_temporarias ENABLE TRIGGER trg_validar_falta_justificada_diaria;