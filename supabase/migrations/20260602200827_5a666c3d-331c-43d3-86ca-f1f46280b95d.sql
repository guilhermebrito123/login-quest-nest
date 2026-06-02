SET LOCAL app.rpc_call = 'true';

UPDATE public.diarias_temporarias
SET observacao = 'Afastamento de Andrea Cordeiro de Freitas'
WHERE id IN (1024, 1018, 1015, 1007, 906);