
-- 1. Criar cliente Tragaluz
INSERT INTO public.clientes (id, razao_social, nome_fantasia, cnpj, convenia_cost_center_id)
VALUES (29, 'Tragaluz', 'Tragaluz', '', '40ee6f53-972c-431c-825a-54eb105ef358');

-- 2. Criar contrato para Tragaluz (conq_perd = 2026)
INSERT INTO public.contratos (cliente_id, negocio, conq_perd, data_inicio)
VALUES (29, 'Tragaluz', 2026, '2026-01-01');

-- 3. Criar unidade para Tragaluz
INSERT INTO public.unidades (nome, contrato_id, endereco, cidade, uf, latitude, longitude, faturamento_vendido)
SELECT 'Tragaluz', id, 'A definir', 'Belo Horizonte', 'MG', -19.9167, -43.9345, 34922.48 FROM public.contratos WHERE negocio = 'Tragaluz' AND cliente_id = 29 LIMIT 1;

-- 4. Desabilitar triggers de usuário antes de inserir postos
ALTER TABLE public.postos_servico DISABLE TRIGGER gerar_dias_trabalho_mes_corrente_trg;
ALTER TABLE public.postos_servico DISABLE TRIGGER marcar_dias_posto_vago_trg;
ALTER TABLE public.postos_servico DISABLE TRIGGER marcar_dias_posto_vago_trigger;
ALTER TABLE public.postos_servico DISABLE TRIGGER trigger_gerar_dias_trabalho;
ALTER TABLE public.postos_servico DISABLE TRIGGER trigger_gerar_dias_trabalho_mes_corrente;
ALTER TABLE public.postos_servico DISABLE TRIGGER trigger_gerenciar_ultimo_dia_atividade;
ALTER TABLE public.postos_servico DISABLE TRIGGER validar_dias_semana_trigger;

-- 5. Criar postos_servico para Tragaluz
INSERT INTO public.postos_servico (nome, funcao, escala, turno, valor_unitario, adicional_noturno, intrajornada, insalubridade, periculosidade, acumulo_funcao, observacoes_especificas, cliente_id, cost_center_id, status)
VALUES 
('ASG 1 - Adc de Copa', 'ASG', '12x36', 'Noturno', 5963.52, true, false, false, false, 'Sim', 'Adicional de função de copa', 29, '59da43d7-6dd8-4840-bc25-21a3aeecf63d', 'vago'),
('ASG 2 - Adc de Copa', 'ASG', '12x36', 'Noturno', 5963.52, true, false, false, false, 'Sim', 'Adicional de função de copa', 29, '59da43d7-6dd8-4840-bc25-21a3aeecf63d', 'vago'),
('ASG 3 - Insalubridade 20%', 'ASG', '12x36', 'Noturno', 6252.63, true, false, true, false, 'Não', NULL, 29, '59da43d7-6dd8-4840-bc25-21a3aeecf63d', 'vago'),
('ASG 4 - Insalubridade 20%', 'ASG', '12x36', 'Noturno', 6252.63, true, false, true, false, 'Não', NULL, 29, '59da43d7-6dd8-4840-bc25-21a3aeecf63d', 'vago'),
('ASG 5', 'ASG', '12x36', 'Diurno', 5245.09, false, false, false, false, 'Não', NULL, 29, '59da43d7-6dd8-4840-bc25-21a3aeecf63d', 'vago'),
('ASG 6', 'ASG', '12x36', 'Diurno', 5245.09, false, false, false, false, 'Não', NULL, 29, '59da43d7-6dd8-4840-bc25-21a3aeecf63d', 'vago');

-- 6. Reabilitar triggers
ALTER TABLE public.postos_servico ENABLE TRIGGER gerar_dias_trabalho_mes_corrente_trg;
ALTER TABLE public.postos_servico ENABLE TRIGGER marcar_dias_posto_vago_trg;
ALTER TABLE public.postos_servico ENABLE TRIGGER marcar_dias_posto_vago_trigger;
ALTER TABLE public.postos_servico ENABLE TRIGGER trigger_gerar_dias_trabalho;
ALTER TABLE public.postos_servico ENABLE TRIGGER trigger_gerar_dias_trabalho_mes_corrente;
ALTER TABLE public.postos_servico ENABLE TRIGGER trigger_gerenciar_ultimo_dia_atividade;
ALTER TABLE public.postos_servico ENABLE TRIGGER validar_dias_semana_trigger;
