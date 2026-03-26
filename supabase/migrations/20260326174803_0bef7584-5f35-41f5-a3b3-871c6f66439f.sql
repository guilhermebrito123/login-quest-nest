create index if not exists idx_diarias_temporarias_logs_data_retencao
on public.diarias_temporarias_logs ((coalesce(criado_em, operacao_em)));