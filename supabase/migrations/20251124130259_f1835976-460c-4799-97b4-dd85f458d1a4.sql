-- Habilitar extensão pg_cron para agendamento de tarefas
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

-- Garantir que a função seja executável pelo cron
GRANT USAGE ON SCHEMA public TO postgres;
GRANT EXECUTE ON FUNCTION public.limpar_posto_dias_vagos_antigos() TO postgres;