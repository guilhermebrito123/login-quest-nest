
-- 1) Função para normalizar CPF
create or replace function public.normalizar_cpf(input text)
returns text
language sql
immutable
as $$
  select nullif(regexp_replace(coalesce(input, ''), '\D', '', 'g'), '');
$$;

-- 2) Coluna técnica
alter table public.diaristas
add column if not exists cpf_normalizado text;
