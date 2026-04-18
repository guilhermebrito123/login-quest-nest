begin;

-- =========================================================
-- 1) TABELA DE VINCULO ENTRE USUARIO INTERNO E COST_CENTER
-- =========================================================

create table if not exists public.internal_profile_cost_centers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.usuarios(id) on delete cascade,
  cost_center_id uuid not null references public.cost_center(id) on delete cascade,
  created_at timestamptz not null default now(),
  created_by uuid not null references public.usuarios(id),
  constraint uq_internal_profile_cost_centers unique (user_id, cost_center_id)
);

create index if not exists idx_internal_profile_cost_centers_user_id
  on public.internal_profile_cost_centers(user_id);

create index if not exists idx_internal_profile_cost_centers_cost_center_id
  on public.internal_profile_cost_centers(cost_center_id);

-- =========================================================
-- 2) VALIDAR QUE SOMENTE PERFIL_INTERNO OPERACIONAL VINCULA
-- =========================================================

create or replace function public.validate_internal_profile_cost_center()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_role public.user_type;
  v_nivel public.internal_access_level;
begin
  select u.role, ip.nivel_acesso
    into v_role, v_nivel
  from public.usuarios u
  left join public.internal_profiles ip on ip.user_id = u.id
  where u.id = new.user_id;

  if v_role is null then
    raise exception 'Usuário % não encontrado', new.user_id;
  end if;

  if v_role <> 'perfil_interno' then
    raise exception 'Somente usuários com role perfil_interno podem possuir cost_center vinculado nesta tabela';
  end if;

  if v_nivel is null then
    raise exception 'Usuário interno % sem internal_profile válido', new.user_id;
  end if;

  if v_nivel in ('admin', 'cliente_view') then
    raise exception 'Usuários com nível % não devem possuir vínculo nesta tabela', v_nivel;
  end if;

  if v_nivel not in (
    'gestor_operacoes','supervisor','analista_centro_controle','tecnico',
    'assistente_operacoes','assistente_financeiro','gestor_financeiro'
  ) then
    raise exception 'Nível de acesso % não permitido para vínculo operacional', v_nivel;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validate_internal_profile_cost_center
  on public.internal_profile_cost_centers;

create trigger trg_validate_internal_profile_cost_center
before insert or update on public.internal_profile_cost_centers
for each row execute function public.validate_internal_profile_cost_center();

-- =========================================================
-- 3) FUNCOES DE ACESSO
-- =========================================================

create or replace function public.internal_user_is_admin(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.usuarios u
    join public.internal_profiles ip on ip.user_id = u.id
    where u.id = p_user_id
      and u.role = 'perfil_interno'
      and ip.nivel_acesso = 'admin'
  );
$$;

create or replace function public.internal_user_has_cost_center_access(
  p_user_id uuid,
  p_cost_center_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select (
    public.internal_user_is_admin(p_user_id)
    or exists (
      select 1
      from public.usuarios u
      join public.internal_profiles ip on ip.user_id = u.id
      join public.internal_profile_cost_centers ipcc on ipcc.user_id = u.id
      where u.id = p_user_id
        and u.role = 'perfil_interno'
        and ip.nivel_acesso in (
          'gestor_operacoes','supervisor','analista_centro_controle','tecnico',
          'assistente_operacoes','assistente_financeiro','gestor_financeiro'
        )
        and ipcc.cost_center_id = p_cost_center_id
    )
  );
$$;

create or replace function public.internal_user_can_access_local(
  p_user_id uuid,
  p_local_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.cost_center_locais l
    where l.id = p_local_id
      and l.ativo = true
      and public.internal_user_has_cost_center_access(p_user_id, l.cost_center_id)
  );
$$;

create or replace function public.internal_user_can_access_chamado(
  p_user_id uuid,
  p_chamado_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.chamados c
    join public.cost_center_locais l on l.id = c.local_id
    where c.id = p_chamado_id
      and public.internal_user_has_cost_center_access(p_user_id, l.cost_center_id)
  );
$$;

create or replace function public.internal_user_can_use_local_for_chamado(
  p_user_id uuid,
  p_local_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.internal_user_can_access_local(p_user_id, p_local_id);
$$;

-- =========================================================
-- 4) HELPER: usuario eh colaborador?
-- =========================================================
create or replace function public.is_colaborador_user(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.usuarios u
    where u.id = p_user_id and u.role = 'colaborador'
  );
$$;

-- =========================================================
-- 5) TRIGGER DE CONSISTENCIA EM CHAMADOS (apenas perfil_interno)
-- =========================================================

create or replace function public.validate_internal_user_chamado_scope()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_role public.user_type;
  v_nivel public.internal_access_level;
  v_local_cost_center_id uuid;
begin
  select u.role, ip.nivel_acesso
    into v_role, v_nivel
  from public.usuarios u
  left join public.internal_profiles ip on ip.user_id = u.id
  where u.id = new.solicitante_id;

  -- Colaboradores e demais roles seguem regras antigas (nao validamos aqui)
  if v_role is distinct from 'perfil_interno' then
    return new;
  end if;

  if v_nivel = 'cliente_view' then
    raise exception 'Usuário cliente_view não pode operar chamados por este escopo';
  end if;

  if v_nivel = 'admin' then
    return new;
  end if;

  select l.cost_center_id into v_local_cost_center_id
  from public.cost_center_locais l
  where l.id = new.local_id and l.ativo = true;

  if v_local_cost_center_id is null then
    raise exception 'Local inválido ou inativo';
  end if;

  if not public.internal_user_has_cost_center_access(new.solicitante_id, v_local_cost_center_id) then
    raise exception 'Usuário interno não possui acesso ao cost_center deste local';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validate_internal_user_chamado_scope on public.chamados;

create trigger trg_validate_internal_user_chamado_scope
before insert or update on public.chamados
for each row execute function public.validate_internal_user_chamado_scope();

-- =========================================================
-- 6) RLS: internal_profile_cost_centers (admin only)
-- =========================================================

alter table public.internal_profile_cost_centers enable row level security;

drop policy if exists "ipcc_select_admin" on public.internal_profile_cost_centers;
create policy "ipcc_select_admin"
on public.internal_profile_cost_centers for select
using (public.internal_user_is_admin(auth.uid()));

drop policy if exists "ipcc_insert_admin" on public.internal_profile_cost_centers;
create policy "ipcc_insert_admin"
on public.internal_profile_cost_centers for insert
with check (public.internal_user_is_admin(auth.uid()));

drop policy if exists "ipcc_update_admin" on public.internal_profile_cost_centers;
create policy "ipcc_update_admin"
on public.internal_profile_cost_centers for update
using (public.internal_user_is_admin(auth.uid()))
with check (public.internal_user_is_admin(auth.uid()));

drop policy if exists "ipcc_delete_admin" on public.internal_profile_cost_centers;
create policy "ipcc_delete_admin"
on public.internal_profile_cost_centers for delete
using (public.internal_user_is_admin(auth.uid()));

-- =========================================================
-- 7) RLS: chamados
--    - admin: tudo
--    - perfil_interno operacional: por vinculo de cost_center
--    - colaborador: proprios chamados (mantem regra antiga)
-- =========================================================

drop policy if exists chamados_select on public.chamados;
drop policy if exists chamados_insert on public.chamados;
drop policy if exists chamados_update on public.chamados;
drop policy if exists chamados_delete on public.chamados;

create policy chamados_select
on public.chamados for select
using (
  public.internal_user_is_admin(auth.uid())
  or public.internal_user_can_access_chamado(auth.uid(), id)
  or (
    solicitante_id = auth.uid()
    and public.is_colaborador_user(auth.uid())
  )
);

create policy chamados_insert
on public.chamados for insert
with check (
  public.internal_user_is_admin(auth.uid())
  or (
    -- perfil_interno operacional criando para si
    solicitante_id = auth.uid()
    and public.internal_user_can_use_local_for_chamado(auth.uid(), local_id)
  )
  or (
    -- colaborador criando para si no proprio cost_center (regra antiga)
    solicitante_id = auth.uid()
    and exists (
      select 1
      from public.usuarios u
      join public.colaborador_profiles cp on cp.user_id = u.id
      join public.cost_center_locais l on l.cost_center_id = cp.cost_center_id
      where u.id = auth.uid()
        and u.role = 'colaborador'
        and cp.ativo = true
        and l.id = chamados.local_id
    )
  )
);

create policy chamados_update
on public.chamados for update
using (
  public.internal_user_is_admin(auth.uid())
  or public.internal_user_can_access_chamado(auth.uid(), id)
  or (
    solicitante_id = auth.uid()
    and public.is_colaborador_user(auth.uid())
  )
)
with check (
  public.internal_user_is_admin(auth.uid())
  or public.internal_user_can_use_local_for_chamado(auth.uid(), local_id)
  or (
    solicitante_id = auth.uid()
    and public.is_colaborador_user(auth.uid())
  )
);

create policy chamados_delete
on public.chamados for delete
using (
  public.internal_user_is_admin(auth.uid())
  or public.internal_user_can_access_chamado(auth.uid(), id)
  or (
    solicitante_id = auth.uid()
    and public.is_colaborador_user(auth.uid())
  )
);

-- =========================================================
-- 8) RLS: chamado_interacoes
-- =========================================================

drop policy if exists interacoes_select on public.chamado_interacoes;
drop policy if exists interacoes_insert on public.chamado_interacoes;
drop policy if exists interacoes_delete on public.chamado_interacoes;

create policy interacoes_select
on public.chamado_interacoes for select
using (
  public.internal_user_is_admin(auth.uid())
  or public.internal_user_can_access_chamado(auth.uid(), chamado_id)
  or (
    interno = false
    and exists (
      select 1 from public.chamados c
      where c.id = chamado_interacoes.chamado_id
        and c.solicitante_id = auth.uid()
    )
  )
);

create policy interacoes_insert
on public.chamado_interacoes for insert
with check (
  autor_id = auth.uid()
  and (
    public.internal_user_is_admin(auth.uid())
    or public.internal_user_can_access_chamado(auth.uid(), chamado_id)
    or exists (
      select 1 from public.chamados c
      where c.id = chamado_interacoes.chamado_id
        and c.solicitante_id = auth.uid()
        and public.is_colaborador_user(auth.uid())
    )
  )
);

create policy interacoes_delete
on public.chamado_interacoes for delete
using (
  public.internal_user_is_admin(auth.uid())
  or public.internal_user_can_access_chamado(auth.uid(), chamado_id)
  or (
    autor_id = auth.uid()
    and public.is_colaborador_user(auth.uid())
  )
);

-- =========================================================
-- 9) RLS: chamado_anexos
-- =========================================================

drop policy if exists anexos_select on public.chamado_anexos;
drop policy if exists anexos_insert on public.chamado_anexos;
drop policy if exists anexos_delete on public.chamado_anexos;

create policy anexos_select
on public.chamado_anexos for select
using (
  public.internal_user_is_admin(auth.uid())
  or public.internal_user_can_access_chamado(auth.uid(), chamado_id)
  or exists (
    select 1 from public.chamados c
    where c.id = chamado_anexos.chamado_id
      and c.solicitante_id = auth.uid()
  )
);

create policy anexos_insert
on public.chamado_anexos for insert
with check (
  uploaded_by = auth.uid()
  and (
    public.internal_user_is_admin(auth.uid())
    or public.internal_user_can_access_chamado(auth.uid(), chamado_id)
    or exists (
      select 1 from public.chamados c
      where c.id = chamado_anexos.chamado_id
        and c.solicitante_id = auth.uid()
        and public.is_colaborador_user(auth.uid())
    )
  )
);

create policy anexos_delete
on public.chamado_anexos for delete
using (
  public.internal_user_is_admin(auth.uid())
  or public.internal_user_can_access_chamado(auth.uid(), chamado_id)
  or (
    uploaded_by = auth.uid()
    and public.is_colaborador_user(auth.uid())
  )
);

-- =========================================================
-- 10) RLS: chamado_historico
-- =========================================================

drop policy if exists historico_select on public.chamado_historico;

create policy historico_select
on public.chamado_historico for select
using (
  public.internal_user_is_admin(auth.uid())
  or public.internal_user_can_access_chamado(auth.uid(), chamado_id)
  or exists (
    select 1 from public.chamados c
    where c.id = chamado_historico.chamado_id
      and c.solicitante_id = auth.uid()
  )
);

commit;