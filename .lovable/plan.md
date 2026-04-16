# Plano: Estrutura de colaborador_profiles + restrição de chamados por cost_center

## Objetivo

Permitir que admins promovam usuários para `colaborador` vinculando-os a um `cost_center`, e garantir que colaboradores só possam abrir chamados em locais (`cost_center_locais`) pertencentes ao seu próprio `cost_center`.

## O que será feito

### 1. Criar tabela `colaborador_profiles`

Estrutura 1:1 com `usuarios`, espelhando o padrão de `internal_profiles`:

```sql
create table public.colaborador_profiles (
  user_id uuid primary key references public.usuarios(id) on delete cascade,
  cost_center_id uuid not null references public.cost_center(id),
  ativo boolean not null default true,
  observacoes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid not null references public.usuarios(id),
  updated_by uuid references public.usuarios(id)
);
```

Inclui:
- Índice em `cost_center_id` para queries de validação
- Trigger de `updated_at` automático
- RLS habilitado

### 2. RLS policies em `colaborador_profiles`

- **SELECT**: usuários internos (`is_internal_user()`) e o próprio colaborador (`user_id = auth.uid()`)
- **INSERT/UPDATE/DELETE**: apenas admins (`has_role(auth.uid(), 'admin')`)

### 3. Trigger de validação `validar_colaborador_profile`

Garante que só é possível criar/atualizar `colaborador_profiles` se `usuarios.role = 'colaborador'`.

### 4. Função RPC `definir_usuario_como_colaborador`

Função transacional que:
- Valida se o executor é admin interno
- Altera `usuarios.role = 'colaborador'`
- Cria ou atualiza `colaborador_profiles` com o `cost_center_id` informado
- Tudo em uma transação atômica

Assinatura:
```sql
definir_usuario_como_colaborador(
  p_user_id uuid,
  p_cost_center_id uuid
) returns void
```

(O `admin_user_id` vem de `auth.uid()` automaticamente.)

### 5. Trigger `validar_abertura_chamado` em `chamados`

Antes de inserir um chamado:
- Se `solicitante_id` tem `role = 'colaborador'`, valida:
  - Existe `colaborador_profiles` ativo para ele
  - O `cost_center_id` do colaborador é igual ao `cost_center_id` do `local_id` escolhido
- Se for `perfil_interno`, libera (sem restrição de cost_center)

### 6. Ajustar trigger existente `handle_usuario_role_transition`

Atualmente, ao mudar role para `colaborador`, o trigger cria automaticamente registro em `colaboradores` com `cpf = ''`. Isso vai ser **desativado para essa transição específica**, pois agora o vínculo correto é via `colaborador_profiles` (não em `colaboradores`, que é uma tabela legada de RH/escalas).

A nova regra: transicionar para `colaborador` agora exige usar a função `definir_usuario_como_colaborador` (que cria `colaborador_profiles`).

### 7. Atualizar UI de UserManagement

Quando o admin escolher a role `colaborador` no Select:
- Abre um dialog pedindo para selecionar o `cost_center`
- Ao confirmar, chama a RPC `definir_usuario_como_colaborador`
- Mostra erro se faltou escolher cost_center

## Resumo das permissões finais nos chamados

| Ação | perfil_interno | colaborador (com cost_center vinculado) |
|------|----------------|------------------------------------------|
| Criar chamado | Em qualquer local | **Apenas em locais do seu próprio cost_center** |
| Visualizar | Sim | Não (sem mudança) |
| Atualizar/Comentar/Anexar | Sim | Não (sem mudança) |

## Arquivos afetados

- **1 migration SQL** (nova tabela, função, triggers, policies, ajuste de trigger existente)
- **src/pages/UserManagement.tsx** — adiciona seletor de cost_center quando role = colaborador
