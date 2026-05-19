-- =============================================================================
-- Módulo Alocações Convenia — correção consolidada
-- =============================================================================

-- 0. Limpeza de assinaturas antigas
drop function if exists public.rpc_alocar_colaborador_convenia(uuid, uuid, time, time, integer, text, date, text, uuid);
drop function if exists public.rpc_alocar_colaborador_convenia(uuid, uuid, time, time, time, time, jsonb, text, date, text, uuid);
drop function if exists public.rpc_movimentar_colaborador_convenia(uuid, uuid, time, time, integer, text, date, text, uuid);
drop function if exists public.rpc_movimentar_colaborador_convenia(uuid, uuid, time, time, time, time, jsonb, text, date, text, uuid);
drop function if exists public.rpc_alterar_horario_alocacao_convenia(uuid, time, time, integer, text, text, uuid);
drop function if exists public.rpc_alterar_horario_alocacao_convenia(uuid, time, time, time, time, jsonb, text, text, uuid);
drop function if exists public.rpc_desvincular_colaborador_convenia(uuid, date, text, uuid);
drop function if exists public.rpc_desvincular_colaborador_convenia(uuid, text, date);
drop function if exists public.rpc_desvincular_colaborador_convenia(uuid, text);
drop function if exists public.rpc_get_historico_alocacao_colaborador_convenia(uuid);
drop function if exists public.rpc_cancelar_alocacao_convenia(uuid, text, uuid);
drop function if exists public.rpc_editar_alocacao_convenia(uuid, time, time, time, time, jsonb, text, date, date, text, uuid);

-- 1. Constraint de operação no histórico
alter table public.colaboradores_convenia_alocacoes_historico
  drop constraint if exists chk_hist_operacao_alocacao;
alter table public.colaboradores_convenia_alocacoes_historico
  add constraint chk_hist_operacao_alocacao
  check (operacao in (
    'alocacao_inicial',
    'transferencia_posto',
    'alteracao_horario',
    'alteracao_paridade_12x36',
    'edicao_alocacao',
    'cancelamento',
    'desvinculacao',
    'alteracao_status_alocacao',
    'ativacao_automatica',
    'inativacao_automatica',
    'atualizacao_automatica_12x36',
    'update_direto'
  ));

-- 2. fn_calcular_status_alocacao
create or replace function public.fn_calcular_status_alocacao(
  p_data_inicio date,
  p_data_fim date
) returns text
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
  if p_data_fim < v_hoje then return 'inativa'; end if;
  if p_data_fim = v_hoje then return 'ativa'; end if;
  return 'encerramento_agendado';
end;
$$;

create or replace function public.fn_calcular_ativo_alocacao(
  p_data_inicio date,
  p_data_fim date
) returns boolean
language sql
stable
set search_path = public
as $$
  select public.fn_calcular_status_alocacao(p_data_inicio, p_data_fim)
         in ('ativa', 'encerramento_agendado');
$$;

-- 3. Trigger fn_sync_status_alocacao
create or replace function public.fn_sync_status_alocacao()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' and old.status_alocacao = 'cancelada' then
    new.status_alocacao := 'cancelada';
    new.ativo := false;
    return new;
  end if;
  if new.status_alocacao = 'cancelada' then
    new.ativo := false;
    return new;
  end if;
  new.status_alocacao := public.fn_calcular_status_alocacao(new.data_inicio, new.data_fim);
  new.ativo := public.fn_calcular_ativo_alocacao(new.data_inicio, new.data_fim);
  return new;
end;
$$;

drop trigger if exists trg_sync_status_alocacao on public.colaboradores_convenia_alocacoes;
create trigger trg_sync_status_alocacao
before insert or update of data_inicio, data_fim, ativo, status_alocacao
on public.colaboradores_convenia_alocacoes
for each row
execute function public.fn_sync_status_alocacao();

-- 4. Índices únicos
drop index if exists public.uq_colaborador_convenia_alocacao_ativa;
drop index if exists public.uq_colaborador_convenia_alocacao_corrente;
drop index if exists public.uq_colaborador_convenia_alocacao_agendada;

create unique index uq_colaborador_convenia_alocacao_corrente
  on public.colaboradores_convenia_alocacoes (colaborador_convenia_id)
  where status_alocacao in ('ativa', 'encerramento_agendado');

create unique index uq_colaborador_convenia_alocacao_agendada
  on public.colaboradores_convenia_alocacoes (colaborador_convenia_id)
  where status_alocacao = 'agendada';

-- 5. fn_sincronizar_status_alocacoes_convenia
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
  v_novo_status text;
begin
  perform set_config('app.skip_alocacao_trigger', 'true', true);

  for r in
    select id from public.colaboradores_convenia_alocacoes
    where status_alocacao = 'encerramento_agendado'
      and data_fim is not null
      and data_fim < v_hoje
    for update
  loop
    select * into v_old from public.colaboradores_convenia_alocacoes where id = r.id;
    update public.colaboradores_convenia_alocacoes
      set status_alocacao = 'inativa',
          ativo = false,
          updated_at = now()
    where id = r.id
    returning * into v_new;

    insert into public.colaboradores_convenia_alocacoes_historico (
      alocacao_id, colaborador_convenia_id, operacao, motivo,
      status_alocacao_anterior, status_alocacao_novo,
      registro_anterior, registro_novo
    ) values (
      v_new.id, v_new.colaborador_convenia_id, 'inativacao_automatica',
      'Encerramento automático: data_fim alcançada.',
      v_old.status_alocacao, v_new.status_alocacao,
      to_jsonb(v_old), to_jsonb(v_new)
    );
  end loop;

  for r in
    select id from public.colaboradores_convenia_alocacoes
    where status_alocacao in ('ativa', 'encerramento_agendado')
      and data_fim is not null
      and data_fim < v_hoje
    for update
  loop
    select * into v_old from public.colaboradores_convenia_alocacoes where id = r.id;
    if v_old.status_alocacao = 'inativa' then
      continue;
    end if;
    update public.colaboradores_convenia_alocacoes
      set status_alocacao = 'inativa',
          ativo = false,
          updated_at = now()
    where id = r.id
    returning * into v_new;

    insert into public.colaboradores_convenia_alocacoes_historico (
      alocacao_id, colaborador_convenia_id, operacao, motivo,
      status_alocacao_anterior, status_alocacao_novo,
      registro_anterior, registro_novo
    ) values (
      v_new.id, v_new.colaborador_convenia_id, 'inativacao_automatica',
      'Encerramento automático: data_fim retroativa.',
      v_old.status_alocacao, v_new.status_alocacao,
      to_jsonb(v_old), to_jsonb(v_new)
    );
  end loop;

  for r in
    select id, colaborador_convenia_id, data_inicio
      from public.colaboradores_convenia_alocacoes
    where status_alocacao = 'agendada'
      and data_inicio <= v_hoje
    for update
  loop
    for v_old in
      select * from public.colaboradores_convenia_alocacoes
      where colaborador_convenia_id = r.colaborador_convenia_id
        and id <> r.id
        and status_alocacao in ('ativa', 'encerramento_agendado')
      for update
    loop
      update public.colaboradores_convenia_alocacoes
        set data_fim = least(coalesce(data_fim, v_hoje - 1), v_hoje - 1),
            status_alocacao = 'inativa',
            ativo = false,
            updated_at = now()
      where id = v_old.id
      returning * into v_new;

      insert into public.colaboradores_convenia_alocacoes_historico (
        alocacao_id, colaborador_convenia_id, operacao, motivo,
        status_alocacao_anterior, status_alocacao_novo,
        registro_anterior, registro_novo
      ) values (
        v_new.id, v_new.colaborador_convenia_id, 'inativacao_automatica',
        'Encerramento automático por substituição: nova alocação iniciada em ' || to_char(r.data_inicio, 'DD/MM/YYYY') || '.',
        v_old.status_alocacao, v_new.status_alocacao,
        to_jsonb(v_old), to_jsonb(v_new)
      );
    end loop;

    select * into v_old from public.colaboradores_convenia_alocacoes where id = r.id;
    v_novo_status := public.fn_calcular_status_alocacao(v_old.data_inicio, v_old.data_fim);

    update public.colaboradores_convenia_alocacoes
      set status_alocacao = v_novo_status,
          ativo = public.fn_calcular_ativo_alocacao(v_old.data_inicio, v_old.data_fim),
          updated_at = now()
    where id = r.id
    returning * into v_new;

    insert into public.colaboradores_convenia_alocacoes_historico (
      alocacao_id, colaborador_convenia_id, operacao, motivo,
      status_alocacao_anterior, status_alocacao_novo,
      registro_anterior, registro_novo
    ) values (
      v_new.id, v_new.colaborador_convenia_id, 'ativacao_automatica',
      'Ativação automática: data_inicio alcançada.',
      v_old.status_alocacao, v_new.status_alocacao,
      to_jsonb(v_old), to_jsonb(v_new)
    );
  end loop;

  perform set_config('app.skip_alocacao_trigger', 'false', true);
end;
$$;

-- 6. pg_cron
create extension if not exists pg_cron;

do $$
begin
  if exists (select 1 from cron.job where jobname = 'sincronizar-status-alocacoes-convenia') then
    perform cron.unschedule('sincronizar-status-alocacoes-convenia');
  end if;
end;
$$;

select cron.schedule(
  'sincronizar-status-alocacoes-convenia',
  '10 0 * * *',
  $$select public.fn_sincronizar_status_alocacoes_convenia();$$
);

-- 7. View v_colaboradores_convenia_alocacao_atual
drop view if exists public.v_colaboradores_convenia_alocacao_atual;
create view public.v_colaboradores_convenia_alocacao_atual
with (security_invoker = true)
as
select
  a.id                                  as alocacao_id,
  c.id                                  as colaborador_convenia_id,
  c.convenia_id,
  trim(concat_ws(' ', c.name, c.last_name)) as colaborador_nome,
  c.cpf,
  c.email,
  c.personal_email,
  c.registration,
  c.job_name,
  c.status                              as status_convenia,
  c.cost_center_id                      as colaborador_cost_center_id,
  c.cost_center_name                    as colaborador_cost_center_name,
  p.id                                  as posto_servico_id,
  p.nome                                as posto_nome,
  p.escala                              as posto_escala,
  p.dias_semana                         as posto_dias_semana,
  p.turno                               as posto_turno,
  p.cliente_id                          as posto_cliente_id,
  p.unidade_id                          as posto_unidade_id,
  p.cost_center_id                      as posto_cost_center_id,
  cc.name                               as posto_cost_center_name,
  a.horario_entrada,
  a.horario_saida,
  a.intervalo_inicio,
  a.intervalo_fim,
  a.paridade_12x36,
  (
    select coalesce(jsonb_agg(jsonb_build_object(
      'dia_semana',       h.dia_semana,
      'horario_entrada',  h.horario_entrada,
      'horario_saida',    h.horario_saida,
      'intervalo_inicio', h.intervalo_inicio,
      'intervalo_fim',    h.intervalo_fim
    ) order by h.dia_semana), '[]'::jsonb)
    from public.colaboradores_convenia_alocacao_horarios h
    where h.alocacao_id = a.id
  )                                     as horarios_semanais,
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
  end                                   as status_alocacao_label,
  a.observacao,
  a.created_at,
  a.created_by,
  a.updated_at,
  a.updated_by
from public.colaboradores_convenia_alocacoes a
join public.colaboradores_convenia c on c.id = a.colaborador_convenia_id
join public.postos_servico        p on p.id = a.posto_servico_id
left join public.cost_center      cc on cc.id = p.cost_center_id
where a.status_alocacao in ('agendada', 'ativa', 'encerramento_agendado');

grant select on public.v_colaboradores_convenia_alocacao_atual to authenticated;

-- 8. RPC ALOCAR
create or replace function public.rpc_alocar_colaborador_convenia(
  p_colaborador_convenia_id uuid,
  p_posto_servico_id        uuid,
  p_horario_entrada         time,
  p_horario_saida           time,
  p_intervalo_inicio        time,
  p_intervalo_fim           time,
  p_horarios_semanais       jsonb,
  p_paridade_12x36          text,
  p_data_inicio             date,
  p_motivo                  text,
  p_usuario_id              uuid
) returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_alocacao_id uuid;
  v_registro_novo jsonb;
  v_horarios_novo jsonb;
  v_data_inicio date := coalesce(p_data_inicio, (now() at time zone 'America/Sao_Paulo')::date);
begin
  perform set_config('app.skip_alocacao_trigger', 'true', true);

  if p_horario_entrada = p_horario_saida then
    raise exception 'Horário de entrada e saída não podem ser iguais.';
  end if;
  if (p_intervalo_inicio is null) <> (p_intervalo_fim is null) then
    raise exception 'Informe intervalo_inicio e intervalo_fim juntos.';
  end if;
  if p_intervalo_inicio is not null and p_intervalo_inicio = p_intervalo_fim then
    raise exception 'intervalo_inicio e intervalo_fim não podem ser iguais.';
  end if;

  if exists (
    select 1 from public.colaboradores_convenia_alocacoes
    where colaborador_convenia_id = p_colaborador_convenia_id
      and status_alocacao = 'agendada'
  ) then
    raise exception 'Este colaborador já possui uma alocação agendada. Edite ou cancele a existente antes de criar outra.';
  end if;

  if v_data_inicio <= (now() at time zone 'America/Sao_Paulo')::date
     and exists (
       select 1 from public.colaboradores_convenia_alocacoes
       where colaborador_convenia_id = p_colaborador_convenia_id
         and status_alocacao in ('ativa', 'encerramento_agendado')
     )
  then
    raise exception 'Colaborador já possui alocação corrente. Use Movimentar para trocar de posto ou Desvincular antes de criar outra.';
  end if;

  insert into public.colaboradores_convenia_alocacoes (
    colaborador_convenia_id, posto_servico_id,
    horario_entrada, horario_saida,
    intervalo_inicio, intervalo_fim,
    paridade_12x36, data_inicio,
    status_alocacao,
    observacao, created_by, updated_by
  ) values (
    p_colaborador_convenia_id, p_posto_servico_id,
    p_horario_entrada, p_horario_saida,
    p_intervalo_inicio, p_intervalo_fim,
    p_paridade_12x36, v_data_inicio,
    public.fn_calcular_status_alocacao(v_data_inicio, null),
    p_motivo, p_usuario_id, p_usuario_id
  ) returning id into v_alocacao_id;

  perform public.fn_upsert_horarios_semanais_alocacao(v_alocacao_id, p_horarios_semanais, p_usuario_id);

  select to_jsonb(a) into v_registro_novo
    from public.colaboradores_convenia_alocacoes a where a.id = v_alocacao_id;
  select coalesce(jsonb_agg(to_jsonb(h) order by h.dia_semana), '[]'::jsonb) into v_horarios_novo
    from public.colaboradores_convenia_alocacao_horarios h where h.alocacao_id = v_alocacao_id;

  insert into public.colaboradores_convenia_alocacoes_historico (
    colaborador_convenia_id, alocacao_id,
    posto_servico_id_anterior, posto_servico_id_novo,
    horario_entrada_anterior, horario_entrada_novo,
    horario_saida_anterior,   horario_saida_novo,
    intervalo_inicio_anterior, intervalo_inicio_novo,
    intervalo_fim_anterior,    intervalo_fim_novo,
    paridade_12x36_anterior,   paridade_12x36_nova,
    horarios_semanais_anterior, horarios_semanais_novo,
    status_alocacao_anterior, status_alocacao_novo,
    operacao, motivo,
    registro_anterior, registro_novo, created_by
  ) values (
    p_colaborador_convenia_id, v_alocacao_id,
    null, p_posto_servico_id,
    null, p_horario_entrada,
    null, p_horario_saida,
    null, p_intervalo_inicio,
    null, p_intervalo_fim,
    null, p_paridade_12x36,
    null, v_horarios_novo,
    null, public.fn_calcular_status_alocacao(v_data_inicio, null),
    'alocacao_inicial', p_motivo,
    null, v_registro_novo, p_usuario_id
  );

  perform set_config('app.skip_alocacao_trigger', 'false', true);
  return v_alocacao_id;
end;
$$;

-- 9. RPC MOVIMENTAR
create or replace function public.rpc_movimentar_colaborador_convenia(
  p_colaborador_convenia_id uuid,
  p_novo_posto_servico_id   uuid,
  p_horario_entrada         time,
  p_horario_saida           time,
  p_intervalo_inicio        time,
  p_intervalo_fim           time,
  p_horarios_semanais       jsonb,
  p_paridade_12x36          text,
  p_data_inicio             date,
  p_motivo                  text,
  p_usuario_id              uuid
) returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_alocacao_atual public.colaboradores_convenia_alocacoes%rowtype;
  v_nova_alocacao_id uuid;
  v_registro_novo jsonb;
  v_horarios_anterior jsonb;
  v_horarios_novo jsonb;
  v_data_inicio date := coalesce(p_data_inicio, (now() at time zone 'America/Sao_Paulo')::date);
  v_hoje date := (now() at time zone 'America/Sao_Paulo')::date;
  v_status_nova text;
begin
  perform set_config('app.skip_alocacao_trigger', 'true', true);

  if p_horario_entrada = p_horario_saida then
    raise exception 'Horário de entrada e saída não podem ser iguais.';
  end if;
  if (p_intervalo_inicio is null) <> (p_intervalo_fim is null) then
    raise exception 'Informe intervalo_inicio e intervalo_fim juntos.';
  end if;
  if p_intervalo_inicio is not null and p_intervalo_inicio = p_intervalo_fim then
    raise exception 'intervalo_inicio e intervalo_fim não podem ser iguais.';
  end if;

  select * into v_alocacao_atual
    from public.colaboradores_convenia_alocacoes
   where colaborador_convenia_id = p_colaborador_convenia_id
     and status_alocacao in ('ativa', 'encerramento_agendado')
   for update;

  if not found then
    raise exception 'Colaborador não possui alocação corrente. Use Alocar para criar uma alocação.';
  end if;

  if v_alocacao_atual.posto_servico_id = p_novo_posto_servico_id then
    raise exception 'O novo posto de serviço é igual ao posto atual. Use Editar para alterar dados sem trocar o posto.';
  end if;

  if v_data_inicio > v_hoje and exists (
    select 1 from public.colaboradores_convenia_alocacoes
    where colaborador_convenia_id = p_colaborador_convenia_id
      and status_alocacao = 'agendada'
  ) then
    raise exception 'Já existe uma movimentação agendada para este colaborador. Cancele a agendada antes de criar outra.';
  end if;

  select coalesce(jsonb_agg(to_jsonb(h) order by h.dia_semana), '[]'::jsonb) into v_horarios_anterior
    from public.colaboradores_convenia_alocacao_horarios h
   where h.alocacao_id = v_alocacao_atual.id;

  if v_data_inicio <= v_hoje then
    update public.colaboradores_convenia_alocacoes
       set data_fim = v_data_inicio - 1,
           status_alocacao = 'inativa',
           ativo = false,
           updated_at = now(),
           updated_by = p_usuario_id
     where id = v_alocacao_atual.id;
  end if;

  v_status_nova := public.fn_calcular_status_alocacao(v_data_inicio, null);

  insert into public.colaboradores_convenia_alocacoes (
    colaborador_convenia_id, posto_servico_id,
    horario_entrada, horario_saida,
    intervalo_inicio, intervalo_fim,
    paridade_12x36, data_inicio,
    status_alocacao,
    observacao, created_by, updated_by
  ) values (
    p_colaborador_convenia_id, p_novo_posto_servico_id,
    p_horario_entrada, p_horario_saida,
    p_intervalo_inicio, p_intervalo_fim,
    p_paridade_12x36, v_data_inicio,
    v_status_nova,
    p_motivo, p_usuario_id, p_usuario_id
  ) returning id into v_nova_alocacao_id;

  perform public.fn_upsert_horarios_semanais_alocacao(v_nova_alocacao_id, p_horarios_semanais, p_usuario_id);

  select to_jsonb(a) into v_registro_novo
    from public.colaboradores_convenia_alocacoes a where a.id = v_nova_alocacao_id;
  select coalesce(jsonb_agg(to_jsonb(h) order by h.dia_semana), '[]'::jsonb) into v_horarios_novo
    from public.colaboradores_convenia_alocacao_horarios h where h.alocacao_id = v_nova_alocacao_id;

  insert into public.colaboradores_convenia_alocacoes_historico (
    colaborador_convenia_id, alocacao_id,
    posto_servico_id_anterior, posto_servico_id_novo,
    horario_entrada_anterior, horario_entrada_novo,
    horario_saida_anterior,   horario_saida_novo,
    intervalo_inicio_anterior, intervalo_inicio_novo,
    intervalo_fim_anterior,    intervalo_fim_novo,
    paridade_12x36_anterior,   paridade_12x36_nova,
    horarios_semanais_anterior, horarios_semanais_novo,
    status_alocacao_anterior, status_alocacao_novo,
    operacao, motivo,
    registro_anterior, registro_novo, created_by
  ) values (
    p_colaborador_convenia_id, v_nova_alocacao_id,
    v_alocacao_atual.posto_servico_id, p_novo_posto_servico_id,
    v_alocacao_atual.horario_entrada,  p_horario_entrada,
    v_alocacao_atual.horario_saida,    p_horario_saida,
    v_alocacao_atual.intervalo_inicio, p_intervalo_inicio,
    v_alocacao_atual.intervalo_fim,    p_intervalo_fim,
    v_alocacao_atual.paridade_12x36,   p_paridade_12x36,
    v_horarios_anterior,               v_horarios_novo,
    v_alocacao_atual.status_alocacao,  v_status_nova,
    'transferencia_posto', p_motivo,
    to_jsonb(v_alocacao_atual), v_registro_novo, p_usuario_id
  );

  perform set_config('app.skip_alocacao_trigger', 'false', true);
  return v_nova_alocacao_id;
end;
$$;

-- 10. RPC ALTERAR HORÁRIO (compat)
create or replace function public.rpc_alterar_horario_alocacao_convenia(
  p_colaborador_convenia_id uuid,
  p_horario_entrada         time,
  p_horario_saida           time,
  p_intervalo_inicio        time,
  p_intervalo_fim           time,
  p_horarios_semanais       jsonb,
  p_paridade_12x36          text,
  p_motivo                  text,
  p_usuario_id              uuid
) returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_alocacao_id uuid;
begin
  select id into v_alocacao_id
    from public.colaboradores_convenia_alocacoes
   where colaborador_convenia_id = p_colaborador_convenia_id
     and status_alocacao in ('ativa', 'encerramento_agendado')
   limit 1;

  if v_alocacao_id is null then
    raise exception 'Colaborador não possui alocação corrente para alterar horário.';
  end if;

  return public.rpc_editar_alocacao_convenia(
    v_alocacao_id,
    p_horario_entrada, p_horario_saida,
    p_intervalo_inicio, p_intervalo_fim,
    p_horarios_semanais,
    p_paridade_12x36,
    null, null,
    p_motivo, p_usuario_id
  );
end;
$$;

-- 11. RPC EDITAR ALOCAÇÃO
create or replace function public.rpc_editar_alocacao_convenia(
  p_alocacao_id        uuid,
  p_horario_entrada    time,
  p_horario_saida      time,
  p_intervalo_inicio   time,
  p_intervalo_fim      time,
  p_horarios_semanais  jsonb,
  p_paridade_12x36     text,
  p_data_inicio        date,
  p_data_fim           date,
  p_motivo             text,
  p_usuario_id         uuid
) returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_atual public.colaboradores_convenia_alocacoes%rowtype;
  v_nova  public.colaboradores_convenia_alocacoes%rowtype;
  v_horarios_anterior jsonb;
  v_horarios_novo     jsonb;
  v_horarios_efetivos jsonb;
  v_data_inicio_efetiva date;
  v_data_fim_efetiva    date;
  v_he time; v_hs time; v_ii time; v_if time; v_pa text;
begin
  perform set_config('app.skip_alocacao_trigger', 'true', true);

  select * into v_atual from public.colaboradores_convenia_alocacoes
   where id = p_alocacao_id for update;

  if not found then
    raise exception 'Alocação % não encontrada.', p_alocacao_id;
  end if;
  if v_atual.status_alocacao in ('inativa', 'cancelada') then
    raise exception 'Não é possível editar alocação com status %.', v_atual.status_alocacao;
  end if;

  v_he := coalesce(p_horario_entrada, v_atual.horario_entrada);
  v_hs := coalesce(p_horario_saida,   v_atual.horario_saida);
  v_ii := coalesce(p_intervalo_inicio, v_atual.intervalo_inicio);
  v_if := coalesce(p_intervalo_fim,   v_atual.intervalo_fim);
  v_pa := coalesce(p_paridade_12x36,  v_atual.paridade_12x36);

  if v_he = v_hs then
    raise exception 'Horário de entrada e saída não podem ser iguais.';
  end if;
  if (v_ii is null) <> (v_if is null) then
    raise exception 'Informe intervalo_inicio e intervalo_fim juntos.';
  end if;
  if v_ii is not null and v_ii = v_if then
    raise exception 'intervalo_inicio e intervalo_fim não podem ser iguais.';
  end if;

  v_data_inicio_efetiva := v_atual.data_inicio;
  if p_data_inicio is not null and p_data_inicio <> v_atual.data_inicio then
    if v_atual.status_alocacao <> 'agendada' then
      raise exception 'data_inicio só pode ser alterada em alocações agendadas.';
    end if;
    if p_data_inicio <= (now() at time zone 'America/Sao_Paulo')::date then
      raise exception 'data_inicio de uma alocação agendada deve ser futura.';
    end if;
    v_data_inicio_efetiva := p_data_inicio;
  end if;

  v_data_fim_efetiva := v_atual.data_fim;
  if p_data_fim is not null and p_data_fim is distinct from v_atual.data_fim then
    if v_atual.status_alocacao <> 'encerramento_agendado' then
      raise exception 'data_fim só pode ser alterada em alocações com encerramento agendado. Use Desvincular para encerrar uma alocação ativa.';
    end if;
    if p_data_fim < v_atual.data_inicio then
      raise exception 'data_fim (%) não pode ser anterior a data_inicio (%).', p_data_fim, v_atual.data_inicio;
    end if;
    if p_data_fim < (now() at time zone 'America/Sao_Paulo')::date then
      raise exception 'data_fim não pode ser retroativa nesta operação. Use Desvincular.';
    end if;
    v_data_fim_efetiva := p_data_fim;
  end if;

  select coalesce(jsonb_agg(to_jsonb(h) order by h.dia_semana), '[]'::jsonb) into v_horarios_anterior
    from public.colaboradores_convenia_alocacao_horarios h
   where h.alocacao_id = v_atual.id;

  update public.colaboradores_convenia_alocacoes set
    horario_entrada    = v_he,
    horario_saida      = v_hs,
    intervalo_inicio   = v_ii,
    intervalo_fim      = v_if,
    paridade_12x36     = v_pa,
    data_inicio        = v_data_inicio_efetiva,
    data_fim           = v_data_fim_efetiva,
    observacao         = coalesce(p_motivo, observacao),
    updated_at         = now(),
    updated_by         = p_usuario_id
  where id = v_atual.id
  returning * into v_nova;

  if p_horarios_semanais is not null then
    perform public.fn_upsert_horarios_semanais_alocacao(v_atual.id, p_horarios_semanais, p_usuario_id);
  end if;

  select coalesce(jsonb_agg(to_jsonb(h) order by h.dia_semana), '[]'::jsonb) into v_horarios_novo
    from public.colaboradores_convenia_alocacao_horarios h
   where h.alocacao_id = v_atual.id;

  insert into public.colaboradores_convenia_alocacoes_historico (
    colaborador_convenia_id, alocacao_id,
    posto_servico_id_anterior, posto_servico_id_novo,
    horario_entrada_anterior, horario_entrada_novo,
    horario_saida_anterior,   horario_saida_novo,
    intervalo_inicio_anterior, intervalo_inicio_novo,
    intervalo_fim_anterior,    intervalo_fim_novo,
    paridade_12x36_anterior,   paridade_12x36_nova,
    horarios_semanais_anterior, horarios_semanais_novo,
    status_alocacao_anterior, status_alocacao_novo,
    operacao, motivo,
    registro_anterior, registro_novo, created_by
  ) values (
    v_atual.colaborador_convenia_id, v_atual.id,
    v_atual.posto_servico_id, v_nova.posto_servico_id,
    v_atual.horario_entrada,  v_nova.horario_entrada,
    v_atual.horario_saida,    v_nova.horario_saida,
    v_atual.intervalo_inicio, v_nova.intervalo_inicio,
    v_atual.intervalo_fim,    v_nova.intervalo_fim,
    v_atual.paridade_12x36,   v_nova.paridade_12x36,
    v_horarios_anterior,      v_horarios_novo,
    v_atual.status_alocacao,  v_nova.status_alocacao,
    'edicao_alocacao', p_motivo,
    to_jsonb(v_atual), to_jsonb(v_nova), p_usuario_id
  );

  perform set_config('app.skip_alocacao_trigger', 'false', true);
  return v_atual.id;
end;
$$;

-- 12. RPC DESVINCULAR
create or replace function public.rpc_desvincular_colaborador_convenia(
  p_alocacao_id uuid,
  p_motivo      text default null,
  p_data_fim    date default null,
  p_usuario_id  uuid default null
) returns public.colaboradores_convenia_alocacoes
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_alocacao public.colaboradores_convenia_alocacoes;
  v_old      public.colaboradores_convenia_alocacoes;
  v_hoje     date := (now() at time zone 'America/Sao_Paulo')::date;
  v_data_fim date;
begin
  perform set_config('app.skip_alocacao_trigger', 'true', true);

  select * into v_alocacao
    from public.colaboradores_convenia_alocacoes
   where id = p_alocacao_id
   for update;

  if not found then
    raise exception 'Alocação % não encontrada.', p_alocacao_id;
  end if;
  if v_alocacao.status_alocacao not in ('ativa', 'encerramento_agendado') then
    raise exception 'Apenas alocações ativas ou com encerramento agendado podem ser desvinculadas. Status atual: %.', v_alocacao.status_alocacao;
  end if;

  v_old := v_alocacao;
  v_data_fim := coalesce(p_data_fim, v_hoje);

  if v_data_fim < v_alocacao.data_inicio then
    raise exception 'data_fim (%) não pode ser anterior a data_inicio (%).', v_data_fim, v_alocacao.data_inicio;
  end if;

  update public.colaboradores_convenia_alocacoes
     set data_fim = v_data_fim,
         observacao = coalesce(p_motivo, observacao),
         updated_at = now(),
         updated_by = coalesce(p_usuario_id, updated_by)
   where id = p_alocacao_id
  returning * into v_alocacao;

  insert into public.colaboradores_convenia_alocacoes_historico (
    alocacao_id, colaborador_convenia_id, operacao, motivo,
    posto_servico_id_anterior, posto_servico_id_novo,
    horario_entrada_anterior, horario_entrada_novo,
    horario_saida_anterior,   horario_saida_novo,
    paridade_12x36_anterior,  paridade_12x36_nova,
    status_alocacao_anterior, status_alocacao_novo,
    registro_anterior, registro_novo, created_by
  ) values (
    v_alocacao.id, v_alocacao.colaborador_convenia_id, 'desvinculacao', p_motivo,
    v_old.posto_servico_id, v_alocacao.posto_servico_id,
    v_old.horario_entrada,  v_alocacao.horario_entrada,
    v_old.horario_saida,    v_alocacao.horario_saida,
    v_old.paridade_12x36,   v_alocacao.paridade_12x36,
    v_old.status_alocacao,  v_alocacao.status_alocacao,
    to_jsonb(v_old), to_jsonb(v_alocacao), p_usuario_id
  );

  perform set_config('app.skip_alocacao_trigger', 'false', true);
  return v_alocacao;
end;
$$;

-- 13. RPC CANCELAR
create or replace function public.rpc_cancelar_alocacao_convenia(
  p_alocacao_id uuid,
  p_motivo      text,
  p_usuario_id  uuid
) returns public.colaboradores_convenia_alocacoes
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_alocacao public.colaboradores_convenia_alocacoes;
  v_old      public.colaboradores_convenia_alocacoes;
begin
  if p_motivo is null or btrim(p_motivo) = '' then
    raise exception 'Motivo é obrigatório para cancelar uma alocação.';
  end if;

  perform set_config('app.skip_alocacao_trigger', 'true', true);

  select * into v_alocacao
    from public.colaboradores_convenia_alocacoes
   where id = p_alocacao_id
   for update;

  if not found then
    raise exception 'Alocação % não encontrada.', p_alocacao_id;
  end if;
  if v_alocacao.status_alocacao <> 'agendada' then
    raise exception 'Apenas alocações agendadas podem ser canceladas. Para encerrar uma alocação ativa, use Desvincular. Status atual: %.', v_alocacao.status_alocacao;
  end if;

  v_old := v_alocacao;

  update public.colaboradores_convenia_alocacoes
     set status_alocacao = 'cancelada',
         ativo = false,
         observacao = p_motivo,
         updated_at = now(),
         updated_by = p_usuario_id
   where id = p_alocacao_id
  returning * into v_alocacao;

  insert into public.colaboradores_convenia_alocacoes_historico (
    alocacao_id, colaborador_convenia_id, operacao, motivo,
    posto_servico_id_anterior, posto_servico_id_novo,
    horario_entrada_anterior, horario_entrada_novo,
    horario_saida_anterior,   horario_saida_novo,
    paridade_12x36_anterior,  paridade_12x36_nova,
    status_alocacao_anterior, status_alocacao_novo,
    registro_anterior, registro_novo, created_by
  ) values (
    v_alocacao.id, v_alocacao.colaborador_convenia_id, 'cancelamento', p_motivo,
    v_old.posto_servico_id, v_alocacao.posto_servico_id,
    v_old.horario_entrada,  v_alocacao.horario_entrada,
    v_old.horario_saida,    v_alocacao.horario_saida,
    v_old.paridade_12x36,   v_alocacao.paridade_12x36,
    v_old.status_alocacao,  v_alocacao.status_alocacao,
    to_jsonb(v_old), to_jsonb(v_alocacao), p_usuario_id
  );

  perform set_config('app.skip_alocacao_trigger', 'false', true);
  return v_alocacao;
end;
$$;

-- 14. RPC HISTÓRICO
create or replace function public.rpc_get_historico_alocacao_colaborador_convenia(
  p_colaborador_convenia_id uuid
) returns table (
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
  intervalo_inicio_anterior time,
  intervalo_inicio_novo time,
  intervalo_fim_anterior time,
  intervalo_fim_novo time,
  paridade_12x36_anterior text,
  paridade_12x36_nova text,
  horarios_semanais_anterior jsonb,
  horarios_semanais_novo jsonb,
  status_alocacao_anterior text,
  status_alocacao_novo text,
  registro_anterior jsonb,
  registro_novo jsonb,
  created_at timestamptz,
  created_by uuid
)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select
    h.id, h.alocacao_id, h.operacao, h.motivo,
    h.posto_servico_id_anterior, pa.nome,
    h.posto_servico_id_novo,     pn.nome,
    h.horario_entrada_anterior,  h.horario_entrada_novo,
    h.horario_saida_anterior,    h.horario_saida_novo,
    h.intervalo_inicio_anterior, h.intervalo_inicio_novo,
    h.intervalo_fim_anterior,    h.intervalo_fim_novo,
    h.paridade_12x36_anterior,   h.paridade_12x36_nova,
    h.horarios_semanais_anterior, h.horarios_semanais_novo,
    h.status_alocacao_anterior,  h.status_alocacao_novo,
    h.registro_anterior,         h.registro_novo,
    h.created_at,                h.created_by
  from public.colaboradores_convenia_alocacoes_historico h
  left join public.postos_servico pa on pa.id = h.posto_servico_id_anterior
  left join public.postos_servico pn on pn.id = h.posto_servico_id_novo
  where h.colaborador_convenia_id = p_colaborador_convenia_id
  order by h.created_at desc;
$$;

-- 15. Trigger trg_log_alocacao_convenia
create or replace function public.trg_log_alocacao_convenia()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
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
        or old.horario_saida is distinct from new.horario_saida
        or old.intervalo_inicio is distinct from new.intervalo_inicio
        or old.intervalo_fim is distinct from new.intervalo_fim then
    v_op := 'alteracao_horario';
  elsif old.status_alocacao is distinct from new.status_alocacao then
    v_op := 'alteracao_status_alocacao';
  else
    v_op := 'update_direto';
  end if;

  insert into public.colaboradores_convenia_alocacoes_historico (
    alocacao_id, colaborador_convenia_id, operacao, motivo,
    posto_servico_id_anterior, posto_servico_id_novo,
    horario_entrada_anterior, horario_entrada_novo,
    horario_saida_anterior,   horario_saida_novo,
    intervalo_inicio_anterior, intervalo_inicio_novo,
    intervalo_fim_anterior,    intervalo_fim_novo,
    paridade_12x36_anterior,   paridade_12x36_nova,
    status_alocacao_anterior, status_alocacao_novo,
    registro_anterior, registro_novo, created_by
  ) values (
    new.id, new.colaborador_convenia_id, v_op,
    'Histórico gerado automaticamente por UPDATE direto na tabela.',
    old.posto_servico_id, new.posto_servico_id,
    old.horario_entrada,  new.horario_entrada,
    old.horario_saida,    new.horario_saida,
    old.intervalo_inicio, new.intervalo_inicio,
    old.intervalo_fim,    new.intervalo_fim,
    old.paridade_12x36,   new.paridade_12x36,
    old.status_alocacao,  new.status_alocacao,
    to_jsonb(old), to_jsonb(new), new.updated_by
  );

  return new;
end;
$$;

drop trigger if exists log_alocacao_convenia on public.colaboradores_convenia_alocacoes;
create trigger log_alocacao_convenia
after update on public.colaboradores_convenia_alocacoes
for each row execute function public.trg_log_alocacao_convenia();

-- 16. Backfill
do $$
begin
  perform set_config('app.skip_alocacao_trigger', 'true', true);

  update public.colaboradores_convenia_alocacoes
     set status_alocacao = case
           when status_alocacao = 'cancelada' then 'cancelada'
           else public.fn_calcular_status_alocacao(data_inicio, data_fim)
         end,
         ativo = case
           when status_alocacao = 'cancelada' then false
           else public.fn_calcular_ativo_alocacao(data_inicio, data_fim)
         end
   where true;

  perform set_config('app.skip_alocacao_trigger', 'false', true);
end;
$$;

select public.fn_sincronizar_status_alocacoes_convenia();

-- 17. Grants
grant select on public.v_colaboradores_convenia_alocacao_atual to authenticated;
grant select on public.colaboradores_convenia_alocacoes        to authenticated;
grant select on public.colaboradores_convenia_alocacoes_historico to authenticated;
grant select on public.colaboradores_convenia_alocacao_horarios   to authenticated;

grant execute on function public.fn_calcular_status_alocacao(date, date) to authenticated;
grant execute on function public.fn_calcular_ativo_alocacao(date, date)  to authenticated;
grant execute on function public.fn_sincronizar_status_alocacoes_convenia() to authenticated;
grant execute on function public.rpc_alocar_colaborador_convenia(uuid, uuid, time, time, time, time, jsonb, text, date, text, uuid) to authenticated;
grant execute on function public.rpc_movimentar_colaborador_convenia(uuid, uuid, time, time, time, time, jsonb, text, date, text, uuid) to authenticated;
grant execute on function public.rpc_alterar_horario_alocacao_convenia(uuid, time, time, time, time, jsonb, text, text, uuid) to authenticated;
grant execute on function public.rpc_editar_alocacao_convenia(uuid, time, time, time, time, jsonb, text, date, date, text, uuid) to authenticated;
grant execute on function public.rpc_desvincular_colaborador_convenia(uuid, text, date, uuid) to authenticated;
grant execute on function public.rpc_cancelar_alocacao_convenia(uuid, text, uuid) to authenticated;
grant execute on function public.rpc_get_historico_alocacao_colaborador_convenia(uuid) to authenticated;