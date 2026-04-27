# Soft-delete de usuários com bloqueio total de CRUD

## Objetivo

Permitir "desativar" um usuário sem apagar fisicamente o registro em `usuarios`. O usuário desativado:

- Não pode mais fazer login.
- Se já estiver logado, **não consegue executar nenhuma operação** de SELECT/INSERT/UPDATE/DELETE em qualquer tabela do sistema.
- Tem todo o histórico preservado em todas as tabelas que o referenciam (diárias, chamados, checklists, planos de ação, horas extras, vagas, logs etc.).
- Pode ser reativado depois, restaurando o acesso integralmente.

Essa abordagem evita o caos de FKs com `RESTRICT`/`NO ACTION` que hoje bloqueiam o `DELETE` físico (vide análise anterior do `diarias_temporarias.criado_por`, `chamados`, `checklists`, `vagas_temp` etc.).

---

## 1. Mudanças de schema (migration)

Adicionar colunas de soft-delete em `public.usuarios`:

```text
ativo            boolean      NOT NULL DEFAULT true
deactivated_at   timestamptz  NULL
deactivated_by   uuid         NULL  -> FK usuarios.id ON DELETE SET NULL
deactivation_reason text       NULL
```

Índice parcial para acelerar lookups dos ativos:
`CREATE INDEX idx_usuarios_ativo ON public.usuarios(id) WHERE ativo = true;`

Nada é apagado, nenhuma FK existente muda. A regra "histórico preservado" sai de graça.

---

## 2. Função-guard central (SECURITY DEFINER)

Criar uma função canônica usada por todas as policies:

```text
public.current_user_is_active() RETURNS boolean
  LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public
  AS $$
    SELECT COALESCE(
      (SELECT ativo FROM public.usuarios WHERE id = auth.uid()),
      false  -- se não existe registro, considera inativo
    );
  $$;
```

`SECURITY DEFINER` evita recursão de RLS ao consultar `usuarios` dentro das próprias policies de `usuarios`.

Também atualizar `current_internal_access_level()` para retornar NULL quando o usuário estiver inativo (defesa em profundidade).

---

## 3. Bloqueio universal de CRUD via RLS

Estratégia: **adicionar uma policy RESTRICTIVE** em cada tabela do schema `public` que exige `current_user_is_active() = true`.

Postgres combina policies PERMISSIVE com OR e policies RESTRICTIVE com AND. Isso significa que adicionar uma única policy RESTRICTIVE por tabela **não quebra** as policies existentes — ela apenas agrega a condição "usuário precisa estar ativo" a todas as operações já permitidas.

Para cada tabela em `public` (são ~254 policies hoje em várias tabelas) a migration roda dinamicamente:

```text
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT c.relname
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname='public' AND c.relkind='r'
      AND c.relname NOT IN ('usuarios')  -- tratada à parte
  LOOP
    EXECUTE format($f$
      DROP POLICY IF EXISTS "require_active_user" ON public.%I;
      CREATE POLICY "require_active_user" ON public.%I
        AS RESTRICTIVE
        FOR ALL
        TO authenticated
        USING (public.current_user_is_active())
        WITH CHECK (public.current_user_is_active());
    $f$, r.relname, r.relname);
  END LOOP;
END $$;
```

Tabelas que **devem ser excluídas** desse loop (acesso público/anônimo legítimo):
- `candidatos` e `candidatos_anexos` (registro anônimo de candidatos — ver memória `candidatos-anonymous-registration`).
- Qualquer tabela cujas policies hoje usem `TO anon` para um caso de negócio público. Vou auditar antes da execução.

Para a própria `public.usuarios` a policy RESTRICTIVE é mais cuidadosa: aplica em INSERT/UPDATE/DELETE, mas mantém SELECT permitido para o próprio usuário ler `ativo=false` (assim o frontend pode mostrar a tela "Conta desativada").

---

## 4. Bloqueio no plano de Auth

RLS impede DML, mas o usuário ainda conseguiria abrir sessão. Reforçar com:

1. **Trigger BEFORE UPDATE em `usuarios`**: quando `ativo` passa de `true → false`, chamar uma rotina que invalida sessões.
2. **Edge Function `deactivate-user`** (chamada pelo frontend admin) que faz, em sequência:
   - `UPDATE usuarios SET ativo=false, deactivated_at=now(), deactivated_by=auth.uid(), deactivation_reason=$1 WHERE id=$2`
   - `supabaseAdmin.auth.admin.updateUserById(id, { ban_duration: '876000h' })` (banimento ~100 anos = login bloqueado).
   - `supabaseAdmin.auth.admin.signOut(id)` para revogar tokens ativos.
3. **Edge Function `reactivate-user`**: faz o inverso (ativo=true, `ban_duration: 'none'`).

Ambas as functions exigem `current_internal_access_level() IN ('admin','gestor_operacional')` (ou o nível que você definir) — verifico no código atual qual é o padrão.

---

## 5. UI / Frontend

Mudanças mínimas em `src/pages/UserManagement.tsx`:

- Substituir o botão "Excluir usuário" por **"Desativar usuário"** (com modal pedindo motivo).
- Adicionar botão **"Reativar"** em usuários inativos.
- Filtros: tabs `Ativos | Inativos | Todos`.
- Badge visual "Inativo" no card.
- As listas que mostram pessoas (responsáveis, aprovadores, etc.) continuam mostrando o nome do usuário inativo no histórico (porque o registro existe), mas os selects de **atribuição nova** filtram por `ativo=true`.

Adicionar tela/aviso global: se o usuário logado tiver `ativo=false`, exibir página "Sua conta foi desativada" e forçar logout.

---

## 6. Detalhes técnicos importantes

- **Não há recursão de RLS** porque `current_user_is_active()` é `SECURITY DEFINER` com `search_path=public`.
- **Performance**: a função é `STABLE`, o Postgres cacheia o resultado dentro da mesma query. Custo ≈ 1 lookup por statement.
- **Bypass para serviços**: edge functions que usam `service_role` continuam ignorando RLS normalmente — sincronizações Convenia/Tiquetaque/cron jobs não são afetadas.
- **Bypass `app.rpc_call`**: RPCs internas que já usam o padrão `app.rpc_call` (ver memória `database-trigger-bypass-pattern`) seguem funcionando porque rodam como `SECURITY DEFINER`.
- **Candidatos anônimos**: tabelas `candidatos*` ficam fora do loop para preservar o registro público.
- **Banimento Auth**: `ban_duration` no Supabase Auth é o mecanismo oficial recomendado para bloquear login sem apagar o `auth.users`.
- **Reversibilidade**: reativar restaura tudo automaticamente — nenhum registro foi destruído.

---

## 7. Resumo das entregas

1. Migration: colunas + índice + função `current_user_is_active()` + atualização `current_internal_access_level()` + policies RESTRICTIVE em todas as tabelas `public` (exceto whitelist).
2. Edge Functions: `deactivate-user` e `reactivate-user`.
3. Frontend: ajustes em `UserManagement.tsx` (botões, modal de motivo, filtros, badge) + guard global de "conta desativada".
4. Memória: registrar `mem://features/user-soft-delete` documentando o padrão.

Após sua aprovação, executo na ordem: migration → edge functions → frontend → registro de memória.
