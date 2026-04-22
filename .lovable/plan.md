

## Corrigir erros de criação de instância de checklist

Dois bugs estão impedindo a criação de instâncias. Ambos vivem nos triggers de banco que atualizei recentemente.

### Bug 1 — Coluna inexistente `ci.template_id`

Os triggers referenciam `ci.template_id`, mas o nome real da coluna em `checklist_instancias` é `checklist_template_id`. Toda inserção de instância dispara o snapshot e quebra com `column ci.template_id does not exist`.

**Funções a corrigir** (substituir `ci.template_id` → `ci.checklist_template_id`):
- `snapshot_template_tarefas_on_instancia`
- `auto_assign_checklist_tarefa_to_equipe`
- `sync_template_equipe_to_checklist_assignments`
- `sync_equipe_membros_to_checklist_assignments`

### Bug 2 — `assigned_by_user_id` NULL apesar da validação

O erro `null value in column "assigned_by_user_id"` continua aparecendo mesmo com a checagem de `auth.uid()`. Causas possíveis:

1. Outro trigger/função insere em `checklist_tarefa_responsaveis` sem preencher o campo.
2. O `auth.uid()` está vazio em contexto de `SECURITY DEFINER` chamado em cascata, e o erro do `IF` não chega a disparar porque o `INSERT` falha antes (improvável, mas possível se `_actor` for atribuído de outra fonte).

**Investigação + correção:**
- Auditar todas as funções/triggers que escrevem em `checklist_tarefa_responsaveis` e garantir que sempre preencham `assigned_by_user_id`.
- Reforçar `auto_assign_checklist_tarefa_to_equipe` para também usar `criado_por_user_id` da instância como fallback derivado (não anônimo): se `auth.uid()` vier nulo em algum cenário válido, usar o `criado_por_user_id` da própria instância (que é NOT NULL e já representa o "ator humano" responsável pela criação).

> Observação: na rodada anterior você optou por **bloquear** quando `auth.uid()` é nulo. Mantenho esse bloqueio, mas como o trigger roda em cascata logo após o INSERT da instância (mesma transação, mesmo usuário autenticado), na prática `auth.uid()` deve estar disponível. Se não estiver, o erro será claro (mensagem em PT) e não o genérico de NOT NULL.

### Arquivos / migrações

Uma única migração SQL recriando as 4 funções com:
- `ci.checklist_template_id` no lugar de `ci.template_id`.
- Validação explícita de `auth.uid()` mantida com mensagem clara.
- Garantia de que toda linha inserida em `checklist_tarefa_responsaveis` tenha `assigned_by_user_id` preenchido.

### Como você vai validar

1. Tentar criar uma instância pela tela → deve criar sem erro.
2. As tarefas do template aparecem em `checklist_instancia_tarefas`.
3. Cada tarefa tem responsáveis em `checklist_tarefa_responsaveis` (um por membro ativo da equipe do template), com `assigned_by_user_id` preenchido com o seu user id.

