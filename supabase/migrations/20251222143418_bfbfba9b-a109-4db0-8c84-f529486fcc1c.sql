
-- Desabilitar temporariamente os triggers que geram dias de trabalho automaticamente
ALTER TABLE postos_servico DISABLE TRIGGER gerar_dias_trabalho_mes_corrente_trg;
ALTER TABLE postos_servico DISABLE TRIGGER marcar_dias_posto_vago_trg;
ALTER TABLE postos_servico DISABLE TRIGGER marcar_dias_posto_vago_trigger;
ALTER TABLE postos_servico DISABLE TRIGGER trigger_gerar_dias_trabalho;
ALTER TABLE postos_servico DISABLE TRIGGER trigger_gerar_dias_trabalho_mes_corrente;
ALTER TABLE dias_trabalho DISABLE TRIGGER sync_dias_vagos_trg;
