

## Plano: Remover preenchimento automático de `cost_center_id` em `horas_extras`

### Problema

O trigger `set_cost_center_from_colaborador_cobrindo` preenche automaticamente o `cost_center_id` para operações `demanda_extra`, `bonus`, `dobra_turno`, `extensao_jornada` usando o cost_center do `colaborador_cobrindo_id`. Isso está errado — o `cost_center_id` deve **sempre** ser inserido manualmente, independente do tipo de operação.

### Solução

Recriar a função `set_cost_center_from_colaborador_cobrindo` removendo toda a lógica de preenchimento automático no INSERT. Manter apenas a regra de imutabilidade no UPDATE (bloquear alteração após criação).

Nova lógica da função:

```sql
CREATE OR REPLACE FUNCTION public.set_cost_center_from_colaborador_cobrindo()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- On UPDATE: block changes to cost_center_id once set
  IF TG_OP = 'UPDATE' AND OLD.cost_center_id IS DISTINCT FROM NEW.cost_center_id THEN
    RAISE EXCEPTION 'O centro de custo não pode ser alterado após a criação da hora extra';
  END IF;

  RETURN NEW;
END;
$$;
```

### Impacto

- Nenhuma alteração de schema — apenas a lógica do trigger muda
- O `cost_center_id` passa a ser responsabilidade do usuário em **todos** os casos
- A imutabilidade após criação permanece

