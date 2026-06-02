SET LOCAL app.rpc_call = 'true';
UPDATE public.diarias_temporarias
SET motivo_vago = 'DIÁRIA - FALTA ATESTADO'
WHERE id = 1781;