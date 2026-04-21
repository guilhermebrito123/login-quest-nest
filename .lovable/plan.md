

## Corrigir recursão infinita em `planos_acao` RLS

### Diagnóstico
O erro `infinite recursion detected in policy for relation "planos_acao"` acontece porque:

- `planos_acao.SELECT` → subquery em `plano_acao_responsaveis`
- `plano_acao_responsaveis.SELECT` → subquery em `planos_acao`

Cada lado precisa avaliar a policy do outro, gerando loop. O INSERT do plano até é gravado, mas o Supabase tenta retornar a linha criada (`SELECT`), e aí a recursão estoura com 500. **É bug de backend (RLS), não de frontend.**

### Solução
Quebrar o ciclo movendo a lógica de "usuário é responsável pelo plano" para um **helper SECURITY DEFINER**, padrão já usado no projeto (igual `module_supervisor_has_cost_center`, `can_review_checklist` etc.).

### Migration

1. **Criar função helper**
   ```sql
   CREATE OR REPLACE FUNCTION public.is_action_plan_responsavel(_user_id uuid, _plano_id uuid)
   RETURNS boolean
   LANGUAGE sql
   STABLE
   SECURITY DEFINER
   SET search_path = public
   AS $$
     SELECT EXISTS (
       SELECT 1 FROM plano_acao_responsaveis
       WHERE plano_acao_id = _plano_id AND assigned_user_id = _user_id
     )
   $$;
   ```

2. **Reescrever `plano_select`** removendo a subquery direta em `plano_acao_responsaveis`:
   ```sql
   DROP POLICY plano_select ON planos_acao;
   CREATE POLICY plano_select ON planos_acao FOR SELECT
   USING (
     module_user_allowed(auth.uid()) AND EXISTS (
       SELECT 1 FROM checklist_instancias i
       WHERE i.id = planos_acao.checklist_instancia_id
         AND (
           module_is_admin(auth.uid())
           OR module_supervisor_has_cost_center(auth.uid(), i.cost_center_id)
           OR is_action_plan_responsavel(auth.uid(), planos_acao.id)
         )
     )
   );
   ```

A função `SECURITY DEFINER` bypassa RLS na consulta interna a `plano_acao_responsaveis`, eliminando o ciclo. As policies de `plano_acao_responsaveis` permanecem inalteradas.

### Validação pós-deploy
- Tentar criar plano de ação no fluxo da imagem → deve retornar 200/201.
- `SELECT * FROM planos_acao` como supervisor → sem 500.
- Supervisor responsável de plano fora do seu cost center continua enxergando o plano (cobertura mantida via helper).

### Observação
Não há mudança de frontend. Após a migration, o `console.error` em `CheckListActionPlansPage.tsx:189` deixa de ocorrer.

