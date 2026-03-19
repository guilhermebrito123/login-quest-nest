
-- Disable triggers for operations
ALTER TABLE public.diarias_temporarias DISABLE TRIGGER trg_autorizar_transicoes_diaria_temporaria;
ALTER TABLE public.diarias_temporarias DISABLE TRIGGER trg_bloquear_edicao_diaria_temporaria;
ALTER TABLE public.diarias_temporarias DISABLE TRIGGER bloquear_edicao_diaria_temporaria_trigger;

-- Delete diárias of 2026-03-12 and 2026-03-13
DELETE FROM public.diarias_temporarias WHERE id IN (901, 903);

-- Transfer diária 911 (2026-03-18) to the other diarista
UPDATE public.diarias_temporarias 
SET diarista_id = '89e96025-0bf4-45d3-a386-9c2674960054'
WHERE id = 911;

-- Re-enable triggers
ALTER TABLE public.diarias_temporarias ENABLE TRIGGER trg_autorizar_transicoes_diaria_temporaria;
ALTER TABLE public.diarias_temporarias ENABLE TRIGGER trg_bloquear_edicao_diaria_temporaria;
ALTER TABLE public.diarias_temporarias ENABLE TRIGGER bloquear_edicao_diaria_temporaria_trigger;
