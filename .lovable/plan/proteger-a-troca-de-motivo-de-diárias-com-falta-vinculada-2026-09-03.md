# Proteger a troca de motivo de diárias com falta vinculada

## Problema

Quando uma diária é criada com motivo `DIÁRIA - FALTA`, o sistema gera automaticamente uma falta para o colaborador ausente. Se depois alguém troca o motivo da diária (por exemplo para `DIÁRIA - SALÁRIO`), a falta gerada continua existindo e continua apontando para essa diária. O resultado é um registro de falta indevido, e a justificativa da falta passa a falhar com erro de "colaborador ausente é obrigatório", porque uma diária de salário não tem colaborador ausente.

Caso real: falta 4313 (02/09/2026, YAN SCHIAVO DE LIMA FERREIRA) ainda vinculada à diária 4342, hoje com motivo `DIÁRIA - SALÁRIO` e status Paga.

## O que será feito

### 1. Bloqueio claro na troca de motivo

Ao tentar alterar o motivo de uma diária de `DIÁRIA - FALTA` ou `DIÁRIA - FALTA ATESTADO` para qualquer outro motivo, a operação será recusada enquanto existir uma falta vinculada àquela diária. A mensagem de erro identificará exatamente a falta que impede a mudança, informando:

- o número (ID) da falta;
- o nome do colaborador;
- a data da falta;
- a orientação de excluir a falta antes de alterar o motivo da diária.

Assim, o usuário autorizado exclui a falta gerada por engano e só então corrige o motivo da diária.

### 2. Justificativa deixa de quebrar

A rotina de justificar falta passa a validar que a diária vinculada ainda é uma diária de falta. Se não for, ela devolve uma mensagem explicativa em vez do erro técnico atual sobre "colaborador ausente".

### 3. Correção do caso atual

Como a diária 4342 é legitimamente uma diária de salário, a falta 4313 será desvinculada dela (a falta continua existindo, com todo o seu histórico) para que possa ser justificada ou excluída normalmente pela equipe. Nenhum dado da diária 4342 é alterado.

## Fluxos que continuam iguais

- Criar diária de falta e gerar a falta automaticamente.
- Justificar e reverter justificativa de faltas normais.
- Cancelar ou reprovar diária, que já desvincula a falta hoje.
- Vínculo automático de falta existente a uma nova diária de falta.
- Exclusão de faltas pelos perfis já autorizados.

## Detalhes técnicos

- Nova trigger `BEFORE UPDATE` em `public.diarias_temporarias`: quando `OLD.motivo_vago IN ('DIÁRIA - FALTA','DIÁRIA - FALTA ATESTADO')` e `NEW.motivo_vago` for diferente (ou nulo), busca em `faltas_colaboradores_convenia` a linha com `diaria_temporaria_id = NEW.id`. Se existir, `RAISE EXCEPTION` com ID da falta, nome do colaborador (`colaboradores_convenia.name`/`last_name`) e `data_falta`.
- Bypass mantido para os fluxos internos que já usam `app.rpc_call` (`justificar_falta`, `reverter_justificativa`) e para transições de cancelamento/reprovação, que continuam desvinculando via `desvincular_falta_ao_reprovar_cancelar`.
- `justificar_falta_convenia`: antes do `UPDATE` na diária, verifica o `motivo_vago` atual; se não for de falta, levanta mensagem explicativa em vez de forçar `DIÁRIA - FALTA ATESTADO`.
- Correção pontual via `UPDATE` de dados: `faltas_colaboradores_convenia.diaria_temporaria_id = NULL` para a falta 4313, executado com o bypass oficial `app.rpc_call` para não disparar as regras de sincronização.
- Sem alteração de schema em tabelas; apenas funções, uma trigger e uma correção de dado pontual.
