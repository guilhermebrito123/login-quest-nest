## Objetivo
Registrar quem criou/alterou/excluiu cada registro de `public.faltas_colaboradores_convenia`, sem tocar em nenhuma policy, função ou trigger já existente.

## Estado atual verificado
- `faltas_colaboradores_convenia`: `id bigint`, `colaborador_convenia_id uuid`, `diaria_temporaria_id bigint`, `data_falta`, `motivo`, `atestado_path`, `justificada_em`, `justificada_por uuid`, `local_falta uuid`, `created_at`, `updated_at`. **Não existem** `created_by`/`updated_by`.
- Triggers já existentes na tabela (todas serão preservadas): `trg_bloquear_vinculo_diaria_se_hora_extra` (BEFORE UPDATE), `trg_reverter_justificativa_ao_remover_atestado` (BEFORE UPDATE), `trg_sync_falta_para_diaria`, `trg_faltas_convenia_cascade_data_hora_extra`, `trg_sync_hora_extra_operacao_on_falta_motivo` (AFTER UPDATE), `trg_cascade_delete_diaria_on_falta_delete` (AFTER DELETE).
- `public.usuarios(id uuid, full_name, email)` existe → FK e resolução de nome/email são válidas.
- `public.has_role(uuid, internal_access_level)` existe → a policy do script funciona como está.

## O que será implementado
1. **Colunas de autoria** `created_by` / `updated_by` (uuid, FK → `public.usuarios(id)`) em `faltas_colaboradores_convenia`, mais trigger BEFORE INSERT/UPDATE `trg_faltas_convenia_autoria` que grava `auth.uid()` (só se o uid existir em `usuarios`, evitando violação de FK) e nunca reescreve `created_by`.
2. **Tabela nova** `public.faltas_colaboradores_convenia_auditoria` (id identity, `falta_id bigint`, `operacao`, `evento`, `alterado_em`, `alterado_por`, nome/email do autor, `dados_antigos`, `dados_novos`, `campos_alterados`, `ip_origem`, `user_agent`) — sem FK para a tabela original, para sobreviver a exclusões. Índices em `falta_id`, `alterado_em DESC`, `alterado_por`, `evento`.
3. **RLS apenas na tabela nova**: `GRANT SELECT` a `authenticated`, sem acesso para `anon`, e uma policy de leitura para `admin`, `gestor_operacoes` e `supervisor` via `has_role`. Nenhuma policy existente é criada, alterada ou removida.
4. **Trigger AFTER INSERT/UPDATE/DELETE** `trg_faltas_convenia_auditoria`, que classifica o evento (`CRIACAO`, `ATUALIZACAO`, `EXCLUSAO`, `JUSTIFICATIVA_REGISTRADA`, `JUSTIFICATIVA_REVERTIDA`, `JUSTIFICATIVA_ALTERADA`) e grava o diff campo a campo.
5. **View** `public.vw_faltas_colaboradores_convenia_auditoria` com o autor resolvido por `LEFT JOIN usuarios`, com `security_invoker = on` para que a RLS da tabela de auditoria continue valendo (ajuste em relação ao script original, que sem isso criaria uma view SECURITY DEFINER e seria apontada como falha de segurança pelo linter).

## Ajustes em relação ao script enviado
- View criada com `WITH (security_invoker = on)` e sem `ORDER BY` interno (ordenação fica a cargo da consulta).
- Sem `REVOKE ... FROM anon` desnecessário além do padrão; grants explícitos conforme padrão do projeto (`GRANT SELECT ... TO authenticated`, `GRANT ALL ... TO service_role` para uso por edge functions).
- Resto do script mantido: nomes, colunas, eventos e comportamento "best-effort".

## Por que não quebra fluxos atuais
- A trigger de autoria é BEFORE e só escreve em duas colunas novas; a de auditoria é AFTER e só faz INSERT em tabela nova.
- Ambas envolvem toda a lógica em bloco `EXCEPTION WHEN OTHERS` com `RAISE WARNING`: qualquer erro na auditoria **não** aborta o INSERT/UPDATE/DELETE original.
- Triggers AFTER UPDATE já existentes continuam disparando na mesma ordem relativa (ordem alfabética não altera a semântica delas, pois nenhuma depende de `created_by`/`updated_by`).
- Nenhuma policy, função ou trigger de outros módulos é tocada.
- Registros anteriores ficam com `created_by/updated_by = NULL` e sem histórico retroativo (não há como reconstruir).

## Depois da migração
Retorno o resultado do linter e, se você quiser, um prompt pronto para o seu frontend local consumir a view de auditoria.
