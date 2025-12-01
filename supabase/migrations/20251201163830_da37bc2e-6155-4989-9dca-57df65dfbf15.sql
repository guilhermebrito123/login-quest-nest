-- Ajustar tabela checklist para usar timezone brasileiro
ALTER TABLE public.checklist 
  ALTER COLUMN created_at SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo'),
  ALTER COLUMN updated_at SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo');

-- Ajustar tabela execucao_checklist para usar timezone brasileiro
ALTER TABLE public.execucao_checklist 
  ALTER COLUMN created_at SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo'),
  ALTER COLUMN updated_at SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo');

-- Ajustar tabela execucao_checklist_item para usar timezone brasileiro
ALTER TABLE public.execucao_checklist_item 
  ALTER COLUMN created_at SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo'),
  ALTER COLUMN updated_at SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo');

-- Ajustar tabela resposta_execucao_checklist para usar timezone brasileiro
ALTER TABLE public.resposta_execucao_checklist 
  ALTER COLUMN registrado_em SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo');

-- Ajustar tabela resposta_execucao_checklist_item para usar timezone brasileiro
ALTER TABLE public.resposta_execucao_checklist_item 
  ALTER COLUMN registrado_em SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo');