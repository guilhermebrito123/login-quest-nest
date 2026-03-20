
-- =========================================================
-- TABELA NOVA DE NOTIFICAÇÕES DE DIÁRIAS
-- =========================================================

create table if not exists public.diarias_notificacoes (
  id uuid primary key default gen_random_uuid(),
  diaria_id bigint not null references public.diarias_temporarias(id) on delete cascade,
  user_id uuid not null references public.usuarios(id) on delete cascade,

  campo text not null,
  evento text not null,
  valor_antigo text null,
  valor_novo text null,

  titulo text not null,
  mensagem text not null,
  lida boolean not null default false,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_diarias_notificacoes_user_id
  on public.diarias_notificacoes(user_id);

create index if not exists idx_diarias_notificacoes_diaria_id
  on public.diarias_notificacoes(diaria_id);

create index if not exists idx_diarias_notificacoes_lida
  on public.diarias_notificacoes(lida);

create index if not exists idx_diarias_notificacoes_created_at
  on public.diarias_notificacoes(created_at desc);

-- RLS
alter table public.diarias_notificacoes enable row level security;

create policy "Usuarios podem ler suas notificacoes"
on public.diarias_notificacoes for select
to authenticated
using (user_id = auth.uid());

create policy "Usuarios podem atualizar suas notificacoes"
on public.diarias_notificacoes for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Sistema pode inserir notificacoes"
on public.diarias_notificacoes for insert
to authenticated
with check (true);

-- =========================================================
-- UPDATED_AT AUTOMÁTICO
-- =========================================================

create or replace function public.set_diarias_notificacoes_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_set_diarias_notificacoes_updated_at
on public.diarias_notificacoes;

create trigger trg_set_diarias_notificacoes_updated_at
before update on public.diarias_notificacoes
for each row
execute function public.set_diarias_notificacoes_updated_at();

-- =========================================================
-- FUNÇÃO AUXILIAR PARA OBTER OS ENVOLVIDOS
-- =========================================================

create or replace function public.obter_usuarios_envolvidos_diaria(
  p_old public.diarias_temporarias,
  p_new public.diarias_temporarias
)
returns table(user_id uuid)
language sql
as $$
  select distinct x.user_id
  from unnest(array[
    p_old.aprovada_por,
    p_new.aprovada_por,
    p_old.aprovado_para_pgto_por,
    p_new.aprovado_para_pgto_por,
    p_old.cancelada_por,
    p_new.cancelada_por,
    p_old.confirmada_por,
    p_new.confirmada_por,
    p_old.criado_por,
    p_new.criado_por,
    p_old.lancada_por,
    p_new.lancada_por,
    p_old.ok_pagamento_por,
    p_new.ok_pagamento_por,
    p_old.paga_por,
    p_new.paga_por,
    p_old.reprovada_por,
    p_new.reprovada_por
  ]) as x(user_id)
  where x.user_id is not null;
$$;

-- =========================================================
-- FUNÇÃO AUXILIAR PARA CRIAR NOTIFICAÇÃO
-- =========================================================

create or replace function public.criar_notificacao_diaria(
  p_diaria_id bigint,
  p_user_id uuid,
  p_campo text,
  p_evento text,
  p_valor_antigo text,
  p_valor_novo text,
  p_titulo text,
  p_mensagem text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.diarias_notificacoes (
    diaria_id, user_id, campo, evento,
    valor_antigo, valor_novo, titulo, mensagem
  )
  values (
    p_diaria_id, p_user_id, p_campo, p_evento,
    p_valor_antigo, p_valor_novo, p_titulo, p_mensagem
  );
end;
$$;

-- =========================================================
-- FUNÇÃO PRINCIPAL DE NOTIFICAÇÃO
-- =========================================================

create or replace function public.notificar_alteracoes_diaria()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_titulo text;
  v_mensagem text;
begin
  if tg_op <> 'UPDATE' then
    return new;
  end if;

  -- motivo_cancelamento
  if old.motivo_cancelamento is distinct from new.motivo_cancelamento then
    for v_user_id in
      select user_id from public.obter_usuarios_envolvidos_diaria(old, new)
    loop
      v_titulo := 'Motivo de cancelamento atualizado';
      v_mensagem := 'A diária #' || new.id ||
                    ' teve o motivo de cancelamento alterado para: ' ||
                    coalesce(new.motivo_cancelamento, 'null');
      perform public.criar_notificacao_diaria(
        new.id, v_user_id, 'motivo_cancelamento', 'campo_alterado',
        old.motivo_cancelamento, new.motivo_cancelamento, v_titulo, v_mensagem
      );
    end loop;
  end if;

  -- motivo_reprovacao
  if old.motivo_reprovacao is distinct from new.motivo_reprovacao then
    for v_user_id in
      select user_id from public.obter_usuarios_envolvidos_diaria(old, new)
    loop
      v_titulo := 'Motivo de reprovação atualizado';
      v_mensagem := 'A diária #' || new.id ||
                    ' teve o motivo de reprovação alterado para: ' ||
                    coalesce(new.motivo_reprovacao::text, 'null');
      perform public.criar_notificacao_diaria(
        new.id, v_user_id, 'motivo_reprovacao', 'campo_alterado',
        old.motivo_reprovacao::text, new.motivo_reprovacao::text, v_titulo, v_mensagem
      );
    end loop;
  end if;

  -- motivo_reprovacao_observacao
  if old.motivo_reprovacao_observacao is distinct from new.motivo_reprovacao_observacao then
    for v_user_id in
      select user_id from public.obter_usuarios_envolvidos_diaria(old, new)
    loop
      v_titulo := 'Observação de reprovação atualizada';
      v_mensagem := 'A diária #' || new.id ||
                    ' teve a observação de reprovação alterada para: ' ||
                    coalesce(new.motivo_reprovacao_observacao, 'null');
      perform public.criar_notificacao_diaria(
        new.id, v_user_id, 'motivo_reprovacao_observacao', 'campo_alterado',
        old.motivo_reprovacao_observacao, new.motivo_reprovacao_observacao, v_titulo, v_mensagem
      );
    end loop;
  end if;

  -- observacao_lancamento
  if old.observacao_lancamento is distinct from new.observacao_lancamento then
    for v_user_id in
      select user_id from public.obter_usuarios_envolvidos_diaria(old, new)
    loop
      v_titulo := 'Observação de lançamento atualizada';
      v_mensagem := 'A diária #' || new.id ||
                    ' teve a observação de lançamento alterada para: ' ||
                    coalesce(new.observacao_lancamento, 'null');
      perform public.criar_notificacao_diaria(
        new.id, v_user_id, 'observacao_lancamento', 'campo_alterado',
        old.observacao_lancamento, new.observacao_lancamento, v_titulo, v_mensagem
      );
    end loop;
  end if;

  -- observacao_pagamento
  if old.observacao_pagamento is distinct from new.observacao_pagamento then
    for v_user_id in
      select user_id from public.obter_usuarios_envolvidos_diaria(old, new)
    loop
      v_titulo := 'Observação de pagamento atualizada';
      v_mensagem := 'A diária #' || new.id ||
                    ' teve a observação de pagamento alterada para: ' ||
                    coalesce(array_to_string(new.observacao_pagamento, ', '), 'null');
      perform public.criar_notificacao_diaria(
        new.id, v_user_id, 'observacao_pagamento', 'campo_alterado',
        coalesce(array_to_string(old.observacao_pagamento, ', '), null),
        coalesce(array_to_string(new.observacao_pagamento, ', '), null),
        v_titulo, v_mensagem
      );
    end loop;
  end if;

  -- outros_motivos_reprovacao_pagamento
  if old.outros_motivos_reprovacao_pagamento is distinct from new.outros_motivos_reprovacao_pagamento then
    for v_user_id in
      select user_id from public.obter_usuarios_envolvidos_diaria(old, new)
    loop
      v_titulo := 'Motivos adicionais de reprovação de pagamento atualizados';
      v_mensagem := 'A diária #' || new.id ||
                    ' teve os motivos adicionais de reprovação de pagamento alterados para: ' ||
                    coalesce(new.outros_motivos_reprovacao_pagamento, 'null');
      perform public.criar_notificacao_diaria(
        new.id, v_user_id, 'outros_motivos_reprovacao_pagamento', 'campo_alterado',
        old.outros_motivos_reprovacao_pagamento, new.outros_motivos_reprovacao_pagamento,
        v_titulo, v_mensagem
      );
    end loop;
  end if;

  -- status -> Cancelada
  if old.status is distinct from new.status and new.status = 'Cancelada' then
    for v_user_id in
      select user_id from public.obter_usuarios_envolvidos_diaria(old, new)
    loop
      v_titulo := 'Diária cancelada';
      v_mensagem := 'A diária #' || new.id ||
                    ' teve o status alterado para Cancelada.';
      perform public.criar_notificacao_diaria(
        new.id, v_user_id, 'status', 'status_cancelada',
        old.status::text, new.status::text, v_titulo, v_mensagem
      );
    end loop;
  end if;

  -- status -> Reprovada
  if old.status is distinct from new.status and new.status = 'Reprovada' then
    for v_user_id in
      select user_id from public.obter_usuarios_envolvidos_diaria(old, new)
    loop
      v_titulo := 'Diária reprovada';
      v_mensagem := 'A diária #' || new.id ||
                    ' teve o status alterado para Reprovada.';
      perform public.criar_notificacao_diaria(
        new.id, v_user_id, 'status', 'status_reprovada',
        old.status::text, new.status::text, v_titulo, v_mensagem
      );
    end loop;
  end if;

  -- ok_pagamento -> false
  if old.ok_pagamento is distinct from new.ok_pagamento and new.ok_pagamento = false then
    for v_user_id in
      select user_id from public.obter_usuarios_envolvidos_diaria(old, new)
    loop
      v_titulo := 'Pagamento da diária marcado como não OK';
      v_mensagem := 'A diária #' || new.id ||
                    ' teve a validação de pagamento alterada para false.';
      perform public.criar_notificacao_diaria(
        new.id, v_user_id, 'ok_pagamento', 'pagamento_nao_ok',
        coalesce(old.ok_pagamento::text, 'null'),
        coalesce(new.ok_pagamento::text, 'null'),
        v_titulo, v_mensagem
      );
    end loop;
  end if;

  return new;
end;
$$;

-- =========================================================
-- TRIGGER NA TABELA DIARIAS_TEMPORARIAS
-- =========================================================

drop trigger if exists trg_notificar_alteracoes_diaria
on public.diarias_temporarias;

create trigger trg_notificar_alteracoes_diaria
after update on public.diarias_temporarias
for each row
execute function public.notificar_alteracoes_diaria();
