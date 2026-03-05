
-- 1. Criar cliente CHART
INSERT INTO public.clientes (razao_social, nome_fantasia, cnpj, convenia_cost_center_id)
VALUES ('Chart', 'Chart', 'A DEFINIR - CHART', '1ea1657c-41b5-487b-b856-9f8f1beafdf1');

-- 2. Criar contrato para Chart
INSERT INTO public.contratos (cliente_id, negocio, conq_perd, data_inicio)
SELECT id, 'Chart', 2026, '2026-01-01' FROM public.clientes WHERE nome_fantasia = 'Chart' LIMIT 1;

-- 3. Criar unidade para Chart
INSERT INTO public.unidades (nome, contrato_id, endereco, cidade, uf, latitude, longitude, faturamento_vendido)
SELECT 'Chart', c.id, 'A definir', 'Belo Horizonte', 'MG', -19.9167, -43.9345, 29708.64
FROM public.contratos c
JOIN public.clientes cl ON c.cliente_id = cl.id
WHERE cl.nome_fantasia = 'Chart' AND c.negocio = 'Chart'
LIMIT 1;

-- 4. Desabilitar triggers
ALTER TABLE public.postos_servico DISABLE TRIGGER gerar_dias_trabalho_mes_corrente_trg;
ALTER TABLE public.postos_servico DISABLE TRIGGER marcar_dias_posto_vago_trg;
ALTER TABLE public.postos_servico DISABLE TRIGGER marcar_dias_posto_vago_trigger;
ALTER TABLE public.postos_servico DISABLE TRIGGER trigger_gerar_dias_trabalho;
ALTER TABLE public.postos_servico DISABLE TRIGGER trigger_gerar_dias_trabalho_mes_corrente;
ALTER TABLE public.postos_servico DISABLE TRIGGER trigger_gerenciar_ultimo_dia_atividade;
ALTER TABLE public.postos_servico DISABLE TRIGGER validar_dias_semana_trigger;

-- 5. Criar postos_servico para Chart
INSERT INTO public.postos_servico (nome, funcao, escala, turno, valor_unitario, adicional_noturno, intrajornada, insalubridade, periculosidade, acumulo_funcao, observacoes_especificas, cliente_id, cost_center_id, status, dias_semana)
VALUES
  ('ASG Fábrica 1 - Adc de Copa', 'ASG', '5x2', 'Diurno'::turno_opcoes, 6127.48, false, false, false, false, 'Sim', 'Adicional de função de copa', (SELECT id FROM public.clientes WHERE nome_fantasia = 'Chart' LIMIT 1), '1ea1657c-41b5-487b-b856-9f8f1beafdf1', 'vago', '{1,2,3,4,5}'),
  ('ASG Fábrica 2 - Insalubridade 40%', 'ASG', '5x2', 'Diurno'::turno_opcoes, 7043.05, false, false, true, false, 'Não', NULL, (SELECT id FROM public.clientes WHERE nome_fantasia = 'Chart' LIMIT 1), '1ea1657c-41b5-487b-b856-9f8f1beafdf1', 'vago', '{1,2,3,4,5}'),
  ('ASG Diamond 1 - Adc de Copa', 'ASG', '6x1', 'Diurno'::turno_opcoes, 5708.52, false, false, false, false, 'Sim', 'Adicional de função de copa', (SELECT id FROM public.clientes WHERE nome_fantasia = 'Chart' LIMIT 1), '1ea1657c-41b5-487b-b856-9f8f1beafdf1', 'vago', '{1,2,3,4,5,6}'),
  ('ASG Ecommerce 1 - Adc de Copa', 'ASG', '5x2', 'Diurno'::turno_opcoes, 5329.42, false, false, false, false, 'Sim', 'Adicional de função de copa', (SELECT id FROM public.clientes WHERE nome_fantasia = 'Chart' LIMIT 1), '1ea1657c-41b5-487b-b856-9f8f1beafdf1', 'vago', '{1,2,3,4,5}'),
  ('ASG Lj Vila da Serra 1 - Adc de Copa', 'ASG', '6x1', 'Diurno'::turno_opcoes, 5500.17, false, false, false, false, 'Sim', 'Adicional de função de copa', (SELECT id FROM public.clientes WHERE nome_fantasia = 'Chart' LIMIT 1), '1ea1657c-41b5-487b-b856-9f8f1beafdf1', 'vago', '{1,2,3,4,5,6}');

-- 6. Reabilitar triggers
ALTER TABLE public.postos_servico ENABLE TRIGGER gerar_dias_trabalho_mes_corrente_trg;
ALTER TABLE public.postos_servico ENABLE TRIGGER marcar_dias_posto_vago_trg;
ALTER TABLE public.postos_servico ENABLE TRIGGER marcar_dias_posto_vago_trigger;
ALTER TABLE public.postos_servico ENABLE TRIGGER trigger_gerar_dias_trabalho;
ALTER TABLE public.postos_servico ENABLE TRIGGER trigger_gerar_dias_trabalho_mes_corrente;
ALTER TABLE public.postos_servico ENABLE TRIGGER trigger_gerenciar_ultimo_dia_atividade;
ALTER TABLE public.postos_servico ENABLE TRIGGER validar_dias_semana_trigger;
