create index if not exists idx_diarias_temporarias_logs_operacao_em_desc
on public.diarias_temporarias_logs (operacao_em desc, criado_em desc);

create index if not exists idx_diarias_temporarias_logs_diaria_id_operacao_em
on public.diarias_temporarias_logs (diaria_id, operacao_em desc);

create index if not exists idx_diarias_temporarias_logs_campo_operacao_em
on public.diarias_temporarias_logs (campo, operacao_em desc);

create index if not exists idx_diarias_temporarias_logs_operacao_operacao_em
on public.diarias_temporarias_logs (operacao, operacao_em desc);

create index if not exists idx_diarias_temporarias_logs_usuario_operacao_em
on public.diarias_temporarias_logs (usuario_responsavel, operacao_em desc);