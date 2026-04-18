begin;

drop policy if exists "Internos operacionais podem ler usuarios" on public.usuarios;

create policy "Internos operacionais podem ler usuarios"
on public.usuarios
for select
to authenticated
using (
  public.current_internal_access_level() is not null
  and public.current_internal_access_level() <> 'cliente_view'::public.internal_access_level
);

commit;