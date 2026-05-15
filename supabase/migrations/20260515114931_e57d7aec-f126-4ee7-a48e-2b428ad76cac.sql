drop function if exists public.rpc_get_historico_alocacao_colaborador_convenia(uuid);
drop function if exists public.rpc_desvincular_colaborador_convenia(uuid, text);
drop function if exists public.rpc_desvincular_colaborador_convenia(uuid, text, date);

create or replace function public.fn_calcular_status_alocacao(
  p_data_inicio date,
  p_data_fim date
)
returns text
language plpgsql
stable
set search_path = public
as $$
declare
  v_hoje date := (now() at time zone 'America/Sao_Paulo')::date;
begin
  if p_data_inicio is null then return 'inativa'; end if;
  if p_data_inicio > v_hoje then return 'agendada'; end if;
  if p_data_fim is null then return 'ativa'; end if;
  if p_data_fim >= v_hoje then return 'encerramento_agendado'; end if;
  return 'inativa';
end;
$$;

create or replace function public.fn_calcular_ativo_alocacao(
  p_data_inicio date,
  p_data_fim date
)
returns boolean
language sql
stable
set search_path = public
as $$
  select public.fn_calcular_status_alocacao(p_data_inicio, p_data_fim)
         in ('ativa', 'encerramento_agendado');
$$;

alter table public.colaboradores_convenia_alocacoes
  add column if not exists status_alocacao text;

update public.colaboradores_convenia_alocacoes
   set status_alocacao = public.fn_calcular_status_alocacao(data_inicio, data_fim),
       ativo = public.fn_calcular_ativo_alocacao(data_inicio, data_fim)
 where true;

alter table public.colaboradores_convenia_alocacoes
  alter column status_alocacao set not null;

alter table public.colaboradores_convenia_alocacoes
  drop constraint if exists chk_status_alocacao_valido;

alter table public.colaboradores_convenia_alocacoes
  add constraint chk_status_alocacao_valido
  check (status_alocacao in ('agendada','ativa','encerramento_agendado','inativa','cancelada'));

create or replace function public.fn_sync_status_alocacao()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' and new.status_alocacao = 'cancelada'
     and old.status_alocacao = 'cancelada' then
    new.ativo := false;
    return new;
  end if;

  if new.status_alocacao is distinct from 'cancelada' then
    new.status_alocacao := public.fn_calcular_status_alocacao(new.data_inicio, new.data_fim);
    new.ativo := public.fn_calcular_ativo_alocacao(new.data_inicio, new.data_fim);
  else
    new.ativo := false;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_sync_status_alocacao on public.colaboradores_convenia_alocacoes;
create trigger trg_sync_status_alocacao
before insert or update of data_inicio, data_fim, ativo, status_alocacao
on public.colaboradores_convenia_alocacoes
for each row
execute function public.fn_sync_status_alocacao();

drop index if exists public.uq_colaborador_convenia_alocacao_ativa;

create unique index if not exists uq_colaborador_convenia_alocacao_corrente
  on public.colaboradores_convenia_alocacoes (colaborador_convenia_id)
  where ativo = true and status_alocacao in ('ativa','encerramento_agendado');

create unique index if not exists uq_colaborador_convenia_alocacao_agendada
  on public.colaboradores_convenia_alocacoes (colaborador_convenia_id)
  where status_alocacao = 'agendada';

alter table public.colaboradores_convenia_alocacoes_historico
  add column if not exists status_alocacao_anterior text,
  add column if not exists status_alocacao_novo text;

alter table public.colaboradores_convenia_alocacoes_historico
  drop constraint if exists chk_hist_operacao_alocacao;

alter table public.colaboradores_convenia_alocacoes_historico
  add constraint chk_hist_operacao_alocacao
  check (operacao in (
    'alocacao_inicial','transferencia_posto','alteracao_paridade_12x36',
    'alteracao_horario','edicao_alocacao','alteracao_status_alocacao',
    'ativacao_automatica','inativacao_automatica','desvinculacao',
    'atualizacao_automatica_12x36','update_direto'
  ));

create or replace function public.fn_log_alocacao_convenia()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_skip text;
  v_op text;
begin
  begin
    v_skip := current_setting('app.skip_alocacao_trigger', true);
  exception when others then
    v_skip := null;
  end;

  if v_skip = 'true' then
    return new;
  end if;

  if old.posto_servico_id is distinct from new.posto_servico_id then
    v_op := 'transferencia_posto';
  elsif old.paridade_12x36 is distinct from new.paridade_12x36 then
    v_op := 'alteracao_paridade_12x36';
  elsif old.horario_entrada is distinct from new.horario_entrada
        or old.horario_saida is distinct from new.horario_saida then
    v_op := 'alteracao_horario';
  elsif old.status_alocacao is distinct from new.status_alocacao then
    v_op := 'alteracao_status_alocacao';
  else
    v_op := 'update_direto';
  end if;

  insert into public.colaboradores_convenia_alocacoes_historico (
    alocacao_id, colaborador_convenia_id, operacao,
    posto_servico_id_anterior, posto_servico_id_novo,
    horario_entrada_anterior, horario_entrada_novo,
    horario_saida_anterior, horario_saida_novo,
    paridade_12x36_anterior, paridade_12x36_nova,
    status_alocacao_anterior, status_alocacao_novo,
    registro_anterior, registro_novo
  ) values (
    new.id, new.colaborador_convenia_id, v_op,
    old.posto_servico_id, new.posto_servico_id,
    old.horario_entrada, new.horario_entrada,
    old.horario_saida, new.horario_saida,
    old.paridade_12x36, new.paridade_12x36,
    old.status_alocacao, new.status_alocacao,
    to_jsonb(old), to_jsonb(new)
  );
  return new;
end;
$$;

create function public.rpc_desvincular_colaborador_convenia(
  p_alocacao_id uuid,
  p_motivo text default null,
  p_data_fim date default null
)
returns public.colaboradores_convenia_alocacoes
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_alocacao public.colaboradores_convenia_alocacoes;
  v_old public.colaboradores_convenia_alocacoes;
  v_hoje date := (now() at time zone 'America/Sao_Paulo')::date;
  v_data_fim date;
begin
  perform set_config('app.skip_alocacao_trigger', 'true', true);

  select * into v_alocacao
    from public.colaboradores_convenia_alocacoes
   where id = p_alocacao_id
   for update;

  if not found then
    raise exception 'Alocação % não encontrada', p_alocacao_id;
  end if;

  v_old := v_alocacao;
  v_data_fim := coalesce(p_data_fim, v_hoje);

  if v_data_fim < v_alocacao.data_inicio then
    raise exception 'data_fim (%) não pode ser anterior a data_inicio (%)',
      v_data_fim, v_alocacao.data_inicio;
  end if;

  update public.colaboradores_convenia_alocacoes
     set data_fim = v_data_fim,
         observacao = coalesce(p_motivo, observacao),
         updated_at = now()
   where id = p_alocacao_id
  returning * into v_alocacao;

  insert into public.colaboradores_convenia_alocacoes_historico (
    alocacao_id, colaborador_convenia_id, operacao, motivo,
    posto_servico_id_anterior, posto_servico_id_novo,
    horario_entrada_anterior, horario_entrada_novo,
    horario_saida_anterior, horario_saida_novo,
    paridade_12x36_anterior, paridade_12x36_nova,
    status_alocacao_anterior, status_alocacao_novo,
    registro_anterior, registro_novo
  ) values (
    v_alocacao.id, v_alocacao.colaborador_convenia_id, 'desvinculacao', p_motivo,
    v_old.posto_servico_id, v_alocacao.posto_servico_id,
    v_old.horario_entrada, v_alocacao.horario_entrada,
    v_old.horario_saida, v_alocacao.horario_saida,
    v_old.paridade_12x36, v_alocacao.paridade_12x36,
    v_old.status_alocacao, v_alocacao.status_alocacao,
    to_jsonb(v_old), to_jsonb(v_alocacao)
  );

  perform set_config('app.skip_alocacao_trigger', 'false', true);
  return v_alocacao;
end;
$$;

create or replace function public.fn_sincronizar_status_alocacoes_convenia()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  r record;
  v_hoje date := (now() at time zone 'America/Sao_Paulo')::date;
  v_old public.colaboradores_convenia_alocacoes;
  v_new public.colaboradores_convenia_alocacoes;
  v_corrente public.colaboradores_convenia_alocacoes;
begin
  perform set_config('app.skip_alocacao_trigger', 'true', true);

  for r in
    select id from public.colaboradores_convenia_alocacoes
     where ativo = true
       and data_fim is not null
       and data_fim < v_hoje
     for update
  loop
    select * into v_old from public.colaboradores_convenia_alocacoes where id = r.id;
    update public.colaboradores_convenia_alocacoes
       set updated_at = now()
     where id = r.id
    returning * into v_new;

    insert into public.colaboradores_convenia_alocacoes_historico (
      alocacao_id, colaborador_convenia_id, operacao,
      status_alocacao_anterior, status_alocacao_novo,
      registro_anterior, registro_novo
    ) values (
      v_new.id, v_new.colaborador_convenia_id, 'inativacao_automatica',
      v_old.status_alocacao, v_new.status_alocacao,
      to_jsonb(v_old), to_jsonb(v_new)
    );
  end loop;

  for r in
    select id, colaborador_convenia_id
      from public.colaboradores_convenia_alocacoes
     where status_alocacao = 'agendada'
       and data_inicio <= v_hoje
     for update
  loop
    select * into v_corrente
      from public.colaboradores_convenia_alocacoes
     where colaborador_convenia_id = r.colaborador_convenia_id
       and ativo = true
       and id <> r.id
     for update;

    if found then
      v_old := v_corrente;
      update public.colaboradores_convenia_alocacoes
         set data_fim = v_hoje - 1,
             updated_at = now()
       where id = v_corrente.id
      returning * into v_new;

      insert into public.colaboradores_convenia_alocacoes_historico (
        alocacao_id, colaborador_convenia_id, operacao,
        status_alocacao_anterior, status_alocacao_novo,
        registro_anterior, registro_novo
      ) values (
        v_new.id, v_new.colaborador_convenia_id, 'inativacao_automatica',
        v_old.status_alocacao, v_new.status_alocacao,
        to_jsonb(v_old), to_jsonb(v_new)
      );
    end if;

    select * into v_old from public.colaboradores_convenia_alocacoes where id = r.id;
    update public.colaboradores_convenia_alocacoes
       set updated_at = now()
     where id = r.id
    returning * into v_new;

    insert into public.colaboradores_convenia_alocacoes_historico (
      alocacao_id, colaborador_convenia_id, operacao,
      status_alocacao_anterior, status_alocacao_novo,
      registro_anterior, registro_novo
    ) values (
      v_new.id, v_new.colaborador_convenia_id, 'ativacao_automatica',
      v_old.status_alocacao, v_new.status_alocacao,
      to_jsonb(v_old), to_jsonb(v_new)
    );
  end loop;

  perform set_config('app.skip_alocacao_trigger', 'false', true);
end;
$$;

drop view if exists public.v_colaboradores_convenia_alocacao_atual;

create view public.v_colaboradores_convenia_alocacao_atual
with (security_invoker = true)
as
select
  a.id                              as alocacao_id,
  a.colaborador_convenia_id,
  trim(coalesce(c.name,'') || ' ' || coalesce(c.last_name,'')) as colaborador_nome,
  a.posto_servico_id,
  p.nome                            as posto_nome,
  p.escala                          as posto_escala,
  a.horario_entrada,
  a.horario_saida,
  a.paridade_12x36,
  a.data_inicio,
  a.data_fim,
  a.ativo,
  a.status_alocacao,
  case a.status_alocacao
    when 'agendada'              then 'Ativo em ' || to_char(a.data_inicio, 'DD/MM/YYYY')
    when 'ativa'                 then 'Ativo'
    when 'encerramento_agendado' then 'Encerra em ' || to_char(a.data_fim, 'DD/MM/YYYY')
    when 'inativa'               then 'Inativo'
    when 'cancelada'             then 'Cancelado'
    else a.status_alocacao
  end                               as status_alocacao_label,
  a.created_at,
  a.updated_at
from public.colaboradores_convenia_alocacoes a
join public.colaboradores_convenia c on c.id = a.colaborador_convenia_id
join public.postos_servico        p on p.id = a.posto_servico_id
where a.status_alocacao in ('agendada','ativa','encerramento_agendado');

grant select on public.v_colaboradores_convenia_alocacao_atual to authenticated;

create function public.rpc_get_historico_alocacao_colaborador_convenia(
  p_colaborador_convenia_id uuid
)
returns table (
  id uuid,
  alocacao_id uuid,
  operacao text,
  motivo text,
  posto_servico_id_anterior uuid,
  posto_servico_anterior_nome text,
  posto_servico_id_novo uuid,
  posto_servico_novo_nome text,
  horario_entrada_anterior time,
  horario_entrada_novo time,
  horario_saida_anterior time,
  horario_saida_novo time,
  paridade_12x36_anterior text,
  paridade_12x36_nova text,
  status_alocacao_anterior text,
  status_alocacao_novo text,
  created_at timestamptz
)
language sql
security definer
stable
set search_path = public
as $$
  select
    h.id, h.alocacao_id, h.operacao, h.motivo,
    h.posto_servico_id_anterior, pa.nome,
    h.posto_servico_id_novo, pn.nome,
    h.horario_entrada_anterior, h.horario_entrada_novo,
    h.horario_saida_anterior, h.horario_saida_novo,
    h.paridade_12x36_anterior, h.paridade_12x36_nova,
    h.status_alocacao_anterior, h.status_alocacao_novo,
    h.created_at
  from public.colaboradores_convenia_alocacoes_historico h
  left join public.postos_servico pa on pa.id = h.posto_servico_id_anterior
  left join public.postos_servico pn on pn.id = h.posto_servico_id_novo
  where h.colaborador_convenia_id = p_colaborador_convenia_id
  order by h.created_at desc;
$$;

grant execute on function public.rpc_get_historico_alocacao_colaborador_convenia(uuid) to authenticated;
grant execute on function public.fn_sincronizar_status_alocacoes_convenia() to authenticated;
grant execute on function public.fn_calcular_status_alocacao(date, date) to authenticated;
grant execute on function public.fn_calcular_ativo_alocacao(date, date) to authenticated;
grant execute on function public.rpc_desvincular_colaborador_convenia(uuid, text, date) to authenticated;