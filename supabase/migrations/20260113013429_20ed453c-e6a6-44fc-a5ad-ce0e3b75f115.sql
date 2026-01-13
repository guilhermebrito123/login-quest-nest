-- Remove duplicate triggers

-- 1. Remove duplicate trigger for log_diaria_temporaria_changes (keep fn_audit_diarias_temporarias_granular)
DROP TRIGGER IF EXISTS trigger_log_diaria_temporaria_changes ON public.diarias_temporarias;

-- 2. Remove duplicate trigger for validar_motivos_diaria_temporaria (keep validar_motivos_diaria_temporaria_trg)
DROP TRIGGER IF EXISTS validar_motivos_diaria_temporaria_trigger ON public.diarias_temporarias;