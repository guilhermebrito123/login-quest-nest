
The user wants to ensure that internal users (perfil_interno) with any access level except `cliente_view` can read the FULL history of any chamado, regardless of who created it or which cost_center it belongs to.

Looking at current RLS policies:
- `chamados.chamados_select`: `is_internal_user() OR solicitante_id = auth.uid()` — `is_internal_user()` likely returns true for ALL internal users INCLUDING `cliente_view`. Need to verify and exclude cliente_view.
- `chamado_anexos.anexos_select`: same pattern
- `chamado_interacoes.interacoes_select`: same pattern (internos veem TUDO incluindo internas)
- `chamado_historico.historico_select`: same pattern

The user's request is to restrict `cliente_view` from seeing chamados history, while allowing all other internal levels to see everything (including internal interactions and full historic).

Need to check what `is_internal_user()` does — it likely returns true for any perfil_interno regardless of nivel_acesso. So today `cliente_view` CAN read everything, which is wrong.

Plan: update the SELECT policies on the 4 chamado tables to require internal access level different from `cliente_view`, while preserving collaborator's ability to see their own tickets.

# Plano: Restringir leitura de chamados para `cliente_view`

## Diagnóstico

Hoje, as policies SELECT das 4 tabelas de chamados usam `is_internal_user()`, que retorna `true` para QUALQUER `perfil_interno` — incluindo `cliente_view`. Ou seja, `cliente_view` consegue ler todos os chamados, anexos, interações (até as internas) e histórico. Isso precisa mudar.

## O que será feito

Substituir `is_internal_user()` por uma checagem mais restritiva nas 4 policies SELECT:

```sql
current_internal_access_level() IS NOT NULL 
AND current_internal_access_level() <> 'cliente_view'
```

Isso replica exatamente o padrão já usado em `chamados_update`.

### Tabelas afetadas (4 policies SELECT)

| Tabela | Nova regra SELECT |
|--------|-------------------|
| `chamados` | Interno (≠ cliente_view) **OU** solicitante = auth.uid() |
| `chamado_anexos` | Interno (≠ cliente_view) **OU** solicitante do chamado = auth.uid() |
| `chamado_interacoes` | Interno (≠ cliente_view) vê TUDO (incl. internas) **OU** colaborador vê apenas `interno = false` dos próprios chamados |
| `chamado_historico` | Interno (≠ cliente_view) **OU** solicitante do chamado = auth.uid() |

## Resultado final por perfil

| Perfil | Chamados | Anexos | Interações internas | Interações públicas | Histórico |
|--------|----------|--------|---------------------|---------------------|-----------|
| `admin`, `gestor_*`, `supervisor`, `assistente_*`, `tecnico`, `analista_*` | Todos | Todos | Sim | Sim | Todo |
| `cliente_view` | **Não** | **Não** | **Não** | **Não** | **Não** |
| `colaborador` | Próprios | Próprios | Não | Próprios | Próprios |

## Detalhes técnicos

Será gerada **1 migration** que faz `DROP POLICY` + `CREATE POLICY` nas 4 tabelas. Nenhum arquivo de código frontend precisa ser alterado.

```sql
-- Exemplo para chamados
DROP POLICY IF EXISTS chamados_select ON public.chamados;
CREATE POLICY chamados_select ON public.chamados
FOR SELECT USING (
  (current_internal_access_level() IS NOT NULL 
   AND current_internal_access_level() <> 'cliente_view'::internal_access_level)
  OR solicitante_id = auth.uid()
);
```

E padrão análogo para `chamado_anexos`, `chamado_interacoes` (preservando regra de `interno = false` para colaboradores) e `chamado_historico`.

## Observação sobre `cliente_view`

Esse perfil fica completamente sem acesso a chamados. Se mais tarde você quiser dar a ele acesso somente-leitura a chamados de um cost_center específico (similar ao que colaborador tem), dá para evoluir depois — não é escopo agora.
