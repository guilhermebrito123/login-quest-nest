

## Plano: Deduplicação de Diaristas por CPF

### Situação Atual

3 CPFs duplicados encontrados:

| CPF | Manter (ID) | Refs | Excluir (ID) | Refs |
|---|---|---|---|---|
| 09077957650 (Camila) | `c6a0fff4` | 3 diárias | `7a6d37d1` | 0 diárias |
| 68686790410 (José Antônio) | `0a404d5f` | 5 diárias | `c50e010d` | 3 diárias |
| 97045292600 (Rosimary) | `92600f80` | 5 diárias | `f3ed6359` | 4 diárias |

Nenhuma referência encontrada nas tabelas `blacklist`, `diaristas_historico`, `diaristas_anexos` ou `diarias` para esses registros duplicados.

### Ações

1. **Reatribuir referências em `diarias_temporarias`**: Para cada duplicata a ser excluída, atualizar `diarista_id` para apontar ao registro que permanecerá
   - `c50e010d` → `0a404d5f` (3 diárias)
   - `f3ed6359` → `92600f80` (4 diárias)
   - `7a6d37d1` não tem referências, nada a reatribuir

2. **Excluir os 3 registros duplicados** da tabela `diaristas`

3. **Adicionar constraint UNIQUE** no campo `cpf` (parcial, apenas para CPFs não-nulos) para prevenir futuras duplicatas — caso já não exista via `diaristas_cpf_normalizado_unique`

### Detalhes Técnicos

- Usar migration para a constraint (se necessário)
- Usar insert tool (que suporta UPDATE/DELETE) para as operações de dados
- O índice único parcial `diaristas_cpf_normalizado_unique` em `cpf_normalizado` já existe, então não é necessário criar novo constraint

