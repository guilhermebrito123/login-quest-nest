
-- Bypass triggers for manual transfer
ALTER TABLE public.diarias_temporarias DISABLE TRIGGER trg_autorizar_transicoes_diaria_temporaria;
ALTER TABLE public.diarias_temporarias DISABLE TRIGGER trg_bloquear_edicao_diaria_temporaria;
ALTER TABLE public.diarias_temporarias DISABLE TRIGGER bloquear_edicao_diaria_temporaria_trigger;

-- Transfer diarias
UPDATE public.diarias_temporarias
SET diarista_id = 'be0ae204-5be7-4c6e-a40f-05dd99ad35af'
WHERE diarista_id = '5c69214e-e025-44b4-ba65-535be273d694';

-- Re-enable triggers
ALTER TABLE public.diarias_temporarias ENABLE TRIGGER trg_autorizar_transicoes_diaria_temporaria;
ALTER TABLE public.diarias_temporarias ENABLE TRIGGER trg_bloquear_edicao_diaria_temporaria;
ALTER TABLE public.diarias_temporarias ENABLE TRIGGER bloquear_edicao_diaria_temporaria_trigger;

-- Delete dependencies
DELETE FROM public.blacklist WHERE diarista_id = '5c69214e-e025-44b4-ba65-535be273d694';
DELETE FROM public.diaristas_anexos WHERE diarista_id = '5c69214e-e025-44b4-ba65-535be273d694';
DELETE FROM public.diaristas_historico WHERE diarista_id = '5c69214e-e025-44b4-ba65-535be273d694';
DELETE FROM public.diarias WHERE diarista_id = '5c69214e-e025-44b4-ba65-535be273d694';

-- Delete the duplicate diarista
DELETE FROM public.diaristas WHERE id = '5c69214e-e025-44b4-ba65-535be273d694';
