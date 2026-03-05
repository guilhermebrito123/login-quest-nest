
-- 1. Criar cliente DNIT
INSERT INTO public.clientes (razao_social, nome_fantasia, cnpj, convenia_cost_center_id)
VALUES ('DNIT MG', 'DNIT MG', 'A DEFINIR - DNIT', 'ade599c5-9b5a-453c-a0f5-6fd03da5c169');

-- 2. Criar contrato para DNIT
INSERT INTO public.contratos (cliente_id, negocio, conq_perd, data_inicio)
SELECT id, 'DNIT MG', 2026, '2026-01-01' FROM public.clientes WHERE nome_fantasia = 'DNIT MG' LIMIT 1;

-- 3. Criar unidade para DNIT
INSERT INTO public.unidades (nome, contrato_id, endereco, cidade, uf, latitude, longitude, faturamento_vendido)
SELECT 'DNIT MG', c.id, 'A definir', 'Belo Horizonte', 'MG', -19.9167, -43.9345, 14222.34
FROM public.contratos c
JOIN public.clientes cl ON c.cliente_id = cl.id
WHERE cl.nome_fantasia = 'DNIT MG' AND c.negocio = 'DNIT MG'
LIMIT 1;

-- 4. Desabilitar triggers
ALTER TABLE public.postos_servico DISABLE TRIGGER gerar_dias_trabalho_mes_corrente_trg;
ALTER TABLE public.postos_servico DISABLE TRIGGER marcar_dias_posto_vago_trg;
ALTER TABLE public.postos_servico DISABLE TRIGGER marcar_dias_posto_vago_trigger;
ALTER TABLE public.postos_servico DISABLE TRIGGER trigger_gerar_dias_trabalho;
ALTER TABLE public.postos_servico DISABLE TRIGGER trigger_gerar_dias_trabalho_mes_corrente;
ALTER TABLE public.postos_servico DISABLE TRIGGER trigger_gerenciar_ultimo_dia_atividade;
ALTER TABLE public.postos_servico DISABLE TRIGGER validar_dias_semana_trigger;

-- 5. Criar postos_servico para DNIT
INSERT INTO public.postos_servico (nome, funcao, escala, turno, valor_unitario, adicional_noturno, intrajornada, insalubridade, periculosidade, acumulo_funcao, observacoes_especificas, cliente_id, cost_center_id, status, dias_semana)
VALUES
  ('ASG 1', 'ASG', '5x2', 'Diurno'::turno_opcoes, 4740.78, false, false, false, false, 'Não', NULL, (SELECT id FROM public.clientes WHERE nome_fantasia = 'DNIT MG' LIMIT 1), 'ade599c5-9b5a-453c-a0f5-6fd03da5c169', 'vago', '{1,2,3,4,5}'),
  ('ASG 2', 'ASG', '5x2', 'Diurno'::turno_opcoes, 4740.78, false, false, false, false, 'Não', NULL, (SELECT id FROM public.clientes WHERE nome_fantasia = 'DNIT MG' LIMIT 1), 'ade599c5-9b5a-453c-a0f5-6fd03da5c169', 'vago', '{1,2,3,4,5}'),
  ('ASG 3', 'ASG', '5x2', 'Diurno'::turno_opcoes, 4740.78, false, false, false, false, 'Não', NULL, (SELECT id FROM public.clientes WHERE nome_fantasia = 'DNIT MG' LIMIT 1), 'ade599c5-9b5a-453c-a0f5-6fd03da5c169', 'vago', '{1,2,3,4,5}');

-- 6. Reabilitar triggers
ALTER TABLE public.postos_servico ENABLE TRIGGER gerar_dias_trabalho_mes_corrente_trg;
ALTER TABLE public.postos_servico ENABLE TRIGGER marcar_dias_posto_vago_trg;
ALTER TABLE public.postos_servico ENABLE TRIGGER marcar_dias_posto_vago_trigger;
ALTER TABLE public.postos_servico ENABLE TRIGGER trigger_gerar_dias_trabalho;
ALTER TABLE public.postos_servico ENABLE TRIGGER trigger_gerar_dias_trabalho_mes_corrente;
ALTER TABLE public.postos_servico ENABLE TRIGGER trigger_gerenciar_ultimo_dia_atividade;
ALTER TABLE public.postos_servico ENABLE TRIGGER validar_dias_semana_trigger;
