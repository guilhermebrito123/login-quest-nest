
# Plano: Criar Edge Function `sync-convenia-cost-centers`

## Objetivo
Criar uma Edge Function dedicada chamada `sync-convenia-cost-centers` que sincroniza **apenas** os centros de custo do Convenia, permitindo execução independente sem processar colaboradores.

## Benefícios
- Sincronização mais rápida (apenas centros de custo)
- Menor consumo de recursos
- Possibilidade de executar separadamente quando necessário
- Endpoint dedicado para automações específicas

## Implementação

### 1. Criar a Edge Function

**Arquivo:** `supabase/functions/sync-convenia-cost-centers/index.ts`

A função irá:
- Buscar centros de custo da API Convenia (`/companies/cost-centers`)
- Usar upsert para inserir/atualizar na tabela `cost_center`
- Retornar resumo da sincronização (total, sucessos, erros)
- Incluir headers CORS para chamadas do frontend
- Usar o token `CONVENIA_COST_CENTER_TOKEN` (ou `CONVENIA_API_TOKEN` como fallback)

```text
Fluxo:
┌─────────────────────┐
│  Frontend/Client    │
└─────────┬───────────┘
          │ POST
          ▼
┌─────────────────────────────────────┐
│ sync-convenia-cost-centers          │
│ (Edge Function)                     │
└─────────┬───────────────────────────┘
          │ GET /companies/cost-centers
          ▼
┌─────────────────────┐
│   API Convenia      │
└─────────┬───────────┘
          │ Response
          ▼
┌─────────────────────────────────────┐
│ Upsert → tabela cost_center         │
└─────────────────────────────────────┘
```

### 2. Atualizar Configuração

**Arquivo:** `supabase/config.toml`

Adicionar configuração da nova função:
```toml
[functions.sync-convenia-cost-centers]
verify_jwt = false
```

## Detalhes Técnicos

### Estrutura da Resposta
```json
{
  "success": true,
  "message": "Sincronização de centros de custo concluída",
  "summary": {
    "total_found": 31,
    "synced": 31,
    "errors": 0
  },
  "errors": []
}
```

### Endpoint Final
```
POST https://jcsmwkkytigomvibwsnb.supabase.co/functions/v1/sync-convenia-cost-centers
```

### Chamada do Frontend
```typescript
const { data, error } = await supabase.functions.invoke('sync-convenia-cost-centers', {
  method: 'POST'
});
```

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `supabase/functions/sync-convenia-cost-centers/index.ts` | Criar |
| `supabase/config.toml` | Adicionar configuração |

## Observações
- A função existente `sync-convenia-colaboradores` continuará funcionando normalmente
- Ambas usam o mesmo token de API já configurado nos secrets
- Não há necessidade de alterações no banco de dados
