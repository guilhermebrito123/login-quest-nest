# Diagnóstico — logs de diárias temporárias

## Números reais do banco

- Linhas em `public.diarias_temporarias_logs`: **35.814**
- Tamanho da tabela: **4,8 MB** / índices: **5,6 MB** (tabela pequena)
- Índices já existentes cobrem quase tudo que você listou:
  - PK em `id`
  - `(operacao_em DESC, criado_em DESC)` — ordenação principal
  - `(diaria_id, operacao_em DESC)`
  - `(campo, operacao_em DESC)`
  - `(operacao, operacao_em DESC)`
  - `(usuario_responsavel, operacao_em DESC)`
  - `(operacao_em)` simples + índice de retenção em `COALESCE(criado_em, operacao_em)`

## EXPLAIN ANALYZE das consultas típicas

| Cenário | Tempo real | Plano |
|---|---|---|
| `ORDER BY operacao_em DESC LIMIT 50 OFFSET 0` | **2,4 ms** | Index Scan Backward (4 buffers) |
| `count(*)` exact sem filtro | **7,2 ms** | Index Only Scan (216 buffers) |
| Busca `ILIKE '%status%'` em 4 colunas + ORDER BY + LIMIT 50 | **1,0 ms** | Index Scan Backward, filtro em memória |

Todos os cenários custam **menos de 10 ms no Postgres**, inclusive o `count exact` e o OR/ILIKE. Nenhum ILIKE está caindo em seq scan lento porque o `ORDER BY ... LIMIT` já resolve via índice de tempo, e o filtro é aplicado em batches pequenos.

## Conclusão

**O banco não é o gargalo desta tela.** A demora percebida vem quase certamente do frontend, não da consulta:

1. O `select` está fazendo **embed via FK para `usuarios(full_name, email)`** — isso, sim, obriga o PostgREST a fazer join extra em cada linha e é o que mais tende a pesar quando cresce.
2. `count exact` roda em toda troca de página, mesmo quando os filtros não mudaram.
3. React renderizando 50 linhas com colunas grandes de `valor_antigo`/`valor_novo` (podem ser JSON longos) sem virtualização.
4. Latência de rede (ida/volta para o Supabase) domina os 2–10 ms de execução.

## O que vale a pena implementar

### Não implementar agora (não traz ganho mensurável)
- Nenhum índice novo. Os que você listou já existem ou seriam redundantes com os atuais para 35k linhas.
- **pg_trgm/GIN em `campo`, `operacao`, `valor_antigo`, `valor_novo`**: não compensa. O ILIKE hoje roda em 1 ms porque o LIMIT 50 sobre índice temporal já é seletivo. GIN trigram só valeria a pena se você fosse permitir busca **sem** ordenação temporal ou em tabelas com milhões de linhas.
- **Particionamento mensal**: fora de escala para 35k linhas / 5 MB. Só faria sentido acima de alguns milhões de linhas.
- **RPC keyset/cursor**: OFFSET só dói em páginas altas (offset > 10k). Com 35k linhas e ordenação indexada, OFFSET simples ainda é aceitável. Pode virar necessário no futuro, não agora.
- Coluna gerada consolidada para busca: prematuro.

### Vale a pena (ganho perceptível, baixo risco)
1. **Parar de embutir `usuarios(full_name, email)` na mesma query.** Buscar os logs primeiro, depois um `select ... in (usuario_ids)` em `usuarios` numa segunda chamada e mapear no cliente. É a mudança que mais deve reduzir latência percebida.
2. **Só rodar `count exact` quando filtros/busca mudarem**, não a cada troca de página. Cachear o total até o filtro mudar. Se quiser zero custo, usar `count: 'estimated'` (a tabela é analisada regularmente) e cair para `exact` só quando `< N`.
3. **`VACUUM ANALYZE public.diarias_temporarias_logs`** (barato, sem side effects) só para atualizar estatísticas — não vai transformar nada, mas é higiene.

Nada disso mexe em RLS, schema de tabela nem quebra o frontend — são ajustes na forma de consultar.

## Faz sentido?

Sim, mas com a inversão do foco: o banco está saudável para esta tela. A otimização de maior impacto é reduzir o payload por linha (tirar o embed de usuários) e evitar `count exact` repetido. Só depois disso, se ainda estiver lento, faz sentido pensar em keyset/virtualização de lista no React.

Se quiser, no build eu:
- Rodo `VACUUM ANALYZE` na tabela.
- Refatoro a tela para buscar usuários em query separada e cachear o count.
