## Resposta direta

Não há no sistema um fluxo de frontend/backend dedicado para converter uma diária originada de `AFASTAMENTO INSS` para `DIÁRIA - SALÁRIO`. As triggers existentes em `diarias_temporarias` validam transições de status e sincronizam com `faltas_colaboradores_convenia` / `dias_trabalho`, mas não oferecem uma ação de "reclassificação de motivo". Por isso, a alteração precisa ser feita via SQL direto, como no caso da diária 1781.

## Alteração proposta (SQL puro, com bypass de trigger)

Atualizar 5 registros em `public.diarias_temporarias`:

- IDs: `1753, 1724, 1631, 1526, 1506`
- `motivo_vago`: `AFASTAMENTO INSS` → `DIÁRIA - SALÁRIO`
- `novo_posto`: `false`
- Demais campos preservados (colaborador, posto, datas, valor, status, etc.)

Para evitar bloqueio das triggers de autorização (que exigem `auth.uid()`), será usado `SET LOCAL app.rpc_call = 'true'` no mesmo bloco, conforme padrão já adotado no projeto.

```sql
SET LOCAL app.rpc_call = 'true';

UPDATE public.diarias_temporarias
SET motivo_vago = 'DIÁRIA - SALÁRIO',
    novo_posto = false
WHERE id IN (1753, 1724, 1631, 1526, 1506)
  AND motivo_vago = 'AFASTAMENTO INSS';
```

A cláusula adicional `AND motivo_vago = 'AFASTAMENTO INSS'` serve como salvaguarda: se algum registro já tiver sido alterado, ele não será sobrescrito.

## Observações

- Nenhum registro será criado/removido em `faltas_colaboradores_convenia` ou `dias_trabalho` — apenas os dois campos da diária mudam.
- Caso `DIÁRIA - SALÁRIO` não exista no enum `motivo_vago_type`, o update falhará e precisaremos confirmar o label exato antes de prosseguir.
