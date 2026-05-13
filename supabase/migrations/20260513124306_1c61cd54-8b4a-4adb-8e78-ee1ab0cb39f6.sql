
-- 1. Alterações em colaboradores_convenia_alocacoes
alter table public.colaboradores_convenia_alocacoes add column if not exists intervalo_inicio time null;
alter table public.colaboradores_convenia_alocacoes add column if not exists intervalo_fim time null;
alter table public.colaboradores_convenia_alocacoes drop constraint if exists chk_alocacao_intervalo_valido;
alter table public.colaboradores_convenia_alocacoes drop constraint if exists chk_alocacao_intervalo_periodo_valido;
alter table public.colaboradores_convenia_alocacoes
  add constraint chk_alocacao_intervalo_periodo_valido
  check (
    (intervalo_inicio is null and intervalo_fim is null)
    or (intervalo_inicio is not null and intervalo_fim is not null and intervalo_inicio <> intervalo_fim)
  );

-- 2. Tabela de horários semanais
create table if not exists public.colaboradores_convenia_alocacao_horarios (
  id uuid primary key default gen_random_uuid(),
  alocacao_id uuid not null references public.colaboradores_convenia_alocacoes(id) on delete cascade,
  dia_semana smallint not null,
  horario_entrada time not null,
  horario_saida time not null,
  intervalo_inicio time null,
  intervalo_fim time null,
  created_at timestamptz not null default now(),
  created_by uuid null references public.usuarios(id),
  updated_at timestamptz not null default now(),
  updated_by uuid null references public.usuarios(id),
  constraint chk_alocacao_horarios_dia_semana check (dia_semana between 1 and 7),
  constraint chk_alocacao_horarios_entrada_saida check (horario_entrada <> horario_saida),
  constraint chk_alocacao_horarios_intervalo check (
    (intervalo_inicio is null and intervalo_fim is null)
    or (intervalo_inicio is not null and intervalo_fim is not null and intervalo_inicio <> intervalo_fim)
  )
);

create unique index if not exists uq_alocacao_horarios_dia
  on public.colaboradores_convenia_alocacao_horarios (alocacao_id, dia_semana);
create index if not exists idx_alocacao_horarios_alocacao
  on public.colaboradores_convenia_alocacao_horarios (alocacao_id);

alter table public.colaboradores_convenia_alocacao_horarios enable row level security;

drop policy if exists "Authenticated select alocacao_horarios" on public.colaboradores_convenia_alocacao_horarios;
create policy "Authenticated select alocacao_horarios"
  on public.colaboradores_convenia_alocacao_horarios
  for select to authenticated using (true);

-- 3. Histórico
alter table public.colaboradores_convenia_alocacoes_historico add column if not exists intervalo_inicio_anterior time null;
alter table public.colaboradores_convenia_alocacoes_historico add column if not exists intervalo_inicio_novo time null;
alter table public.colaboradores_convenia_alocacoes_historico add column if not exists intervalo_fim_anterior time null;
alter table public.colaboradores_convenia_alocacoes_historico add column if not exists intervalo_fim_novo time null;
alter table public.colaboradores_convenia_alocacoes_historico add column if not exists horarios_semanais_anterior jsonb null;
alter table public.colaboradores_convenia_alocacoes_historico add column if not exists horarios_semanais_novo jsonb null;

-- 4. Funções auxiliares de escala
create or replace function public.fn_normalizar_escala(p_escala text)
returns text language sql immutable set search_path = public, pg_temp as $$
  select regexp_replace(lower(coalesce(p_escala, '')), '\s+', '', 'g');
$$;

create or replace function public.fn_posto_servico_escala_normalizada(p_posto_servico_id uuid)
returns text language sql stable set search_path = public, pg_temp as $$
  select public.fn_normalizar_escala(p.escala) from public.postos_servico p where p.id = p_posto_servico_id;
$$;

create or replace function public.fn_posto_servico_is_12x36(p_posto_servico_id uuid)
returns boolean language sql stable set search_path = public, pg_temp as $$
  select coalesce(public.fn_posto_servico_escala_normalizada(p_posto_servico_id) like '%12x36%', false);
$$;

create or replace function public.fn_posto_servico_is_6x1(p_posto_servico_id uuid)
returns boolean language sql stable set search_path = public, pg_temp as $$
  select coalesce(public.fn_posto_servico_escala_normalizada(p_posto_servico_id) like '%6x1%', false);
$$;

create or replace function public.fn_posto_servico_is_5x2(p_posto_servico_id uuid)
returns boolean language sql stable set search_path = public, pg_temp as $$
  select coalesce(public.fn_posto_servico_escala_normalizada(p_posto_servico_id) like '%5x2%', false);
$$;

-- 5. Dias obrigatórios da alocação
create or replace function public.fn_dias_obrigatorios_alocacao(p_posto_servico_id uuid)
returns smallint[] language plpgsql stable set search_path = public, pg_temp as $$
declare
  v_escala text; v_dias integer[];
begin
  select public.fn_normalizar_escala(p.escala), p.dias_semana
    into v_escala, v_dias
    from public.postos_servico p where p.id = p_posto_servico_id;
  if v_dias is not null and array_length(v_dias, 1) > 0 then
    return array(select distinct d::smallint from unnest(v_dias) as d where d between 1 and 7 order by d);
  end if;
  if v_escala like '%6x1%' then return array[1,2,3,4,5,6]::smallint[]; end if;
  if v_escala like '%5x2%' then return array[1,2,3,4,5]::smallint[]; end if;
  return array[]::smallint[];
end;
$$;

-- 6. Trigger validação paridade
create or replace function public.trg_validar_alocacao_por_posto()
returns trigger language plpgsql set search_path = public, pg_temp as $$
declare v_is_12x36 boolean;
begin
  select public.fn_posto_servico_is_12x36(new.posto_servico_id) into v_is_12x36;
  if v_is_12x36 then
    if new.paridade_12x36 is null then
      raise exception 'A paridade 12x36 é obrigatória para postos com escala 12x36.';
    end if;
    if new.paridade_12x36 not in ('impar', 'par') then
      raise exception 'A paridade 12x36 deve ser impar ou par.';
    end if;
  else
    new.paridade_12x36 := null;
  end if;
  return new;
end;
$$;

drop trigger if exists validar_alocacao_12x36 on public.colaboradores_convenia_alocacoes;
drop trigger if exists validar_alocacao_por_posto on public.colaboradores_convenia_alocacoes;
create trigger validar_alocacao_por_posto
  before insert or update on public.colaboradores_convenia_alocacoes
  for each row execute function public.trg_validar_alocacao_por_posto();

-- 7. Validação dos horários semanais
create or replace function public.fn_validar_horarios_semanais_alocacao(p_alocacao_id uuid)
returns void language plpgsql stable set search_path = public, pg_temp as $$
declare
  v_posto_servico_id uuid; v_dias_obrigatorios smallint[]; v_dias_cadastrados smallint[];
  v_dias_faltantes smallint[]; v_dias_extras smallint[];
begin
  select posto_servico_id into v_posto_servico_id
    from public.colaboradores_convenia_alocacoes where id = p_alocacao_id;
  if v_posto_servico_id is null then raise exception 'Alocação não encontrada.'; end if;
  v_dias_obrigatorios := public.fn_dias_obrigatorios_alocacao(v_posto_servico_id);
  select coalesce(array_agg(h.dia_semana order by h.dia_semana), array[]::smallint[])
    into v_dias_cadastrados
    from public.colaboradores_convenia_alocacao_horarios h where h.alocacao_id = p_alocacao_id;
  if coalesce(array_length(v_dias_obrigatorios, 1), 0) = 0 then
    if coalesce(array_length(v_dias_cadastrados, 1), 0) > 0 then
      raise exception 'Este posto não exige horários por dia. Use apenas o horário padrão da alocação.';
    end if;
    return;
  end if;
  select array_agg(d order by d) into v_dias_faltantes
    from unnest(v_dias_obrigatorios) d where not d = any(v_dias_cadastrados);
  if coalesce(array_length(v_dias_faltantes, 1), 0) > 0 then
    raise exception 'Horários obrigatórios ausentes para os dias da semana: %', v_dias_faltantes;
  end if;
  select array_agg(d order by d) into v_dias_extras
    from unnest(v_dias_cadastrados) d where not d = any(v_dias_obrigatorios);
  if coalesce(array_length(v_dias_extras, 1), 0) > 0 then
    raise exception 'Foram informados horários para dias fora da escala do posto: %', v_dias_extras;
  end if;
end;
$$;

-- 8. Upsert dos horários semanais
create or replace function public.fn_upsert_horarios_semanais_alocacao(
  p_alocacao_id uuid, p_horarios jsonb, p_usuario_id uuid
) returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  delete from public.colaboradores_convenia_alocacao_horarios where alocacao_id = p_alocacao_id;
  if p_horarios is null then
    perform public.fn_validar_horarios_semanais_alocacao(p_alocacao_id);
    return;
  end if;
  if jsonb_typeof(p_horarios) <> 'array' then
    raise exception 'p_horarios_semanais deve ser um array JSON.';
  end if;
  insert into public.colaboradores_convenia_alocacao_horarios (
    alocacao_id, dia_semana, horario_entrada, horario_saida, intervalo_inicio, intervalo_fim, created_by, updated_by
  )
  select p_alocacao_id, x.dia_semana, x.horario_entrada, x.horario_saida, x.intervalo_inicio, x.intervalo_fim, p_usuario_id, p_usuario_id
  from jsonb_to_recordset(p_horarios) as x(
    dia_semana smallint, horario_entrada time, horario_saida time, intervalo_inicio time, intervalo_fim time
  );
  perform public.fn_validar_horarios_semanais_alocacao(p_alocacao_id);
end;
$$;

-- 9. Trigger histórico
create or replace function public.trg_log_alocacao_convenia()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if current_setting('app.skip_alocacao_trigger', true) = 'true' then return new; end if;
  if tg_op = 'UPDATE' then
    insert into public.colaboradores_convenia_alocacoes_historico (
      colaborador_convenia_id, alocacao_id,
      posto_servico_id_anterior, posto_servico_id_novo,
      horario_entrada_anterior, horario_entrada_novo,
      horario_saida_anterior, horario_saida_novo,
      intervalo_inicio_anterior, intervalo_inicio_novo,
      intervalo_fim_anterior, intervalo_fim_novo,
      paridade_12x36_anterior, paridade_12x36_nova,
      operacao, motivo, registro_anterior, registro_novo, created_by
    ) values (
      new.colaborador_convenia_id, new.id,
      old.posto_servico_id, new.posto_servico_id,
      old.horario_entrada, new.horario_entrada,
      old.horario_saida, new.horario_saida,
      old.intervalo_inicio, new.intervalo_inicio,
      old.intervalo_fim, new.intervalo_fim,
      old.paridade_12x36, new.paridade_12x36,
      case
        when old.posto_servico_id is distinct from new.posto_servico_id then 'transferencia_posto'
        when old.paridade_12x36 is distinct from new.paridade_12x36 then 'alteracao_paridade_12x36'
        when old.horario_entrada is distinct from new.horario_entrada
          or old.horario_saida is distinct from new.horario_saida
          or old.intervalo_inicio is distinct from new.intervalo_inicio
          or old.intervalo_fim is distinct from new.intervalo_fim
          then 'alteracao_horario'
        else 'update_direto'
      end,
      'Histórico gerado automaticamente por update direto na tabela.',
      to_jsonb(old), to_jsonb(new), new.updated_by
    );
  end if;
  return new;
end;
$$;

-- 10. View
drop view if exists public.v_colaboradores_convenia_alocacao_atual;
create view public.v_colaboradores_convenia_alocacao_atual
with (security_invoker = true) as
select
  a.id as alocacao_id,
  c.id as colaborador_convenia_id,
  c.convenia_id,
  concat_ws(' ', c.name, c.last_name) as nome_colaborador,
  c.cpf, c.email, c.personal_email, c.registration, c.job_name,
  c.status as status_convenia,
  c.cost_center_id as colaborador_cost_center_id,
  c.cost_center_name as colaborador_cost_center_name,
  p.id as posto_servico_id,
  p.nome as posto_servico_nome,
  p.escala, p.dias_semana, p.turno, p.cliente_id, p.unidade_id,
  p.cost_center_id as posto_cost_center_id,
  cc.name as posto_cost_center_name,
  a.horario_entrada, a.horario_saida,
  a.intervalo_inicio, a.intervalo_fim,
  a.paridade_12x36,
  (
    select coalesce(jsonb_agg(jsonb_build_object(
      'dia_semana', h.dia_semana,
      'horario_entrada', h.horario_entrada,
      'horario_saida', h.horario_saida,
      'intervalo_inicio', h.intervalo_inicio,
      'intervalo_fim', h.intervalo_fim
    ) order by h.dia_semana), '[]'::jsonb)
    from public.colaboradores_convenia_alocacao_horarios h where h.alocacao_id = a.id
  ) as horarios_semanais,
  a.data_inicio, a.data_fim, a.ativo, a.observacao,
  a.created_at, a.created_by, a.updated_at, a.updated_by
from public.colaboradores_convenia_alocacoes a
join public.colaboradores_convenia c on c.id = a.colaborador_convenia_id
join public.postos_servico p on p.id = a.posto_servico_id
left join public.cost_center cc on cc.id = p.cost_center_id
where a.ativo = true;

-- 11. Drop assinaturas antigas
drop function if exists public.rpc_alocar_colaborador_convenia(uuid, uuid, time, time, integer, text, date, text, uuid);
drop function if exists public.rpc_movimentar_colaborador_convenia(uuid, uuid, time, time, integer, text, date, text, uuid);
drop function if exists public.rpc_alterar_horario_alocacao_convenia(uuid, time, time, integer, text, text, uuid);

-- 12. RPC alocar
create or replace function public.rpc_alocar_colaborador_convenia(
  p_colaborador_convenia_id uuid, p_posto_servico_id uuid,
  p_horario_entrada time, p_horario_saida time,
  p_intervalo_inicio time, p_intervalo_fim time,
  p_horarios_semanais jsonb,
  p_paridade_12x36 text, p_data_inicio date, p_motivo text, p_usuario_id uuid
) returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_alocacao_id uuid; v_registro_novo jsonb; v_horarios_novo jsonb;
begin
  perform set_config('app.skip_alocacao_trigger', 'true', true);
  if p_horario_entrada = p_horario_saida then raise exception 'Horário de entrada e saída não podem ser iguais.'; end if;
  if (p_intervalo_inicio is null) <> (p_intervalo_fim is null) then raise exception 'Informe intervalo_inicio e intervalo_fim juntos.'; end if;
  if p_intervalo_inicio is not null and p_intervalo_inicio = p_intervalo_fim then raise exception 'intervalo_inicio e intervalo_fim não podem ser iguais.'; end if;
  if exists (select 1 from public.colaboradores_convenia_alocacoes where colaborador_convenia_id = p_colaborador_convenia_id and ativo = true) then
    raise exception 'Este colaborador já possui uma alocação ativa.';
  end if;
  insert into public.colaboradores_convenia_alocacoes (
    colaborador_convenia_id, posto_servico_id, horario_entrada, horario_saida,
    intervalo_inicio, intervalo_fim, paridade_12x36, data_inicio, ativo, observacao, created_by, updated_by
  ) values (
    p_colaborador_convenia_id, p_posto_servico_id, p_horario_entrada, p_horario_saida,
    p_intervalo_inicio, p_intervalo_fim, p_paridade_12x36, coalesce(p_data_inicio, current_date),
    true, p_motivo, p_usuario_id, p_usuario_id
  ) returning id into v_alocacao_id;

  perform public.fn_upsert_horarios_semanais_alocacao(v_alocacao_id, p_horarios_semanais, p_usuario_id);

  select to_jsonb(a) into v_registro_novo from public.colaboradores_convenia_alocacoes a where a.id = v_alocacao_id;
  select coalesce(jsonb_agg(to_jsonb(h) order by h.dia_semana), '[]'::jsonb) into v_horarios_novo
    from public.colaboradores_convenia_alocacao_horarios h where h.alocacao_id = v_alocacao_id;

  insert into public.colaboradores_convenia_alocacoes_historico (
    colaborador_convenia_id, alocacao_id,
    posto_servico_id_anterior, posto_servico_id_novo,
    horario_entrada_anterior, horario_entrada_novo,
    horario_saida_anterior, horario_saida_novo,
    intervalo_inicio_anterior, intervalo_inicio_novo,
    intervalo_fim_anterior, intervalo_fim_novo,
    paridade_12x36_anterior, paridade_12x36_nova,
    horarios_semanais_anterior, horarios_semanais_novo,
    operacao, motivo, registro_anterior, registro_novo, created_by
  ) values (
    p_colaborador_convenia_id, v_alocacao_id,
    null, p_posto_servico_id,
    null, p_horario_entrada,
    null, p_horario_saida,
    null, p_intervalo_inicio,
    null, p_intervalo_fim,
    null, p_paridade_12x36,
    null, v_horarios_novo,
    'alocacao_inicial', p_motivo,
    null, v_registro_novo, p_usuario_id
  );
  return v_alocacao_id;
end;
$$;

-- 13. RPC alterar horário
create or replace function public.rpc_alterar_horario_alocacao_convenia(
  p_colaborador_convenia_id uuid,
  p_horario_entrada time, p_horario_saida time,
  p_intervalo_inicio time, p_intervalo_fim time,
  p_horarios_semanais jsonb,
  p_paridade_12x36 text, p_motivo text, p_usuario_id uuid
) returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_alocacao_atual public.colaboradores_convenia_alocacoes%rowtype;
  v_alocacao_atualizada jsonb; v_horarios_anterior jsonb; v_horarios_novo jsonb; v_operacao text;
begin
  perform set_config('app.skip_alocacao_trigger', 'true', true);
  if p_horario_entrada = p_horario_saida then raise exception 'Horário de entrada e saída não podem ser iguais.'; end if;
  if (p_intervalo_inicio is null) <> (p_intervalo_fim is null) then raise exception 'Informe intervalo_inicio e intervalo_fim juntos.'; end if;
  if p_intervalo_inicio is not null and p_intervalo_inicio = p_intervalo_fim then raise exception 'intervalo_inicio e intervalo_fim não podem ser iguais.'; end if;

  select * into v_alocacao_atual from public.colaboradores_convenia_alocacoes
    where colaborador_convenia_id = p_colaborador_convenia_id and ativo = true for update;
  if not found then raise exception 'Colaborador não possui alocação ativa.'; end if;

  select coalesce(jsonb_agg(to_jsonb(h) order by h.dia_semana), '[]'::jsonb) into v_horarios_anterior
    from public.colaboradores_convenia_alocacao_horarios h where h.alocacao_id = v_alocacao_atual.id;

  update public.colaboradores_convenia_alocacoes set
    horario_entrada = p_horario_entrada, horario_saida = p_horario_saida,
    intervalo_inicio = p_intervalo_inicio, intervalo_fim = p_intervalo_fim,
    paridade_12x36 = p_paridade_12x36, observacao = p_motivo, updated_by = p_usuario_id
  where id = v_alocacao_atual.id;

  perform public.fn_upsert_horarios_semanais_alocacao(v_alocacao_atual.id, p_horarios_semanais, p_usuario_id);

  select to_jsonb(a) into v_alocacao_atualizada from public.colaboradores_convenia_alocacoes a where a.id = v_alocacao_atual.id;
  select coalesce(jsonb_agg(to_jsonb(h) order by h.dia_semana), '[]'::jsonb) into v_horarios_novo
    from public.colaboradores_convenia_alocacao_horarios h where h.alocacao_id = v_alocacao_atual.id;

  if v_alocacao_atual.paridade_12x36 is distinct from p_paridade_12x36
     and v_alocacao_atual.horario_entrada is not distinct from p_horario_entrada
     and v_alocacao_atual.horario_saida is not distinct from p_horario_saida
     and v_alocacao_atual.intervalo_inicio is not distinct from p_intervalo_inicio
     and v_alocacao_atual.intervalo_fim is not distinct from p_intervalo_fim
     and v_horarios_anterior = v_horarios_novo
  then v_operacao := 'alteracao_paridade_12x36';
  else v_operacao := 'alteracao_horario';
  end if;

  insert into public.colaboradores_convenia_alocacoes_historico (
    colaborador_convenia_id, alocacao_id,
    posto_servico_id_anterior, posto_servico_id_novo,
    horario_entrada_anterior, horario_entrada_novo,
    horario_saida_anterior, horario_saida_novo,
    intervalo_inicio_anterior, intervalo_inicio_novo,
    intervalo_fim_anterior, intervalo_fim_novo,
    paridade_12x36_anterior, paridade_12x36_nova,
    horarios_semanais_anterior, horarios_semanais_novo,
    operacao, motivo, registro_anterior, registro_novo, created_by
  ) values (
    p_colaborador_convenia_id, v_alocacao_atual.id,
    v_alocacao_atual.posto_servico_id, v_alocacao_atual.posto_servico_id,
    v_alocacao_atual.horario_entrada, p_horario_entrada,
    v_alocacao_atual.horario_saida, p_horario_saida,
    v_alocacao_atual.intervalo_inicio, p_intervalo_inicio,
    v_alocacao_atual.intervalo_fim, p_intervalo_fim,
    v_alocacao_atual.paridade_12x36, p_paridade_12x36,
    v_horarios_anterior, v_horarios_novo,
    v_operacao, p_motivo,
    to_jsonb(v_alocacao_atual), v_alocacao_atualizada, p_usuario_id
  );
  return v_alocacao_atual.id;
end;
$$;

-- 14. RPC movimentar
create or replace function public.rpc_movimentar_colaborador_convenia(
  p_colaborador_convenia_id uuid, p_novo_posto_servico_id uuid,
  p_horario_entrada time, p_horario_saida time,
  p_intervalo_inicio time, p_intervalo_fim time,
  p_horarios_semanais jsonb,
  p_paridade_12x36 text, p_data_inicio date, p_motivo text, p_usuario_id uuid
) returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_alocacao_atual public.colaboradores_convenia_alocacoes%rowtype;
  v_nova_alocacao_id uuid; v_registro_novo jsonb; v_horarios_anterior jsonb; v_horarios_novo jsonb;
begin
  perform set_config('app.skip_alocacao_trigger', 'true', true);
  if p_horario_entrada = p_horario_saida then raise exception 'Horário de entrada e saída não podem ser iguais.'; end if;
  if (p_intervalo_inicio is null) <> (p_intervalo_fim is null) then raise exception 'Informe intervalo_inicio e intervalo_fim juntos.'; end if;
  if p_intervalo_inicio is not null and p_intervalo_inicio = p_intervalo_fim then raise exception 'intervalo_inicio e intervalo_fim não podem ser iguais.'; end if;

  select * into v_alocacao_atual from public.colaboradores_convenia_alocacoes
    where colaborador_convenia_id = p_colaborador_convenia_id and ativo = true for update;
  if not found then raise exception 'Colaborador não possui alocação ativa.'; end if;
  if v_alocacao_atual.posto_servico_id = p_novo_posto_servico_id then
    raise exception 'O novo posto de serviço é igual ao posto atual.';
  end if;

  select coalesce(jsonb_agg(to_jsonb(h) order by h.dia_semana), '[]'::jsonb) into v_horarios_anterior
    from public.colaboradores_convenia_alocacao_horarios h where h.alocacao_id = v_alocacao_atual.id;

  update public.colaboradores_convenia_alocacoes set
    ativo = false, data_fim = coalesce(p_data_inicio, current_date) - 1, updated_by = p_usuario_id
  where id = v_alocacao_atual.id;

  insert into public.colaboradores_convenia_alocacoes (
    colaborador_convenia_id, posto_servico_id, horario_entrada, horario_saida,
    intervalo_inicio, intervalo_fim, paridade_12x36, data_inicio, ativo, observacao, created_by, updated_by
  ) values (
    p_colaborador_convenia_id, p_novo_posto_servico_id, p_horario_entrada, p_horario_saida,
    p_intervalo_inicio, p_intervalo_fim, p_paridade_12x36, coalesce(p_data_inicio, current_date),
    true, p_motivo, p_usuario_id, p_usuario_id
  ) returning id into v_nova_alocacao_id;

  perform public.fn_upsert_horarios_semanais_alocacao(v_nova_alocacao_id, p_horarios_semanais, p_usuario_id);

  select to_jsonb(a) into v_registro_novo from public.colaboradores_convenia_alocacoes a where a.id = v_nova_alocacao_id;
  select coalesce(jsonb_agg(to_jsonb(h) order by h.dia_semana), '[]'::jsonb) into v_horarios_novo
    from public.colaboradores_convenia_alocacao_horarios h where h.alocacao_id = v_nova_alocacao_id;

  insert into public.colaboradores_convenia_alocacoes_historico (
    colaborador_convenia_id, alocacao_id,
    posto_servico_id_anterior, posto_servico_id_novo,
    horario_entrada_anterior, horario_entrada_novo,
    horario_saida_anterior, horario_saida_novo,
    intervalo_inicio_anterior, intervalo_inicio_novo,
    intervalo_fim_anterior, intervalo_fim_novo,
    paridade_12x36_anterior, paridade_12x36_nova,
    horarios_semanais_anterior, horarios_semanais_novo,
    operacao, motivo, registro_anterior, registro_novo, created_by
  ) values (
    p_colaborador_convenia_id, v_nova_alocacao_id,
    v_alocacao_atual.posto_servico_id, p_novo_posto_servico_id,
    v_alocacao_atual.horario_entrada, p_horario_entrada,
    v_alocacao_atual.horario_saida, p_horario_saida,
    v_alocacao_atual.intervalo_inicio, p_intervalo_inicio,
    v_alocacao_atual.intervalo_fim, p_intervalo_fim,
    v_alocacao_atual.paridade_12x36, p_paridade_12x36,
    v_horarios_anterior, v_horarios_novo,
    'transferencia_posto', p_motivo,
    to_jsonb(v_alocacao_atual), v_registro_novo, p_usuario_id
  );
  return v_nova_alocacao_id;
end;
$$;

-- 15. RPC histórico
drop function if exists public.rpc_get_historico_alocacao_colaborador_convenia(uuid);
create or replace function public.rpc_get_historico_alocacao_colaborador_convenia(p_colaborador_convenia_id uuid)
returns table (
  id uuid, colaborador_convenia_id uuid, alocacao_id uuid,
  posto_servico_id_anterior uuid, posto_servico_anterior_nome text,
  posto_servico_id_novo uuid, posto_servico_novo_nome text,
  horario_entrada_anterior time, horario_entrada_novo time,
  horario_saida_anterior time, horario_saida_novo time,
  intervalo_inicio_anterior time, intervalo_inicio_novo time,
  intervalo_fim_anterior time, intervalo_fim_novo time,
  paridade_12x36_anterior text, paridade_12x36_nova text,
  horarios_semanais_anterior jsonb, horarios_semanais_novo jsonb,
  operacao text, motivo text,
  registro_anterior jsonb, registro_novo jsonb,
  created_at timestamptz, created_by uuid
) language sql stable security definer set search_path = public, pg_temp as $$
  select h.id, h.colaborador_convenia_id, h.alocacao_id,
    h.posto_servico_id_anterior, p_ant.nome,
    h.posto_servico_id_novo, p_novo.nome,
    h.horario_entrada_anterior, h.horario_entrada_novo,
    h.horario_saida_anterior, h.horario_saida_novo,
    h.intervalo_inicio_anterior, h.intervalo_inicio_novo,
    h.intervalo_fim_anterior, h.intervalo_fim_novo,
    h.paridade_12x36_anterior, h.paridade_12x36_nova,
    h.horarios_semanais_anterior, h.horarios_semanais_novo,
    h.operacao, h.motivo,
    h.registro_anterior, h.registro_novo,
    h.created_at, h.created_by
  from public.colaboradores_convenia_alocacoes_historico h
  left join public.postos_servico p_ant on p_ant.id = h.posto_servico_id_anterior
  left join public.postos_servico p_novo on p_novo.id = h.posto_servico_id_novo
  where h.colaborador_convenia_id = p_colaborador_convenia_id
  order by h.created_at desc;
$$;

-- 16. fn_alternar_paridade_12x36_mensal usando novos campos
create or replace function public.fn_alternar_paridade_12x36_mensal()
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_primeiro_dia_mes_atual date; v_ultimo_dia_mes_anterior date; v_dias_mes_anterior integer;
  r record; v_nova_paridade text; v_registro_novo jsonb;
begin
  perform set_config('app.skip_alocacao_trigger','true',true);
  v_primeiro_dia_mes_atual := date_trunc('month', current_date)::date;
  v_ultimo_dia_mes_anterior := v_primeiro_dia_mes_atual - 1;
  v_dias_mes_anterior := extract(day from v_ultimo_dia_mes_anterior)::integer;
  if mod(v_dias_mes_anterior, 2) = 0 then return; end if;
  for r in
    select a.* from public.colaboradores_convenia_alocacoes a
    join public.postos_servico p on p.id = a.posto_servico_id
    where a.ativo = true
      and regexp_replace(lower(coalesce(p.escala,'')), '\s+', '', 'g') like '%12x36%'
      and a.paridade_12x36 in ('impar','par')
  loop
    v_nova_paridade := case when r.paridade_12x36 = 'impar' then 'par' else 'impar' end;
    update public.colaboradores_convenia_alocacoes
      set paridade_12x36 = v_nova_paridade, updated_at = now(), updated_by = null
      where id = r.id;
    select to_jsonb(a) into v_registro_novo from public.colaboradores_convenia_alocacoes a where a.id = r.id;
    insert into public.colaboradores_convenia_alocacoes_historico (
      colaborador_convenia_id, alocacao_id, posto_servico_id_anterior, posto_servico_id_novo,
      horario_entrada_anterior, horario_entrada_novo, horario_saida_anterior, horario_saida_novo,
      intervalo_inicio_anterior, intervalo_inicio_novo,
      intervalo_fim_anterior, intervalo_fim_novo,
      paridade_12x36_anterior, paridade_12x36_nova,
      operacao, motivo, registro_anterior, registro_novo, created_by
    ) values (
      r.colaborador_convenia_id, r.id, r.posto_servico_id, r.posto_servico_id,
      r.horario_entrada, r.horario_entrada, r.horario_saida, r.horario_saida,
      r.intervalo_inicio, r.intervalo_inicio,
      r.intervalo_fim, r.intervalo_fim,
      r.paridade_12x36, v_nova_paridade,
      'atualizacao_automatica_12x36',
      'Alternância automática mensal da escala 12x36 devido ao mês anterior ter quantidade ímpar de dias.',
      to_jsonb(r), v_registro_novo, null
    );
  end loop;
end;
$$;

-- 17. Grants
grant select on public.colaboradores_convenia_alocacao_horarios to authenticated;
grant select on public.v_colaboradores_convenia_alocacao_atual to authenticated;
grant execute on function public.fn_upsert_horarios_semanais_alocacao(uuid, jsonb, uuid) to authenticated;
grant execute on function public.rpc_alocar_colaborador_convenia(uuid, uuid, time, time, time, time, jsonb, text, date, text, uuid) to authenticated;
grant execute on function public.rpc_movimentar_colaborador_convenia(uuid, uuid, time, time, time, time, jsonb, text, date, text, uuid) to authenticated;
grant execute on function public.rpc_alterar_horario_alocacao_convenia(uuid, time, time, time, time, jsonb, text, text, uuid) to authenticated;
grant execute on function public.rpc_get_historico_alocacao_colaborador_convenia(uuid) to authenticated;
