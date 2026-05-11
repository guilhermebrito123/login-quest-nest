
-- 1. Tabela principal
create table if not exists public.colaboradores_convenia_alocacoes (
  id uuid primary key default gen_random_uuid(),
  colaborador_convenia_id uuid not null references public.colaboradores_convenia(id) on delete restrict,
  posto_servico_id uuid not null references public.postos_servico(id) on delete restrict,
  horario_entrada time not null,
  horario_saida time not null,
  intervalo_minutos integer null,
  paridade_12x36 text null,
  data_inicio date not null default current_date,
  data_fim date null,
  ativo boolean not null default true,
  observacao text null,
  created_at timestamptz not null default now(),
  created_by uuid null references public.usuarios(id),
  updated_at timestamptz not null default now(),
  updated_by uuid null references public.usuarios(id)
);

-- 2. Constraints alocações
alter table public.colaboradores_convenia_alocacoes drop constraint if exists chk_alocacao_horarios_diferentes;
alter table public.colaboradores_convenia_alocacoes add constraint chk_alocacao_horarios_diferentes check (horario_entrada <> horario_saida);
alter table public.colaboradores_convenia_alocacoes drop constraint if exists chk_alocacao_intervalo_valido;
alter table public.colaboradores_convenia_alocacoes add constraint chk_alocacao_intervalo_valido check (intervalo_minutos is null or intervalo_minutos >= 0);
alter table public.colaboradores_convenia_alocacoes drop constraint if exists chk_alocacao_datas_validas;
alter table public.colaboradores_convenia_alocacoes add constraint chk_alocacao_datas_validas check (data_fim is null or data_fim >= data_inicio);
alter table public.colaboradores_convenia_alocacoes drop constraint if exists chk_alocacao_paridade_12x36;
alter table public.colaboradores_convenia_alocacoes add constraint chk_alocacao_paridade_12x36 check (paridade_12x36 is null or paridade_12x36 in ('impar','par'));

-- 3. Única alocação ativa por colaborador
drop index if exists public.uq_colaborador_convenia_alocacao_ativa;
create unique index uq_colaborador_convenia_alocacao_ativa on public.colaboradores_convenia_alocacoes (colaborador_convenia_id) where ativo = true;

-- 4. Tabela histórico
create table if not exists public.colaboradores_convenia_alocacoes_historico (
  id uuid primary key default gen_random_uuid(),
  colaborador_convenia_id uuid not null references public.colaboradores_convenia(id) on delete restrict,
  alocacao_id uuid null references public.colaboradores_convenia_alocacoes(id) on delete set null,
  posto_servico_id_anterior uuid null references public.postos_servico(id) on delete restrict,
  posto_servico_id_novo uuid null references public.postos_servico(id) on delete restrict,
  horario_entrada_anterior time null,
  horario_entrada_novo time null,
  horario_saida_anterior time null,
  horario_saida_novo time null,
  intervalo_minutos_anterior integer null,
  intervalo_minutos_novo integer null,
  paridade_12x36_anterior text null,
  paridade_12x36_nova text null,
  operacao text not null,
  motivo text null,
  registro_anterior jsonb null,
  registro_novo jsonb null,
  created_at timestamptz not null default now(),
  created_by uuid null references public.usuarios(id)
);

-- 5. Constraints histórico
alter table public.colaboradores_convenia_alocacoes_historico drop constraint if exists chk_hist_operacao_alocacao;
alter table public.colaboradores_convenia_alocacoes_historico add constraint chk_hist_operacao_alocacao check (operacao in ('alocacao_inicial','transferencia_posto','alteracao_horario','alteracao_paridade_12x36','desvinculacao','atualizacao_automatica_12x36','update_direto'));
alter table public.colaboradores_convenia_alocacoes_historico drop constraint if exists chk_hist_paridade_anterior;
alter table public.colaboradores_convenia_alocacoes_historico add constraint chk_hist_paridade_anterior check (paridade_12x36_anterior is null or paridade_12x36_anterior in ('impar','par'));
alter table public.colaboradores_convenia_alocacoes_historico drop constraint if exists chk_hist_paridade_nova;
alter table public.colaboradores_convenia_alocacoes_historico add constraint chk_hist_paridade_nova check (paridade_12x36_nova is null or paridade_12x36_nova in ('impar','par'));

-- 6. Índices
create index if not exists idx_alocacoes_convenia_colaborador on public.colaboradores_convenia_alocacoes (colaborador_convenia_id);
create index if not exists idx_alocacoes_convenia_posto on public.colaboradores_convenia_alocacoes (posto_servico_id);
create index if not exists idx_alocacoes_convenia_ativo on public.colaboradores_convenia_alocacoes (ativo);
create index if not exists idx_alocacoes_convenia_colaborador_ativo on public.colaboradores_convenia_alocacoes (colaborador_convenia_id, ativo);
create index if not exists idx_hist_alocacoes_convenia_colaborador on public.colaboradores_convenia_alocacoes_historico (colaborador_convenia_id);
create index if not exists idx_hist_alocacoes_convenia_alocacao on public.colaboradores_convenia_alocacoes_historico (alocacao_id);
create index if not exists idx_hist_alocacoes_convenia_created_at on public.colaboradores_convenia_alocacoes_historico (created_at desc);

-- 7. Função auxiliar 12x36
create or replace function public.fn_posto_servico_is_12x36(p_posto_servico_id uuid)
returns boolean language plpgsql stable set search_path = public, pg_temp as $$
declare v_escala text;
begin
  select escala into v_escala from public.postos_servico where id = p_posto_servico_id;
  if v_escala is null then return false; end if;
  return regexp_replace(lower(v_escala), '\s+', '', 'g') like '%12x36%';
end;
$$;

-- 8. Trigger valida paridade 12x36
create or replace function public.trg_validar_alocacao_12x36()
returns trigger language plpgsql set search_path = public, pg_temp as $$
declare v_is_12x36 boolean;
begin
  select public.fn_posto_servico_is_12x36(new.posto_servico_id) into v_is_12x36;
  if v_is_12x36 then
    if new.paridade_12x36 is null then
      raise exception 'A paridade 12x36 é obrigatória para postos com escala 12x36.';
    end if;
    if new.paridade_12x36 not in ('impar','par') then
      raise exception 'A paridade 12x36 deve ser impar ou par.';
    end if;
  else
    new.paridade_12x36 := null;
  end if;
  return new;
end;
$$;

drop trigger if exists validar_alocacao_12x36 on public.colaboradores_convenia_alocacoes;
create trigger validar_alocacao_12x36
before insert or update on public.colaboradores_convenia_alocacoes
for each row execute function public.trg_validar_alocacao_12x36();

-- 9. Trigger updated_at
create or replace function public.trg_set_updated_at_alocacao_convenia()
returns trigger language plpgsql set search_path = public, pg_temp as $$
begin new.updated_at := now(); return new; end;
$$;

drop trigger if exists set_updated_at_alocacao_convenia on public.colaboradores_convenia_alocacoes;
create trigger set_updated_at_alocacao_convenia
before update on public.colaboradores_convenia_alocacoes
for each row execute function public.trg_set_updated_at_alocacao_convenia();

-- 10. Trigger histórico para updates diretos
create or replace function public.trg_log_alocacao_convenia()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if current_setting('app.skip_alocacao_trigger', true) = 'true' then
    return new;
  end if;
  if tg_op = 'UPDATE' then
    insert into public.colaboradores_convenia_alocacoes_historico (
      colaborador_convenia_id, alocacao_id,
      posto_servico_id_anterior, posto_servico_id_novo,
      horario_entrada_anterior, horario_entrada_novo,
      horario_saida_anterior, horario_saida_novo,
      intervalo_minutos_anterior, intervalo_minutos_novo,
      paridade_12x36_anterior, paridade_12x36_nova,
      operacao, motivo, registro_anterior, registro_novo, created_by
    ) values (
      new.colaborador_convenia_id, new.id,
      old.posto_servico_id, new.posto_servico_id,
      old.horario_entrada, new.horario_entrada,
      old.horario_saida, new.horario_saida,
      old.intervalo_minutos, new.intervalo_minutos,
      old.paridade_12x36, new.paridade_12x36,
      case
        when old.posto_servico_id is distinct from new.posto_servico_id then 'transferencia_posto'
        when old.paridade_12x36 is distinct from new.paridade_12x36 then 'alteracao_paridade_12x36'
        when old.horario_entrada is distinct from new.horario_entrada
          or old.horario_saida is distinct from new.horario_saida
          or old.intervalo_minutos is distinct from new.intervalo_minutos then 'alteracao_horario'
        else 'update_direto'
      end,
      'Histórico gerado automaticamente por update direto na tabela.',
      to_jsonb(old), to_jsonb(new), new.updated_by
    );
  end if;
  return new;
end;
$$;

drop trigger if exists log_alocacao_convenia on public.colaboradores_convenia_alocacoes;
create trigger log_alocacao_convenia
after update on public.colaboradores_convenia_alocacoes
for each row execute function public.trg_log_alocacao_convenia();

-- 11. View
create or replace view public.v_colaboradores_convenia_alocacao_atual as
select
  a.id as alocacao_id,
  c.id as colaborador_convenia_id,
  c.convenia_id,
  concat_ws(' ', c.name, c.last_name) as nome_colaborador,
  c.cpf, c.email, c.personal_email, c.registration, c.job_name,
  c.status as status_convenia,
  c.cost_center_id, c.cost_center_name,
  p.id as posto_servico_id,
  p.nome as posto_servico_nome,
  p.escala, p.dias_semana,
  p.cliente_id, p.unidade_id,
  p.cost_center_id as posto_cost_center_id,
  a.horario_entrada, a.horario_saida, a.intervalo_minutos, a.paridade_12x36,
  a.data_inicio, a.data_fim, a.ativo, a.observacao,
  a.created_at, a.created_by, a.updated_at, a.updated_by
from public.colaboradores_convenia_alocacoes a
join public.colaboradores_convenia c on c.id = a.colaborador_convenia_id
join public.postos_servico p on p.id = a.posto_servico_id
where a.ativo = true;

-- 12. RPC alocar
create or replace function public.rpc_alocar_colaborador_convenia(
  p_colaborador_convenia_id uuid, p_posto_servico_id uuid,
  p_horario_entrada time, p_horario_saida time,
  p_intervalo_minutos integer, p_paridade_12x36 text,
  p_data_inicio date, p_motivo text, p_usuario_id uuid
) returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_alocacao_id uuid; v_registro_novo jsonb;
begin
  perform set_config('app.skip_alocacao_trigger','true',true);
  if p_horario_entrada = p_horario_saida then raise exception 'Horário de entrada e saída não podem ser iguais.'; end if;
  if p_intervalo_minutos is not null and p_intervalo_minutos < 0 then raise exception 'Intervalo não pode ser negativo.'; end if;
  if exists (select 1 from public.colaboradores_convenia_alocacoes where colaborador_convenia_id = p_colaborador_convenia_id and ativo = true) then
    raise exception 'Este colaborador já possui uma alocação ativa.';
  end if;
  insert into public.colaboradores_convenia_alocacoes (
    colaborador_convenia_id, posto_servico_id, horario_entrada, horario_saida,
    intervalo_minutos, paridade_12x36, data_inicio, ativo, observacao, created_by, updated_by
  ) values (
    p_colaborador_convenia_id, p_posto_servico_id, p_horario_entrada, p_horario_saida,
    p_intervalo_minutos, p_paridade_12x36, coalesce(p_data_inicio, current_date), true, p_motivo, p_usuario_id, p_usuario_id
  ) returning id into v_alocacao_id;
  select to_jsonb(a) into v_registro_novo from public.colaboradores_convenia_alocacoes a where a.id = v_alocacao_id;
  insert into public.colaboradores_convenia_alocacoes_historico (
    colaborador_convenia_id, alocacao_id, posto_servico_id_anterior, posto_servico_id_novo,
    horario_entrada_anterior, horario_entrada_novo, horario_saida_anterior, horario_saida_novo,
    intervalo_minutos_anterior, intervalo_minutos_novo, paridade_12x36_anterior, paridade_12x36_nova,
    operacao, motivo, registro_anterior, registro_novo, created_by
  ) values (
    p_colaborador_convenia_id, v_alocacao_id, null, p_posto_servico_id,
    null, p_horario_entrada, null, p_horario_saida,
    null, p_intervalo_minutos, null, p_paridade_12x36,
    'alocacao_inicial', p_motivo, null, v_registro_novo, p_usuario_id
  );
  return v_alocacao_id;
end;
$$;

-- 13. RPC movimentar
create or replace function public.rpc_movimentar_colaborador_convenia(
  p_colaborador_convenia_id uuid, p_novo_posto_servico_id uuid,
  p_horario_entrada time, p_horario_saida time,
  p_intervalo_minutos integer, p_paridade_12x36 text,
  p_data_inicio date, p_motivo text, p_usuario_id uuid
) returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_alocacao_atual public.colaboradores_convenia_alocacoes%rowtype; v_nova_alocacao_id uuid; v_registro_novo jsonb;
begin
  perform set_config('app.skip_alocacao_trigger','true',true);
  if p_horario_entrada = p_horario_saida then raise exception 'Horário de entrada e saída não podem ser iguais.'; end if;
  if p_intervalo_minutos is not null and p_intervalo_minutos < 0 then raise exception 'Intervalo não pode ser negativo.'; end if;
  select * into v_alocacao_atual from public.colaboradores_convenia_alocacoes where colaborador_convenia_id = p_colaborador_convenia_id and ativo = true for update;
  if not found then raise exception 'Colaborador não possui alocação ativa.'; end if;
  if v_alocacao_atual.posto_servico_id = p_novo_posto_servico_id then raise exception 'O novo posto de serviço é igual ao posto atual.'; end if;
  update public.colaboradores_convenia_alocacoes
    set ativo = false, data_fim = coalesce(p_data_inicio, current_date) - 1, updated_by = p_usuario_id
    where id = v_alocacao_atual.id;
  insert into public.colaboradores_convenia_alocacoes (
    colaborador_convenia_id, posto_servico_id, horario_entrada, horario_saida,
    intervalo_minutos, paridade_12x36, data_inicio, ativo, observacao, created_by, updated_by
  ) values (
    p_colaborador_convenia_id, p_novo_posto_servico_id, p_horario_entrada, p_horario_saida,
    p_intervalo_minutos, p_paridade_12x36, coalesce(p_data_inicio, current_date), true, p_motivo, p_usuario_id, p_usuario_id
  ) returning id into v_nova_alocacao_id;
  select to_jsonb(a) into v_registro_novo from public.colaboradores_convenia_alocacoes a where a.id = v_nova_alocacao_id;
  insert into public.colaboradores_convenia_alocacoes_historico (
    colaborador_convenia_id, alocacao_id, posto_servico_id_anterior, posto_servico_id_novo,
    horario_entrada_anterior, horario_entrada_novo, horario_saida_anterior, horario_saida_novo,
    intervalo_minutos_anterior, intervalo_minutos_novo, paridade_12x36_anterior, paridade_12x36_nova,
    operacao, motivo, registro_anterior, registro_novo, created_by
  ) values (
    p_colaborador_convenia_id, v_nova_alocacao_id,
    v_alocacao_atual.posto_servico_id, p_novo_posto_servico_id,
    v_alocacao_atual.horario_entrada, p_horario_entrada,
    v_alocacao_atual.horario_saida, p_horario_saida,
    v_alocacao_atual.intervalo_minutos, p_intervalo_minutos,
    v_alocacao_atual.paridade_12x36, p_paridade_12x36,
    'transferencia_posto', p_motivo, to_jsonb(v_alocacao_atual), v_registro_novo, p_usuario_id
  );
  return v_nova_alocacao_id;
end;
$$;

-- 14. RPC alterar horário/paridade
create or replace function public.rpc_alterar_horario_alocacao_convenia(
  p_colaborador_convenia_id uuid,
  p_horario_entrada time, p_horario_saida time,
  p_intervalo_minutos integer, p_paridade_12x36 text,
  p_motivo text, p_usuario_id uuid
) returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_alocacao_atual public.colaboradores_convenia_alocacoes%rowtype; v_alocacao_atualizada jsonb; v_operacao text;
begin
  perform set_config('app.skip_alocacao_trigger','true',true);
  if p_horario_entrada = p_horario_saida then raise exception 'Horário de entrada e saída não podem ser iguais.'; end if;
  if p_intervalo_minutos is not null and p_intervalo_minutos < 0 then raise exception 'Intervalo não pode ser negativo.'; end if;
  select * into v_alocacao_atual from public.colaboradores_convenia_alocacoes where colaborador_convenia_id = p_colaborador_convenia_id and ativo = true for update;
  if not found then raise exception 'Colaborador não possui alocação ativa.'; end if;
  update public.colaboradores_convenia_alocacoes
    set horario_entrada = p_horario_entrada, horario_saida = p_horario_saida,
        intervalo_minutos = p_intervalo_minutos, paridade_12x36 = p_paridade_12x36,
        observacao = p_motivo, updated_by = p_usuario_id
    where id = v_alocacao_atual.id;
  select to_jsonb(a) into v_alocacao_atualizada from public.colaboradores_convenia_alocacoes a where a.id = v_alocacao_atual.id;
  if v_alocacao_atual.paridade_12x36 is distinct from p_paridade_12x36
     and v_alocacao_atual.horario_entrada is not distinct from p_horario_entrada
     and v_alocacao_atual.horario_saida is not distinct from p_horario_saida
     and v_alocacao_atual.intervalo_minutos is not distinct from p_intervalo_minutos
  then v_operacao := 'alteracao_paridade_12x36';
  else v_operacao := 'alteracao_horario';
  end if;
  insert into public.colaboradores_convenia_alocacoes_historico (
    colaborador_convenia_id, alocacao_id, posto_servico_id_anterior, posto_servico_id_novo,
    horario_entrada_anterior, horario_entrada_novo, horario_saida_anterior, horario_saida_novo,
    intervalo_minutos_anterior, intervalo_minutos_novo, paridade_12x36_anterior, paridade_12x36_nova,
    operacao, motivo, registro_anterior, registro_novo, created_by
  ) values (
    p_colaborador_convenia_id, v_alocacao_atual.id,
    v_alocacao_atual.posto_servico_id, v_alocacao_atual.posto_servico_id,
    v_alocacao_atual.horario_entrada, p_horario_entrada,
    v_alocacao_atual.horario_saida, p_horario_saida,
    v_alocacao_atual.intervalo_minutos, p_intervalo_minutos,
    v_alocacao_atual.paridade_12x36, p_paridade_12x36,
    v_operacao, p_motivo, to_jsonb(v_alocacao_atual), v_alocacao_atualizada, p_usuario_id
  );
  return v_alocacao_atual.id;
end;
$$;

-- 15. RPC desvincular
create or replace function public.rpc_desvincular_colaborador_convenia(
  p_colaborador_convenia_id uuid, p_data_fim date, p_motivo text, p_usuario_id uuid
) returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_alocacao_atual public.colaboradores_convenia_alocacoes%rowtype; v_registro_novo jsonb;
begin
  perform set_config('app.skip_alocacao_trigger','true',true);
  select * into v_alocacao_atual from public.colaboradores_convenia_alocacoes where colaborador_convenia_id = p_colaborador_convenia_id and ativo = true for update;
  if not found then raise exception 'Colaborador não possui alocação ativa.'; end if;
  update public.colaboradores_convenia_alocacoes
    set ativo = false, data_fim = coalesce(p_data_fim, current_date), observacao = p_motivo, updated_by = p_usuario_id
    where id = v_alocacao_atual.id;
  select to_jsonb(a) into v_registro_novo from public.colaboradores_convenia_alocacoes a where a.id = v_alocacao_atual.id;
  insert into public.colaboradores_convenia_alocacoes_historico (
    colaborador_convenia_id, alocacao_id, posto_servico_id_anterior, posto_servico_id_novo,
    horario_entrada_anterior, horario_entrada_novo, horario_saida_anterior, horario_saida_novo,
    intervalo_minutos_anterior, intervalo_minutos_novo, paridade_12x36_anterior, paridade_12x36_nova,
    operacao, motivo, registro_anterior, registro_novo, created_by
  ) values (
    p_colaborador_convenia_id, v_alocacao_atual.id,
    v_alocacao_atual.posto_servico_id, null,
    v_alocacao_atual.horario_entrada, null,
    v_alocacao_atual.horario_saida, null,
    v_alocacao_atual.intervalo_minutos, null,
    v_alocacao_atual.paridade_12x36, null,
    'desvinculacao', p_motivo, to_jsonb(v_alocacao_atual), v_registro_novo, p_usuario_id
  );
  return v_alocacao_atual.id;
end;
$$;

-- 16. RPC histórico
create or replace function public.rpc_get_historico_alocacao_colaborador_convenia(p_colaborador_convenia_id uuid)
returns table (
  id uuid, colaborador_convenia_id uuid, alocacao_id uuid,
  posto_servico_id_anterior uuid, posto_servico_anterior_nome text,
  posto_servico_id_novo uuid, posto_servico_novo_nome text,
  horario_entrada_anterior time, horario_entrada_novo time,
  horario_saida_anterior time, horario_saida_novo time,
  intervalo_minutos_anterior integer, intervalo_minutos_novo integer,
  paridade_12x36_anterior text, paridade_12x36_nova text,
  operacao text, motivo text,
  registro_anterior jsonb, registro_novo jsonb,
  created_at timestamptz, created_by uuid
) language sql stable security definer set search_path = public, pg_temp as $$
  select h.id, h.colaborador_convenia_id, h.alocacao_id,
    h.posto_servico_id_anterior, p_ant.nome,
    h.posto_servico_id_novo, p_novo.nome,
    h.horario_entrada_anterior, h.horario_entrada_novo,
    h.horario_saida_anterior, h.horario_saida_novo,
    h.intervalo_minutos_anterior, h.intervalo_minutos_novo,
    h.paridade_12x36_anterior, h.paridade_12x36_nova,
    h.operacao, h.motivo, h.registro_anterior, h.registro_novo,
    h.created_at, h.created_by
  from public.colaboradores_convenia_alocacoes_historico h
  left join public.postos_servico p_ant on p_ant.id = h.posto_servico_id_anterior
  left join public.postos_servico p_novo on p_novo.id = h.posto_servico_id_novo
  where h.colaborador_convenia_id = p_colaborador_convenia_id
  order by h.created_at desc;
$$;

-- 17. Função mensal alternar paridade
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
      intervalo_minutos_anterior, intervalo_minutos_novo, paridade_12x36_anterior, paridade_12x36_nova,
      operacao, motivo, registro_anterior, registro_novo, created_by
    ) values (
      r.colaborador_convenia_id, r.id, r.posto_servico_id, r.posto_servico_id,
      r.horario_entrada, r.horario_entrada, r.horario_saida, r.horario_saida,
      r.intervalo_minutos, r.intervalo_minutos, r.paridade_12x36, v_nova_paridade,
      'atualizacao_automatica_12x36',
      'Alternância automática mensal da escala 12x36 devido ao mês anterior ter quantidade ímpar de dias.',
      to_jsonb(r), v_registro_novo, null
    );
  end loop;
end;
$$;

-- 18. pg_cron
create extension if not exists pg_cron;
do $$
begin
  if exists (select 1 from cron.job where jobname = 'alternar-paridade-12x36-mensal') then
    perform cron.unschedule('alternar-paridade-12x36-mensal');
  end if;
end;
$$;
select cron.schedule('alternar-paridade-12x36-mensal', '5 0 1 * *', $$select public.fn_alternar_paridade_12x36_mensal();$$);

-- 19. Permissões
grant execute on function public.rpc_alocar_colaborador_convenia(uuid,uuid,time,time,integer,text,date,text,uuid) to authenticated;
grant execute on function public.rpc_movimentar_colaborador_convenia(uuid,uuid,time,time,integer,text,date,text,uuid) to authenticated;
grant execute on function public.rpc_alterar_horario_alocacao_convenia(uuid,time,time,integer,text,text,uuid) to authenticated;
grant execute on function public.rpc_desvincular_colaborador_convenia(uuid,date,text,uuid) to authenticated;
grant execute on function public.rpc_get_historico_alocacao_colaborador_convenia(uuid) to authenticated;
grant select on public.v_colaboradores_convenia_alocacao_atual to authenticated;
grant select on public.colaboradores_convenia_alocacoes to authenticated;
grant select on public.colaboradores_convenia_alocacoes_historico to authenticated;
