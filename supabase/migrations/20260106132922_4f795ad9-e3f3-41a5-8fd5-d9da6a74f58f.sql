
-- Remover o trigger antigo que usa a tabela diarias_temporarias_logs
DROP TRIGGER IF EXISTS trigger_log_diaria_temporaria_changes ON public.diarias_temporarias;

-- Opcionalmente, remover a função antiga também
DROP FUNCTION IF EXISTS public.log_diaria_temporaria_changes();
