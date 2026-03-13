
-- Desabilitar triggers de usuário para backfill
alter table public.diaristas disable trigger user;

-- Backfill
with cpf_stats as (
  select
    id,
    public.normalizar_cpf(cpf) as cpf_norm,
    count(*) over (
      partition by public.normalizar_cpf(cpf)
    ) as qtd
  from public.diaristas
)
update public.diaristas d
set cpf_normalizado = case
  when s.cpf_norm is not null
   and length(s.cpf_norm) = 11
   and s.qtd = 1
    then s.cpf_norm
  else null
end
from cpf_stats s
where s.id = d.id;

-- Reabilitar triggers
alter table public.diaristas enable trigger user;

-- Índice único parcial
create unique index if not exists diaristas_cpf_normalizado_unique
on public.diaristas (cpf_normalizado)
where cpf_normalizado is not null;

-- Função trigger de guarda
create or replace function public.trg_diaristas_cpf_guard()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_new_cpf_norm text;
  v_old_cpf_norm text;
  v_conflito_id text;
begin
  v_new_cpf_norm := public.normalizar_cpf(new.cpf);

  if v_new_cpf_norm is null then
    raise exception 'CPF é obrigatório.';
  end if;

  if length(v_new_cpf_norm) <> 11 then
    raise exception 'CPF inválido. Informe 11 dígitos.';
  end if;

  if tg_op = 'UPDATE' then
    v_old_cpf_norm := public.normalizar_cpf(old.cpf);
    if v_new_cpf_norm = v_old_cpf_norm then
      new.cpf_normalizado := old.cpf_normalizado;
      return new;
    end if;
  end if;

  select d.id::text
    into v_conflito_id
  from public.diaristas d
  where public.normalizar_cpf(d.cpf) = v_new_cpf_norm
    and d.id::text <> new.id::text
  limit 1;

  if v_conflito_id is not null then
    raise exception 'Já existe um diarista cadastrado com este CPF.';
  end if;

  new.cpf_normalizado := v_new_cpf_norm;
  return new;
end;
$$;

-- Trigger
drop trigger if exists diaristas_cpf_guard_biu on public.diaristas;

create trigger diaristas_cpf_guard_biu
before insert or update of cpf
on public.diaristas
for each row
execute function public.trg_diaristas_cpf_guard();
