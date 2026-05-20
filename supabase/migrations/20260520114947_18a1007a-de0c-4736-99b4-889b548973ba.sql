
-- 1) Reagendar o cron para 00:10 BRT (= 03:10 UTC)
do $$
begin
  if exists (select 1 from cron.job where jobname = 'sincronizar-status-alocacoes-convenia') then
    perform cron.unschedule('sincronizar-status-alocacoes-convenia');
  end if;
end$$;

select cron.schedule(
  'sincronizar-status-alocacoes-convenia',
  '10 3 * * *',
  $$select public.fn_sincronizar_status_alocacoes_convenia();$$
);

-- 2) Wrapper RPC com checagem de papel interno
create or replace function public.rpc_sincronizar_alocacoes_convenia()
returns void
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
begin
  if public.current_internal_access_level() is null then
    raise exception 'Acesso negado: somente perfis internos podem sincronizar alocações Convenia.'
      using errcode = '42501';
  end if;

  perform public.fn_sincronizar_status_alocacoes_convenia();
end;
$$;

-- 3) Permissões
grant execute on function public.rpc_sincronizar_alocacoes_convenia() to authenticated;
grant execute on function public.fn_sincronizar_status_alocacoes_convenia() to authenticated;

-- 4) Rodar a sincronização agora para corrigir o estado atual
select public.fn_sincronizar_status_alocacoes_convenia();
