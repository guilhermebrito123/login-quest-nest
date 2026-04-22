

# Criar funções de apoio para o módulo "Plano de ação"

## Objetivo
Disponibilizar duas funções no banco para que o frontend pare de listar "todos os perfis internos" como elegíveis e passe a respeitar as mesmas regras do RLS de `plano_acao_responsaveis`.

## O que será criado

### 1. `get_current_user_can_manage_plan(plano_id)` → boolean
Retorna `true` se o usuário logado pode atribuir/remover responsáveis de um plano específico (admin OU supervisor com o CC do plano vinculado).
**Uso no frontend:** esconder o botão "Atribuir" quando retorna `false`.

### 2. `get_action_plan_assignable_users(plano_id)` → tabela
Retorna a lista de usuários elegíveis a serem atribuídos como responsáveis daquele plano. Internamente:

- Resolve o CC via `planos_acao → checklist_instancias.cost_center_id`.
- Une duas listas:
  - **Colaboradores**: `usuarios.role='colaborador'` + `colaborador_profiles.ativo=true` + `cost_center_id` igual ao do plano → tipo `'colaborador'`.
  - **Perfis internos**: `internal_profiles.nivel_acesso <> 'cliente_view'`, sendo admin (sempre) OU vinculado ao CC via `internal_profile_cost_centers` → tipo `'interno'`.
- Devolve `(user_id, nome, email, tipo, nivel_acesso)` ordenado por tipo + nome.
- Só retorna dados se o chamador puder gerenciar o plano (chama a helper acima).

Ambas: `SECURITY DEFINER`, `search_path = public`, `GRANT EXECUTE` para `authenticated`.

## Como o frontend vai consumir

```ts
// 1. Saber se mostra o botão "Atribuir"
const { data: canManage } = await supabase
  .rpc('get_current_user_can_manage_plan', { _plano_acao_id: planoId });

// 2. Carregar opções do dropdown
const { data: assignables } = await supabase
  .rpc('get_action_plan_assignable_users', { _plano_acao_id: planoId });
// assignables: [{ user_id, nome, email, tipo: 'colaborador'|'interno', nivel_acesso }]
```

## Observações
- Nenhuma alteração nas políticas RLS existentes — apenas funções novas.
- Nenhum dado é alterado, apenas leitura.
- Se algum dia uma nova regra de elegibilidade entrar (ex.: bloquear gestores), basta editar a função; o frontend não precisa mudar.

