
-- Delete dependent records first
DELETE FROM public.blacklist WHERE diarista_id = '00460bad-8bd3-4d3e-97bc-88056eddc4fc';
DELETE FROM public.diaristas_anexos WHERE diarista_id = '00460bad-8bd3-4d3e-97bc-88056eddc4fc';
DELETE FROM public.diaristas_historico WHERE diarista_id = '00460bad-8bd3-4d3e-97bc-88056eddc4fc';
DELETE FROM public.diarias WHERE diarista_id = '00460bad-8bd3-4d3e-97bc-88056eddc4fc';

-- Delete the diarista
DELETE FROM public.diaristas WHERE id = '00460bad-8bd3-4d3e-97bc-88056eddc4fc';
