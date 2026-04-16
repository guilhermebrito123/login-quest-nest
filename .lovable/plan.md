

# Plano: Corrigir erro de CPF duplicado e garantir acesso de perfil_interno aos Chamados

## Diagnóstico

O erro "duplicate key value violates unique constraint colaboradores_cpf_key" ocorre porque o trigger `handle_usuario_role_transition` tenta inserir na tabela `colaboradores` com `cpf = ''` quando a role muda para `colaborador`. Se já existe outro registro com `cpf = ''`, o UNIQUE constraint bloqueia.

**Boa notícia:** Usuários com role `perfil_interno` (como admins) **já podem** criar, acompanhar, comentar e anexar chamados. As políticas RLS da tabela `chamados` já permitem isso. Não é necessário mudar ninguém para `colaborador`.

## O que será feito

### 1. Corrigir a constraint de CPF duplicado na tabela colaboradores
- Alterar a UNIQUE constraint de `cpf` para permitir valores vazios (`''`) duplicados usando um índice parcial:
  - Remover `UNIQUE (cpf)` existente
  - Criar `UNIQUE INDEX` apenas onde `cpf <> ''` (CPFs reais continuam únicos)
- Isso resolve o erro caso alguém precise de fato transicionar para `colaborador`

### 2. Nenhuma tabela nova necessária
- A tabela `chamados` já referencia `solicitante_id -> usuarios(id)`, que funciona para qualquer tipo de usuário
- As RLS policies já permitem que `perfil_interno` crie, visualize, atualize e comente chamados
- O trigger `validar_responsavel_chamado` já valida corretamente os responsáveis

### 3. Resumo de permissões existentes nos Chamados

| Ação | perfil_interno (admin, supervisor, etc.) | colaborador |
|------|------------------------------------------|-------------|
| Criar chamado | Sim | Sim |
| Visualizar | Sim | Não (apenas internos) |
| Atualizar | Sim (exceto cliente_view) | Não |
| Comentar | Sim | Não |
| Anexar | Sim | Não |
| Deletar | Apenas admin | Não |

## Detalhes técnicos

**Migration SQL:**
```sql
-- Remove a constraint UNIQUE simples do CPF
ALTER TABLE public.colaboradores DROP CONSTRAINT IF EXISTS colaboradores_cpf_key;

-- Cria índice único parcial que ignora CPFs vazios
CREATE UNIQUE INDEX colaboradores_cpf_unique_nonempty 
  ON public.colaboradores(cpf) 
  WHERE cpf <> '';
```

Apenas 1 migration será executada. Nenhum arquivo de código precisa ser alterado.

