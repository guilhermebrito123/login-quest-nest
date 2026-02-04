
# Plano: Adicionar atributo `reserva_tecnica` na tabela `diaristas`

## Objetivo
Adicionar um novo campo booleano opcional chamado `reserva_tecnica` na tabela `diaristas`, definindo o valor como `false` para todos os registros existentes.

## Etapas de Implementação

### 1. Migração do Banco de Dados

Criar uma migração SQL que:
- Adiciona a coluna `reserva_tecnica` do tipo `boolean` com valor padrão `false`
- Atualiza todos os registros existentes para `false`

```sql
-- Adicionar coluna reserva_tecnica à tabela diaristas
ALTER TABLE public.diaristas 
ADD COLUMN IF NOT EXISTS reserva_tecnica boolean DEFAULT false;

-- Atualizar todos os registros existentes para false
UPDATE public.diaristas SET reserva_tecnica = false WHERE reserva_tecnica IS NULL;
```

### 2. Atualização do Formulário (DiaristaForm.tsx)

- Adicionar `reserva_tecnica` ao estado do formulário com valor padrão `false`
- Adicionar campo no `useEffect` para carregar o valor ao editar
- Adicionar um campo de seleção (Sim/Não) no formulário para o usuário marcar se o diarista é reserva técnica

### 3. Atualização da Listagem (Diaristas.tsx) - Opcional

- Considerar adicionar uma coluna ou badge indicando se o diarista é reserva técnica na tabela de listagem

---

## Detalhes Técnicos

### Arquivos Impactados
| Arquivo | Alteração |
|---------|-----------|
| Nova migração SQL | Adicionar coluna e atualizar dados existentes |
| `src/integrations/supabase/types.ts` | Atualização automática |
| `src/components/diaristas/DiaristaForm.tsx` | Adicionar campo no formulário |
| `src/pages/Diaristas.tsx` | (Opcional) Exibir indicador de reserva técnica |

### Estrutura do Campo
- **Nome**: `reserva_tecnica`
- **Tipo**: `boolean`
- **Nullable**: Sim (opcional)
- **Default**: `false`

### Impacto nas Políticas RLS
Nenhuma alteração necessária - as políticas existentes já cobrem operações CRUD na tabela `diaristas`.
