
-- Reabilitar os triggers que geram dias de trabalho automaticamente
ALTER TABLE postos_servico ENABLE TRIGGER gerar_dias_trabalho_mes_corrente_trg;
ALTER TABLE postos_servico ENABLE TRIGGER marcar_dias_posto_vago_trg;
ALTER TABLE postos_servico ENABLE TRIGGER marcar_dias_posto_vago_trigger;
ALTER TABLE postos_servico ENABLE TRIGGER trigger_gerar_dias_trabalho;
ALTER TABLE postos_servico ENABLE TRIGGER trigger_gerar_dias_trabalho_mes_corrente;
ALTER TABLE dias_trabalho ENABLE TRIGGER sync_dias_vagos_trg;
