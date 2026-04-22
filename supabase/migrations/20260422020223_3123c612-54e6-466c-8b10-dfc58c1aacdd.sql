-- Remover UPDATE/DELETE diretos das tabelas de auditoria
-- A remoção só pode ocorrer via CASCADE quando o registro origem for deletado

DROP POLICY IF EXISTS status_historico_update ON public.checklist_tarefa_status_historico;
DROP POLICY IF EXISTS status_historico_delete ON public.checklist_tarefa_status_historico;

DROP POLICY IF EXISTS plano_atualizacoes_update ON public.plano_acao_atualizacoes;
DROP POLICY IF EXISTS plano_atualizacoes_delete ON public.plano_acao_atualizacoes;