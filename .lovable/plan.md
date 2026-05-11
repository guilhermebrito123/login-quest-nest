# Módulo: Alocação de colaboradores Convenia em postos de serviço

Este plano consolida exatamente o desenho que você descreveu, em uma única migration coesa, sem duplicar histórico (RPCs/cron gravam o histórico explicitamente; o trigger só grava em UPDATEs diretos fora das RPCs, controlado por `app.skip_alocacao_trigger`).

## Escopo

Criar todo o módulo de alocação de colaboradores Convenia em postos de serviço, isolado dos fluxos atuais de `colaboradores` (efetivos), `dias_trabalho` e `escalas`. A escala é lida de `postos_servico.escala`; horários ficam por alocação.

## Estrutura proposta

```text
colaboradores_convenia ──┐
                         │ 1:N (apenas 1 ativa via índice único parcial)
                         ▼
   colaboradores_convenia_alocacoes ──► postos_servico
                         │
                         │ histórico explícito (RPCs + cron) e
                         │ trigger de proteção em UPDATE direto
                         ▼
   colaboradores_convenia_alocacoes_historico
```

## O que será criado (em uma única migration)

1. **Tabelas**
   - `colaboradores_convenia_alocacoes` (alocação atual/passada por colaborador, com `horario_entrada/saida`, `intervalo_minutos`, `paridade_12x36`, `data_inicio/fim`, `ativo`).
   - `colaboradores_convenia_alocacoes_historico` (trilha de auditoria com `operacao`, `motivo`, `registro_anterior/novo` em `jsonb`).

2. **Constraints**
   - `chk_alocacao_horarios_diferentes`, `chk_alocacao_intervalo_valido`, `chk_alocacao_datas_validas`, `chk_alocacao_paridade_12x36`.
   - Histórico: `chk_hist_operacao_alocacao`, `chk_hist_paridade_anterior/nova`.
   - Índice único parcial `uq_colaborador_convenia_alocacao_ativa` garantindo uma única alocação ativa por colaborador.

3. **Índices** em `colaborador_convenia_id`, `posto_servico_id`, `ativo`, `(colaborador, ativo)` e nos campos de busca do histórico.

4. **Funções e triggers**
   - `fn_posto_servico_is_12x36(uuid)` — detecta `12x36` em `postos_servico.escala` ignorando espaços/caixa.
   - `trg_validar_alocacao_12x36` — exige `paridade_12x36` quando o posto for 12x36; zera quando não for. Antes de INSERT/UPDATE.
   - `trg_set_updated_at_alocacao_convenia` — antes de UPDATE.
   - `trg_log_alocacao_convenia` — após UPDATE; **só grava histórico** quando `app.skip_alocacao_trigger` não estiver `'true'` (isto é, em updates diretos fora das RPCs). Classifica a operação (`transferencia_posto`, `alteracao_paridade_12x36`, `alteracao_horario`, `update_direto`).

5. **View**
   - `v_colaboradores_convenia_alocacao_atual` juntando `colaboradores_convenia` + `postos_servico` para a alocação ativa.

6. **RPCs** (todas `security definer` e setam `app.skip_alocacao_trigger='true'` para evitar histórico duplicado; cada uma grava o histórico explicitamente)
   - `rpc_alocar_colaborador_convenia(...)` — `alocacao_inicial`.
   - `rpc_movimentar_colaborador_convenia(...)` — encerra a ativa (`data_fim = data_inicio - 1`), abre nova; `transferencia_posto`.
   - `rpc_alterar_horario_alocacao_convenia(...)` — `alteracao_horario` ou `alteracao_paridade_12x36`.
   - `rpc_desvincular_colaborador_convenia(...)` — `desvinculacao`.
   - `rpc_get_historico_alocacao_colaborador_convenia(uuid)` — leitura com nomes dos postos.

7. **Rotina mensal de paridade 12x36**
   - `fn_alternar_paridade_12x36_mensal()`: se o mês anterior teve número ímpar de dias (28, 30 → não alterna; 29, 31 → alterna), inverte `'impar' ↔ 'par'` para todas as alocações ativas em postos 12x36 e grava `atualizacao_automatica_12x36` no histórico.
   - Agendada via `pg_cron` em `5 0 1 * *` com nome `alternar-paridade-12x36-mensal` (com `unschedule` defensivo se já existir).

8. **Permissões** — `grant execute` das RPCs e `grant select` na view para `authenticated`. `select` defensivo nas duas tabelas para `authenticated` (todo write deve passar pelas RPCs).

## Por que esta forma evita duplicação de histórico

- Em fluxos normais (RPCs e cron) o histórico é inserido **manualmente** pela própria função, e a flag `app.skip_alocacao_trigger='true'` desliga o trigger durante a transação.
- O trigger `trg_log_alocacao_convenia` continua ativo apenas como rede de segurança para `UPDATE` direto na tabela (fora das RPCs), classificando como `update_direto` quando não for transferência/horário/paridade.

## Pontos que confirmei contra o schema atual

- `colaboradores_convenia.id` é `uuid` ✅
- `postos_servico` possui `escala text`, `cliente_id`, `unidade_id`, `cost_center_id`, `dias_semana`, `turno` (já presentes na view).
- O módulo **não toca** em `colaboradores`, `dias_trabalho`, `escalas`, `faltas_*` nem nas RPCs do fluxo de diárias/faltas discutidas anteriormente.

## Observações para sua decisão antes de implementar

1. **Regra mensal de paridade**: como descrito, ela **só alterna** quando o mês anterior tem número ímpar de dias (29 em fevereiro bissexto, 31 em jan/mar/mai/jul/ago/out/dez). Em meses de 28/30 dias a paridade é mantida. Confirmar se é exatamente isto.
2. **`pg_cron`**: a migration tenta `create extension if not exists pg_cron` e agenda o job. Se preferir, posso entregar o agendamento como passo separado.
3. **Permissões**: por padrão concedo execução das RPCs e leitura da view a `authenticated`. Se quiser restringir a um role/policy específico (ex.: `perfil_interno`), me diga e eu adiciono `revoke ... from public` + checagem de role nas RPCs (`current_internal_access_level()`).
4. **RLS**: as duas tabelas novas podem ficar com RLS habilitada e leitura permitida via `has_role`/helper interno; por ora segui sua especificação (apenas grants). Posso adicionar políticas RLS se quiser.

Se confirmar, eu emito uma única `supabase--migration` com todo o bloco (tabelas, constraints, índices, funções, triggers, view, RPCs, função mensal, agendamento e grants) exatamente como descrito.
