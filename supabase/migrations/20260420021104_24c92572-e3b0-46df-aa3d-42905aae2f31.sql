-- ============================================================
-- ENUMS DO MÓDULO
-- ============================================================

CREATE TYPE public.module_recurrence_type AS ENUM (
  'one_time', 'daily', 'weekly', 'biweekly', 'monthly',
  'quarterly', 'semiannual', 'annual'
);

CREATE TYPE public.checklist_template_status AS ENUM (
  'draft', 'published', 'archived'
);

CREATE TYPE public.checklist_instance_status AS ENUM (
  'scheduled', 'open', 'in_progress', 'submitted', 'under_review',
  'reviewed', 'awaiting_action_plan', 'closed', 'cancelled'
);

CREATE TYPE public.checklist_task_response_type AS ENUM (
  'conformity_radio', 'text', 'textarea', 'number', 'score',
  'boolean', 'single_select', 'multi_select', 'date', 'datetime', 'time'
);

CREATE TYPE public.checklist_task_kanban_status AS ENUM (
  'pending', 'doing', 'blocked', 'ignored', 'done'
);

CREATE TYPE public.checklist_review_decision AS ENUM (
  'approved', 'rejected', 'needs_action_plan', 'needs_adjustment'
);

CREATE TYPE public.action_plan_status AS ENUM (
  'open', 'in_progress', 'waiting_validation', 'done', 'cancelled'
);

CREATE TYPE public.action_plan_nonconformity_class AS ENUM (
  'organizacao', 'limpeza', 'conservacao', 'manutencao_predial',
  'manutencao_equipamentos', 'infraestrutura', 'instalacoes_eletricas',
  'instalacoes_hidraulicas', 'ti_sistemas', 'ti_hardware', 'ti_rede',
  'seguranca_trabalho', 'seguranca_patrimonial', 'epi', 'epc',
  'sinalizacao', 'acessibilidade', 'ergonomia', 'saude_ocupacional',
  'treinamentos', 'competencia_tecnica', 'documentacao', 'procedimentos',
  'qualidade', 'processos_operacionais', 'produtividade', 'comunicacao',
  'lideranca', 'dimensionamento_equipe', 'comportamento_conduta',
  'disciplina_operacional', 'atendimento_cliente', 'fornecedores',
  'materiais_insumos', 'estoque_armazenamento', 'transporte_logistica',
  'meio_ambiente', 'residuos_descartes', 'conformidade_legal', 'compliance',
  'auditoria_controles', 'financeiro_orcamento', 'planejamento',
  'continuidade_operacional', 'risco', 'incidente_ocorrencia', 'outros'
);

-- ============================================================
-- TABELAS AUXILIARES DO MÓDULO
-- ============================================================

CREATE TABLE public.module_colaborador_cargos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES public.usuarios(id) ON DELETE CASCADE,
  cargo_nome text NOT NULL,
  area_nome text NULL,
  descricao text NULL,
  ativo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.module_equipes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  descricao text NULL,
  criada_por_user_id uuid NOT NULL REFERENCES public.usuarios(id),
  escopo text NOT NULL CHECK (escopo IN ('global_admin', 'cost_center')),
  ativo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.module_equipe_cost_centers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  equipe_id uuid NOT NULL REFERENCES public.module_equipes(id) ON DELETE CASCADE,
  cost_center_id uuid NOT NULL REFERENCES public.cost_center(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (equipe_id, cost_center_id)
);

-- ============================================================
-- TEMPLATES DE CHECKLIST
-- ============================================================

CREATE TABLE public.checklist_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo text NOT NULL,
  descricao text NULL,
  observacao text NULL,
  criado_por_user_id uuid NOT NULL REFERENCES public.usuarios(id),
  cost_center_id uuid NOT NULL REFERENCES public.cost_center(id),
  local_id uuid NOT NULL REFERENCES public.cost_center_locais(id),
  equipe_responsavel_id uuid NOT NULL REFERENCES public.module_equipes(id),
  status public.checklist_template_status NOT NULL DEFAULT 'draft',
  recorrencia public.module_recurrence_type NOT NULL DEFAULT 'one_time',
  recorrencia_intervalo integer NOT NULL DEFAULT 1,
  inicia_em timestamptz NULL,
  encerra_em timestamptz NULL,
  prazo_padrao_horas integer NULL,
  exige_plano_acao boolean NOT NULL DEFAULT false,
  versao integer NOT NULL DEFAULT 1,
  ativo boolean NOT NULL DEFAULT true,
  proxima_geracao_em timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.checklist_template_tarefas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_template_id uuid NOT NULL REFERENCES public.checklist_templates(id) ON DELETE CASCADE,
  titulo text NOT NULL,
  descricao text NULL,
  ajuda text NULL,
  ordem integer NOT NULL,
  tipo_resposta public.checklist_task_response_type NOT NULL,
  obrigatoria boolean NOT NULL DEFAULT true,
  permite_comentario boolean NOT NULL DEFAULT true,
  permite_anexo boolean NOT NULL DEFAULT false,
  nota_min numeric(10,2) NULL,
  nota_max numeric(10,2) NULL,
  config_json jsonb NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- INSTÂNCIAS DE CHECKLIST
-- ============================================================

CREATE TABLE public.checklist_instancias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_template_id uuid NOT NULL REFERENCES public.checklist_templates(id),
  template_versao integer NOT NULL,
  titulo_snapshot text NOT NULL,
  descricao_snapshot text NULL,
  observacao_snapshot text NULL,
  criado_por_user_id uuid NOT NULL REFERENCES public.usuarios(id),
  cost_center_id uuid NOT NULL REFERENCES public.cost_center(id),
  local_id uuid NOT NULL REFERENCES public.cost_center_locais(id),
  equipe_responsavel_id uuid NOT NULL REFERENCES public.module_equipes(id),
  agendado_para timestamptz NULL,
  prazo_em timestamptz NULL,
  status public.checklist_instance_status NOT NULL DEFAULT 'open',
  exige_plano_acao boolean NOT NULL DEFAULT false,
  finalizado_por_user_id uuid NULL REFERENCES public.usuarios(id),
  finalizado_em timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.checklist_instancia_tarefas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_instancia_id uuid NOT NULL REFERENCES public.checklist_instancias(id) ON DELETE CASCADE,
  checklist_template_tarefa_id uuid NULL REFERENCES public.checklist_template_tarefas(id),
  titulo_snapshot text NOT NULL,
  descricao_snapshot text NULL,
  ajuda_snapshot text NULL,
  ordem integer NOT NULL,
  tipo_resposta_snapshot public.checklist_task_response_type NOT NULL,
  obrigatoria boolean NOT NULL,
  permite_comentario boolean NOT NULL,
  permite_anexo boolean NOT NULL,
  nota_min numeric(10,2) NULL,
  nota_max numeric(10,2) NULL,
  config_json_snapshot jsonb NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.checklist_tarefa_responsaveis (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_instancia_tarefa_id uuid NOT NULL REFERENCES public.checklist_instancia_tarefas(id) ON DELETE CASCADE,
  assigned_user_id uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  assigned_by_user_id uuid NOT NULL REFERENCES public.usuarios(id),
  status_kanban public.checklist_task_kanban_status NOT NULL DEFAULT 'pending',
  pode_alterar_status boolean NOT NULL DEFAULT true,
  ativo boolean NOT NULL DEFAULT true,
  atribuida_em timestamptz NOT NULL DEFAULT now(),
  concluida_em timestamptz NULL,
  UNIQUE (checklist_instancia_tarefa_id, assigned_user_id)
);

CREATE TABLE public.checklist_tarefa_respostas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_instancia_tarefa_id uuid NOT NULL REFERENCES public.checklist_instancia_tarefas(id) ON DELETE CASCADE,
  tarefa_responsavel_id uuid NOT NULL REFERENCES public.checklist_tarefa_responsaveis(id) ON DELETE CASCADE,
  respondido_por_user_id uuid NOT NULL REFERENCES public.usuarios(id),
  resposta_texto text NULL,
  resposta_numero numeric(12,2) NULL,
  resposta_boolean boolean NULL,
  resposta_data date NULL,
  resposta_datetime timestamptz NULL,
  resposta_json jsonb NULL,
  comentario_resposta text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.checklist_tarefa_status_historico (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_instancia_tarefa_id uuid NOT NULL REFERENCES public.checklist_instancia_tarefas(id) ON DELETE CASCADE,
  assigned_user_id uuid NOT NULL REFERENCES public.usuarios(id),
  changed_by_user_id uuid NOT NULL REFERENCES public.usuarios(id),
  status_anterior public.checklist_task_kanban_status NULL,
  status_novo public.checklist_task_kanban_status NOT NULL,
  motivo text NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- AVALIAÇÃO E FEEDBACK
-- ============================================================

CREATE TABLE public.checklist_avaliacoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_instancia_id uuid NOT NULL UNIQUE REFERENCES public.checklist_instancias(id) ON DELETE CASCADE,
  avaliado_por_user_id uuid NOT NULL REFERENCES public.usuarios(id),
  decisao public.checklist_review_decision NOT NULL,
  comentario_avaliacao text NULL,
  plano_acao_necessario boolean NOT NULL DEFAULT false,
  avaliado_em timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.checklist_avaliacao_itens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_avaliacao_id uuid NOT NULL REFERENCES public.checklist_avaliacoes(id) ON DELETE CASCADE,
  checklist_instancia_tarefa_id uuid NOT NULL REFERENCES public.checklist_instancia_tarefas(id) ON DELETE CASCADE,
  resultado_conformidade text NOT NULL CHECK (
    resultado_conformidade IN ('conforme', 'nao_conforme', 'nao_aplicavel')
  ),
  nota numeric(12,2) NULL,
  feedback text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (checklist_avaliacao_id, checklist_instancia_tarefa_id)
);

CREATE TABLE public.checklist_feedbacks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_instancia_tarefa_id uuid NOT NULL REFERENCES public.checklist_instancia_tarefas(id) ON DELETE CASCADE,
  checklist_avaliacao_item_id uuid NULL REFERENCES public.checklist_avaliacao_itens(id) ON DELETE SET NULL,
  autor_user_id uuid NOT NULL REFERENCES public.usuarios(id),
  destinatario_user_id uuid NOT NULL REFERENCES public.usuarios(id),
  mensagem text NOT NULL,
  ciente boolean NOT NULL DEFAULT false,
  ciente_em timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- PLANO DE AÇÃO
-- ============================================================

CREATE TABLE public.planos_acao (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_instancia_id uuid NOT NULL UNIQUE REFERENCES public.checklist_instancias(id) ON DELETE CASCADE,
  checklist_avaliacao_id uuid NOT NULL REFERENCES public.checklist_avaliacoes(id) ON DELETE CASCADE,
  equipe_responsavel_id uuid NOT NULL REFERENCES public.module_equipes(id),
  nao_conformidades_resumo text NOT NULL,
  classe_nao_conformidade public.action_plan_nonconformity_class NOT NULL,
  acao_proposta text NOT NULL,
  prazo_em timestamptz NOT NULL,
  status public.action_plan_status NOT NULL DEFAULT 'open',
  criado_por_user_id uuid NOT NULL REFERENCES public.usuarios(id),
  finalizado_por_user_id uuid NULL REFERENCES public.usuarios(id),
  finalizado_em timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.plano_acao_responsaveis (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plano_acao_id uuid NOT NULL REFERENCES public.planos_acao(id) ON DELETE CASCADE,
  assigned_user_id uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  assigned_by_user_id uuid NOT NULL REFERENCES public.usuarios(id),
  ativo boolean NOT NULL DEFAULT true,
  atribuido_em timestamptz NOT NULL DEFAULT now(),
  UNIQUE (plano_acao_id, assigned_user_id)
);

CREATE TABLE public.plano_acao_atualizacoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plano_acao_id uuid NOT NULL REFERENCES public.planos_acao(id) ON DELETE CASCADE,
  autor_user_id uuid NOT NULL REFERENCES public.usuarios(id),
  status_anterior public.action_plan_status NULL,
  status_novo public.action_plan_status NULL,
  comentario text NULL,
  progresso_percentual numeric(5,2) NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- AUDITORIA
-- ============================================================

CREATE TABLE public.module_audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_name text NOT NULL,
  entity_id uuid NOT NULL,
  action_name text NOT NULL,
  actor_user_id uuid NULL REFERENCES public.usuarios(id),
  old_data jsonb NULL,
  new_data jsonb NULL,
  metadata jsonb NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- ÍNDICES
-- ============================================================

CREATE INDEX idx_module_colaborador_cargos_user_id ON public.module_colaborador_cargos(user_id);
CREATE INDEX idx_module_equipe_cost_centers_equipe ON public.module_equipe_cost_centers(equipe_id);
CREATE INDEX idx_module_equipe_cost_centers_cc ON public.module_equipe_cost_centers(cost_center_id);
CREATE INDEX idx_checklist_templates_cc ON public.checklist_templates(cost_center_id);
CREATE INDEX idx_checklist_templates_local ON public.checklist_templates(local_id);
CREATE INDEX idx_checklist_templates_proxima_geracao ON public.checklist_templates(proxima_geracao_em) WHERE status = 'published' AND ativo = true;
CREATE INDEX idx_checklist_instancias_status ON public.checklist_instancias(status);
CREATE INDEX idx_checklist_instancias_prazo ON public.checklist_instancias(prazo_em);
CREATE INDEX idx_checklist_instancias_template ON public.checklist_instancias(checklist_template_id);
CREATE INDEX idx_checklist_instancia_tarefas_instancia ON public.checklist_instancia_tarefas(checklist_instancia_id);
CREATE INDEX idx_checklist_tarefa_responsaveis_user ON public.checklist_tarefa_responsaveis(assigned_user_id);
CREATE INDEX idx_checklist_tarefa_responsaveis_status ON public.checklist_tarefa_responsaveis(status_kanban);
CREATE INDEX idx_checklist_tarefa_respostas_tarefa ON public.checklist_tarefa_respostas(checklist_instancia_tarefa_id);
CREATE INDEX idx_checklist_avaliacoes_instancia ON public.checklist_avaliacoes(checklist_instancia_id);
CREATE INDEX idx_planos_acao_status ON public.planos_acao(status);
CREATE INDEX idx_plano_acao_responsaveis_user ON public.plano_acao_responsaveis(assigned_user_id);
CREATE INDEX idx_module_audit_logs_entity ON public.module_audit_logs(entity_name, entity_id);

-- ============================================================
-- FUNÇÕES DE PERMISSÃO (SECURITY DEFINER)
-- ============================================================

-- Verifica se o usuário é admin interno
CREATE OR REPLACE FUNCTION public.module_is_admin(_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.internal_profiles
    WHERE user_id = _user_id AND nivel_acesso = 'admin'
  )
$$;

-- Verifica se o usuário é supervisor com acesso a um cost_center
CREATE OR REPLACE FUNCTION public.module_supervisor_has_cost_center(_user_id uuid, _cost_center_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.internal_profiles ip
    JOIN public.internal_profile_cost_centers ipcc ON ipcc.user_id = ip.user_id
    WHERE ip.user_id = _user_id
      AND ip.nivel_acesso = 'supervisor'
      AND ipcc.cost_center_id = _cost_center_id
  )
$$;

-- Verifica se o usuário é colaborador ativo no cost_center
CREATE OR REPLACE FUNCTION public.module_is_colaborador_in_cc(_user_id uuid, _cost_center_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.usuarios u
    JOIN public.colaborador_profiles cp ON cp.user_id = u.id
    WHERE u.id = _user_id
      AND u.role = 'colaborador'
      AND cp.ativo = true
      AND cp.cost_center_id = _cost_center_id
  )
$$;

-- Verifica se é perfil interno (não cliente_view) com acesso ao cost_center
CREATE OR REPLACE FUNCTION public.module_internal_in_cc(_user_id uuid, _cost_center_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.internal_profiles ip
    LEFT JOIN public.internal_profile_cost_centers ipcc
      ON ipcc.user_id = ip.user_id AND ipcc.cost_center_id = _cost_center_id
    WHERE ip.user_id = _user_id
      AND ip.nivel_acesso <> 'cliente_view'
      AND (ip.nivel_acesso = 'admin' OR ipcc.cost_center_id = _cost_center_id)
  )
$$;

-- Bloqueia cliente_view de qualquer acesso ao módulo
CREATE OR REPLACE FUNCTION public.module_user_allowed(_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT NOT EXISTS (
    SELECT 1 FROM public.internal_profiles
    WHERE user_id = _user_id AND nivel_acesso = 'cliente_view'
  )
$$;

-- Pode criar/editar templates: admin global, ou supervisor do cost_center
CREATE OR REPLACE FUNCTION public.can_create_checklist_template(_user_id uuid, _cost_center_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.module_is_admin(_user_id)
      OR public.module_supervisor_has_cost_center(_user_id, _cost_center_id)
$$;

-- Pode atribuir tarefa a colaborador: deve ser colaborador ativo do mesmo cost_center
CREATE OR REPLACE FUNCTION public.can_assign_checklist_task(_assigned_user_id uuid, _cost_center_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.module_is_colaborador_in_cc(_assigned_user_id, _cost_center_id)
$$;

-- Pode avaliar checklist: admin ou supervisor do cost_center
CREATE OR REPLACE FUNCTION public.can_review_checklist(_user_id uuid, _cost_center_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.module_is_admin(_user_id)
      OR public.module_supervisor_has_cost_center(_user_id, _cost_center_id)
$$;

-- Pode ser responsável por plano de ação: colaborador no cc, ou perfil interno (exceto cliente_view) no cc
CREATE OR REPLACE FUNCTION public.can_assign_action_plan_user(_assigned_user_id uuid, _cost_center_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.module_is_colaborador_in_cc(_assigned_user_id, _cost_center_id)
      OR public.module_internal_in_cc(_assigned_user_id, _cost_center_id)
$$;

-- Pode atualizar status do plano de ação: admin ou supervisor do cost_center
CREATE OR REPLACE FUNCTION public.can_update_action_plan_status(_user_id uuid, _cost_center_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.module_is_admin(_user_id)
      OR public.module_supervisor_has_cost_center(_user_id, _cost_center_id)
$$;

-- Verifica se usuário é responsável ativo por uma tarefa
CREATE OR REPLACE FUNCTION public.is_task_responsible(_user_id uuid, _instancia_tarefa_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.checklist_tarefa_responsaveis
    WHERE checklist_instancia_tarefa_id = _instancia_tarefa_id
      AND assigned_user_id = _user_id
      AND ativo = true
  )
$$;

-- ============================================================
-- TRIGGERS DE updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION public.module_set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_module_colaborador_cargos_updated BEFORE UPDATE ON public.module_colaborador_cargos FOR EACH ROW EXECUTE FUNCTION public.module_set_updated_at();
CREATE TRIGGER trg_module_equipes_updated BEFORE UPDATE ON public.module_equipes FOR EACH ROW EXECUTE FUNCTION public.module_set_updated_at();
CREATE TRIGGER trg_checklist_templates_updated BEFORE UPDATE ON public.checklist_templates FOR EACH ROW EXECUTE FUNCTION public.module_set_updated_at();
CREATE TRIGGER trg_checklist_template_tarefas_updated BEFORE UPDATE ON public.checklist_template_tarefas FOR EACH ROW EXECUTE FUNCTION public.module_set_updated_at();
CREATE TRIGGER trg_checklist_instancias_updated BEFORE UPDATE ON public.checklist_instancias FOR EACH ROW EXECUTE FUNCTION public.module_set_updated_at();
CREATE TRIGGER trg_checklist_tarefa_respostas_updated BEFORE UPDATE ON public.checklist_tarefa_respostas FOR EACH ROW EXECUTE FUNCTION public.module_set_updated_at();
CREATE TRIGGER trg_planos_acao_updated BEFORE UPDATE ON public.planos_acao FOR EACH ROW EXECUTE FUNCTION public.module_set_updated_at();

-- ============================================================
-- TRIGGER: snapshot automático de tarefas ao criar instância
-- ============================================================

CREATE OR REPLACE FUNCTION public.snapshot_template_tarefas()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.checklist_instancia_tarefas (
    checklist_instancia_id, checklist_template_tarefa_id,
    titulo_snapshot, descricao_snapshot, ajuda_snapshot, ordem,
    tipo_resposta_snapshot, obrigatoria, permite_comentario,
    permite_anexo, nota_min, nota_max, config_json_snapshot
  )
  SELECT
    NEW.id, t.id, t.titulo, t.descricao, t.ajuda, t.ordem,
    t.tipo_resposta, t.obrigatoria, t.permite_comentario,
    t.permite_anexo, t.nota_min, t.nota_max, t.config_json
  FROM public.checklist_template_tarefas t
  WHERE t.checklist_template_id = NEW.checklist_template_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_snapshot_template_tarefas
AFTER INSERT ON public.checklist_instancias
FOR EACH ROW EXECUTE FUNCTION public.snapshot_template_tarefas();

-- ============================================================
-- FUNÇÃO: calcula próxima execução conforme periodicidade (BR timezone)
-- Sempre alinhado: daily 00:00, weekly domingo 00:00, monthly dia 1 00:00
-- ============================================================

CREATE OR REPLACE FUNCTION public.calc_next_recurrence(
  _recurrence public.module_recurrence_type,
  _intervalo integer,
  _from timestamptz
) RETURNS timestamptz LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
  base_br timestamp;
  next_br timestamp;
  next_utc timestamptz;
BEGIN
  -- Trabalhamos em horário de Brasília
  base_br := (_from AT TIME ZONE 'America/Sao_Paulo');

  IF _recurrence = 'one_time' THEN
    RETURN NULL;
  ELSIF _recurrence = 'daily' THEN
    -- Próxima meia-noite BR (ou daqui a N dias se já passou)
    next_br := date_trunc('day', base_br) + (COALESCE(_intervalo,1) || ' days')::interval;
  ELSIF _recurrence = 'weekly' THEN
    -- Próximo domingo 00:00 BR
    next_br := date_trunc('day', base_br)
      + ((7 - EXTRACT(DOW FROM base_br)::int) % 7 || ' days')::interval;
    IF next_br <= base_br THEN
      next_br := next_br + (7 * COALESCE(_intervalo,1) || ' days')::interval;
    END IF;
  ELSIF _recurrence = 'biweekly' THEN
    next_br := date_trunc('day', base_br)
      + ((7 - EXTRACT(DOW FROM base_br)::int) % 7 || ' days')::interval;
    IF next_br <= base_br THEN
      next_br := next_br + '14 days'::interval;
    END IF;
  ELSIF _recurrence = 'monthly' THEN
    -- Dia 1 do próximo mês 00:00 BR
    next_br := date_trunc('month', base_br) + (COALESCE(_intervalo,1) || ' months')::interval;
  ELSIF _recurrence = 'quarterly' THEN
    next_br := date_trunc('month', base_br) + '3 months'::interval;
    -- Alinha ao próximo dia 1 do mês
    next_br := date_trunc('month', next_br);
  ELSIF _recurrence = 'semiannual' THEN
    next_br := date_trunc('month', base_br) + '6 months'::interval;
    next_br := date_trunc('month', next_br);
  ELSIF _recurrence = 'annual' THEN
    next_br := date_trunc('year', base_br) + (COALESCE(_intervalo,1) || ' years')::interval;
  ELSE
    RETURN NULL;
  END IF;

  -- Converte de volta para UTC
  next_utc := next_br AT TIME ZONE 'America/Sao_Paulo';
  RETURN next_utc;
END;
$$;

-- ============================================================
-- TRIGGER: atualiza proxima_geracao_em quando recorrência muda
-- e cancela instâncias futuras 'scheduled' se a regra muda
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_template_recurrence_change()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  -- Recalcula proxima_geracao_em quando publicado pela primeira vez
  -- ou quando recorrência/intervalo mudam
  IF (TG_OP = 'INSERT' AND NEW.status = 'published') THEN
    NEW.proxima_geracao_em := public.calc_next_recurrence(
      NEW.recorrencia, NEW.recorrencia_intervalo,
      COALESCE(NEW.inicia_em, now())
    );
  ELSIF (TG_OP = 'UPDATE') THEN
    IF NEW.status = 'published' AND OLD.status <> 'published' THEN
      NEW.proxima_geracao_em := public.calc_next_recurrence(
        NEW.recorrencia, NEW.recorrencia_intervalo,
        COALESCE(NEW.inicia_em, now())
      );
    ELSIF (NEW.recorrencia <> OLD.recorrencia
           OR NEW.recorrencia_intervalo <> OLD.recorrencia_intervalo)
          AND NEW.status = 'published' THEN
      NEW.proxima_geracao_em := public.calc_next_recurrence(
        NEW.recorrencia, NEW.recorrencia_intervalo, now()
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_template_recurrence_change
BEFORE INSERT OR UPDATE ON public.checklist_templates
FOR EACH ROW EXECUTE FUNCTION public.handle_template_recurrence_change();

-- Trigger AFTER UPDATE: cancela instâncias futuras 'scheduled' quando recorrência muda
CREATE OR REPLACE FUNCTION public.cancel_scheduled_on_recurrence_change()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF (NEW.recorrencia <> OLD.recorrencia
      OR NEW.recorrencia_intervalo <> OLD.recorrencia_intervalo) THEN
    UPDATE public.checklist_instancias
    SET status = 'cancelled', updated_at = now()
    WHERE checklist_template_id = NEW.id
      AND status = 'scheduled'
      AND COALESCE(agendado_para, created_at) > now();
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_cancel_scheduled_on_recurrence_change
AFTER UPDATE ON public.checklist_templates
FOR EACH ROW
WHEN (OLD.recorrencia IS DISTINCT FROM NEW.recorrencia
   OR OLD.recorrencia_intervalo IS DISTINCT FROM NEW.recorrencia_intervalo)
EXECUTE FUNCTION public.cancel_scheduled_on_recurrence_change();

-- ============================================================
-- FUNÇÃO: gera instâncias devidas (chamada pelo cron)
-- ============================================================

CREATE OR REPLACE FUNCTION public.generate_due_checklist_instances()
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  tpl RECORD;
  new_instance_id uuid;
  total integer := 0;
BEGIN
  FOR tpl IN
    SELECT *
    FROM public.checklist_templates
    WHERE status = 'published'
      AND ativo = true
      AND recorrencia <> 'one_time'
      AND proxima_geracao_em IS NOT NULL
      AND proxima_geracao_em <= now()
      AND (encerra_em IS NULL OR encerra_em > now())
  LOOP
    INSERT INTO public.checklist_instancias (
      checklist_template_id, template_versao,
      titulo_snapshot, descricao_snapshot, observacao_snapshot,
      criado_por_user_id, cost_center_id, local_id, equipe_responsavel_id,
      agendado_para, prazo_em, status, exige_plano_acao
    ) VALUES (
      tpl.id, tpl.versao,
      tpl.titulo, tpl.descricao, tpl.observacao,
      tpl.criado_por_user_id, tpl.cost_center_id, tpl.local_id, tpl.equipe_responsavel_id,
      tpl.proxima_geracao_em,
      CASE WHEN tpl.prazo_padrao_horas IS NOT NULL
           THEN tpl.proxima_geracao_em + (tpl.prazo_padrao_horas || ' hours')::interval
           ELSE NULL END,
      'open', tpl.exige_plano_acao
    ) RETURNING id INTO new_instance_id;

    -- Avança a próxima geração
    UPDATE public.checklist_templates
    SET proxima_geracao_em = public.calc_next_recurrence(
      tpl.recorrencia, tpl.recorrencia_intervalo, tpl.proxima_geracao_em
    )
    WHERE id = tpl.id;

    total := total + 1;
  END LOOP;
  RETURN total;
END;
$$;

-- ============================================================
-- pg_cron: roda a cada hora (timezone do banco; a função usa BR timezone)
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule(
  'generate-checklist-instances-hourly',
  '0 * * * *',
  $$ SELECT public.generate_due_checklist_instances(); $$
);

-- ============================================================
-- ENABLE RLS EM TODAS AS TABELAS DO MÓDULO
-- ============================================================

ALTER TABLE public.module_colaborador_cargos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.module_equipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.module_equipe_cost_centers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_template_tarefas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_instancias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_instancia_tarefas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_tarefa_responsaveis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_tarefa_respostas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_tarefa_status_historico ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_avaliacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_avaliacao_itens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_feedbacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.planos_acao ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plano_acao_responsaveis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plano_acao_atualizacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.module_audit_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- POLÍTICAS RLS
-- Regra geral: cliente_view bloqueado em todas as tabelas
-- ============================================================

-- module_colaborador_cargos
CREATE POLICY "cargos_select" ON public.module_colaborador_cargos FOR SELECT TO authenticated
USING (public.module_user_allowed(auth.uid()) AND (public.module_is_admin(auth.uid()) OR user_id = auth.uid() OR is_internal_user()));
CREATE POLICY "cargos_insert" ON public.module_colaborador_cargos FOR INSERT TO authenticated
WITH CHECK (public.module_is_admin(auth.uid()));
CREATE POLICY "cargos_update" ON public.module_colaborador_cargos FOR UPDATE TO authenticated
USING (public.module_is_admin(auth.uid())) WITH CHECK (public.module_is_admin(auth.uid()));
CREATE POLICY "cargos_delete" ON public.module_colaborador_cargos FOR DELETE TO authenticated
USING (public.module_is_admin(auth.uid()));

-- module_equipes
CREATE POLICY "equipes_select" ON public.module_equipes FOR SELECT TO authenticated
USING (public.module_user_allowed(auth.uid()));
CREATE POLICY "equipes_insert" ON public.module_equipes FOR INSERT TO authenticated
WITH CHECK (public.module_user_allowed(auth.uid()) AND (public.module_is_admin(auth.uid()) OR (escopo = 'cost_center' AND criada_por_user_id = auth.uid())));
CREATE POLICY "equipes_update" ON public.module_equipes FOR UPDATE TO authenticated
USING (public.module_is_admin(auth.uid()) OR criada_por_user_id = auth.uid())
WITH CHECK (public.module_is_admin(auth.uid()) OR criada_por_user_id = auth.uid());
CREATE POLICY "equipes_delete" ON public.module_equipes FOR DELETE TO authenticated
USING (public.module_is_admin(auth.uid()));

-- module_equipe_cost_centers
CREATE POLICY "equipe_cc_select" ON public.module_equipe_cost_centers FOR SELECT TO authenticated
USING (public.module_user_allowed(auth.uid()));
CREATE POLICY "equipe_cc_insert" ON public.module_equipe_cost_centers FOR INSERT TO authenticated
WITH CHECK (public.module_is_admin(auth.uid()) OR public.module_supervisor_has_cost_center(auth.uid(), cost_center_id));
CREATE POLICY "equipe_cc_delete" ON public.module_equipe_cost_centers FOR DELETE TO authenticated
USING (public.module_is_admin(auth.uid()) OR public.module_supervisor_has_cost_center(auth.uid(), cost_center_id));

-- checklist_templates
CREATE POLICY "tpl_select" ON public.checklist_templates FOR SELECT TO authenticated
USING (public.module_user_allowed(auth.uid()) AND (
  public.module_is_admin(auth.uid())
  OR public.module_supervisor_has_cost_center(auth.uid(), cost_center_id)
  OR public.module_is_colaborador_in_cc(auth.uid(), cost_center_id)
));
CREATE POLICY "tpl_insert" ON public.checklist_templates FOR INSERT TO authenticated
WITH CHECK (public.can_create_checklist_template(auth.uid(), cost_center_id) AND criado_por_user_id = auth.uid());
CREATE POLICY "tpl_update" ON public.checklist_templates FOR UPDATE TO authenticated
USING (public.can_create_checklist_template(auth.uid(), cost_center_id))
WITH CHECK (public.can_create_checklist_template(auth.uid(), cost_center_id));
CREATE POLICY "tpl_delete" ON public.checklist_templates FOR DELETE TO authenticated
USING (public.module_is_admin(auth.uid()));

-- checklist_template_tarefas
CREATE POLICY "tpl_tarefas_select" ON public.checklist_template_tarefas FOR SELECT TO authenticated
USING (public.module_user_allowed(auth.uid()) AND EXISTS (
  SELECT 1 FROM public.checklist_templates t WHERE t.id = checklist_template_id AND (
    public.module_is_admin(auth.uid())
    OR public.module_supervisor_has_cost_center(auth.uid(), t.cost_center_id)
    OR public.module_is_colaborador_in_cc(auth.uid(), t.cost_center_id)
  )
));
CREATE POLICY "tpl_tarefas_modify" ON public.checklist_template_tarefas FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.checklist_templates t WHERE t.id = checklist_template_id AND public.can_create_checklist_template(auth.uid(), t.cost_center_id)))
WITH CHECK (EXISTS (SELECT 1 FROM public.checklist_templates t WHERE t.id = checklist_template_id AND public.can_create_checklist_template(auth.uid(), t.cost_center_id)));

-- checklist_instancias
CREATE POLICY "inst_select" ON public.checklist_instancias FOR SELECT TO authenticated
USING (public.module_user_allowed(auth.uid()) AND (
  public.module_is_admin(auth.uid())
  OR public.module_supervisor_has_cost_center(auth.uid(), cost_center_id)
  OR public.module_is_colaborador_in_cc(auth.uid(), cost_center_id)
));
CREATE POLICY "inst_insert" ON public.checklist_instancias FOR INSERT TO authenticated
WITH CHECK (public.can_create_checklist_template(auth.uid(), cost_center_id));
CREATE POLICY "inst_update" ON public.checklist_instancias FOR UPDATE TO authenticated
USING (public.module_is_admin(auth.uid()) OR public.module_supervisor_has_cost_center(auth.uid(), cost_center_id))
WITH CHECK (public.module_is_admin(auth.uid()) OR public.module_supervisor_has_cost_center(auth.uid(), cost_center_id));
CREATE POLICY "inst_delete" ON public.checklist_instancias FOR DELETE TO authenticated
USING (public.module_is_admin(auth.uid()));

-- checklist_instancia_tarefas (snapshots, criadas via trigger; admin/supervisor lê tudo, colaborador lê suas)
CREATE POLICY "inst_tarefas_select" ON public.checklist_instancia_tarefas FOR SELECT TO authenticated
USING (public.module_user_allowed(auth.uid()) AND EXISTS (
  SELECT 1 FROM public.checklist_instancias i WHERE i.id = checklist_instancia_id AND (
    public.module_is_admin(auth.uid())
    OR public.module_supervisor_has_cost_center(auth.uid(), i.cost_center_id)
    OR public.is_task_responsible(auth.uid(), checklist_instancia_tarefas.id)
  )
));

-- checklist_tarefa_responsaveis
CREATE POLICY "responsaveis_select" ON public.checklist_tarefa_responsaveis FOR SELECT TO authenticated
USING (public.module_user_allowed(auth.uid()) AND (
  assigned_user_id = auth.uid()
  OR EXISTS (SELECT 1 FROM public.checklist_instancia_tarefas t
             JOIN public.checklist_instancias i ON i.id = t.checklist_instancia_id
             WHERE t.id = checklist_instancia_tarefa_id AND (
               public.module_is_admin(auth.uid())
               OR public.module_supervisor_has_cost_center(auth.uid(), i.cost_center_id)
             ))
));
CREATE POLICY "responsaveis_insert" ON public.checklist_tarefa_responsaveis FOR INSERT TO authenticated
WITH CHECK (
  assigned_by_user_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.checklist_instancia_tarefas t
    JOIN public.checklist_instancias i ON i.id = t.checklist_instancia_id
    WHERE t.id = checklist_instancia_tarefa_id
      AND (public.module_is_admin(auth.uid()) OR public.module_supervisor_has_cost_center(auth.uid(), i.cost_center_id))
      AND public.can_assign_checklist_task(assigned_user_id, i.cost_center_id)
  )
);
CREATE POLICY "responsaveis_update" ON public.checklist_tarefa_responsaveis FOR UPDATE TO authenticated
USING (
  -- colaborador só atualiza seu kanban se instância estiver open/in_progress
  (assigned_user_id = auth.uid() AND pode_alterar_status = true AND EXISTS (
    SELECT 1 FROM public.checklist_instancia_tarefas t
    JOIN public.checklist_instancias i ON i.id = t.checklist_instancia_id
    WHERE t.id = checklist_instancia_tarefa_id AND i.status IN ('open','in_progress')
  ))
  OR EXISTS (
    SELECT 1 FROM public.checklist_instancia_tarefas t
    JOIN public.checklist_instancias i ON i.id = t.checklist_instancia_id
    WHERE t.id = checklist_instancia_tarefa_id
      AND (public.module_is_admin(auth.uid()) OR public.module_supervisor_has_cost_center(auth.uid(), i.cost_center_id))
  )
);
CREATE POLICY "responsaveis_delete" ON public.checklist_tarefa_responsaveis FOR DELETE TO authenticated
USING (EXISTS (
  SELECT 1 FROM public.checklist_instancia_tarefas t
  JOIN public.checklist_instancias i ON i.id = t.checklist_instancia_id
  WHERE t.id = checklist_instancia_tarefa_id
    AND (public.module_is_admin(auth.uid()) OR public.module_supervisor_has_cost_center(auth.uid(), i.cost_center_id))
));

-- checklist_tarefa_respostas
CREATE POLICY "respostas_select" ON public.checklist_tarefa_respostas FOR SELECT TO authenticated
USING (public.module_user_allowed(auth.uid()) AND (
  respondido_por_user_id = auth.uid()
  OR EXISTS (SELECT 1 FROM public.checklist_instancia_tarefas t
             JOIN public.checklist_instancias i ON i.id = t.checklist_instancia_id
             WHERE t.id = checklist_instancia_tarefa_id AND (
               public.module_is_admin(auth.uid())
               OR public.module_supervisor_has_cost_center(auth.uid(), i.cost_center_id)
             ))
));
CREATE POLICY "respostas_insert" ON public.checklist_tarefa_respostas FOR INSERT TO authenticated
WITH CHECK (
  respondido_por_user_id = auth.uid()
  AND public.is_task_responsible(auth.uid(), checklist_instancia_tarefa_id)
  AND EXISTS (
    SELECT 1 FROM public.checklist_instancia_tarefas t
    JOIN public.checklist_instancias i ON i.id = t.checklist_instancia_id
    WHERE t.id = checklist_instancia_tarefa_id AND i.status IN ('open','in_progress')
  )
);
CREATE POLICY "respostas_update" ON public.checklist_tarefa_respostas FOR UPDATE TO authenticated
USING (respondido_por_user_id = auth.uid() AND EXISTS (
  SELECT 1 FROM public.checklist_instancia_tarefas t
  JOIN public.checklist_instancias i ON i.id = t.checklist_instancia_id
  WHERE t.id = checklist_instancia_tarefa_id AND i.status IN ('open','in_progress')
))
WITH CHECK (respondido_por_user_id = auth.uid());

-- checklist_tarefa_status_historico (insert via trigger ou app; leitura ampla)
CREATE POLICY "status_hist_select" ON public.checklist_tarefa_status_historico FOR SELECT TO authenticated
USING (public.module_user_allowed(auth.uid()) AND EXISTS (
  SELECT 1 FROM public.checklist_instancia_tarefas t
  JOIN public.checklist_instancias i ON i.id = t.checklist_instancia_id
  WHERE t.id = checklist_instancia_tarefa_id AND (
    public.module_is_admin(auth.uid())
    OR public.module_supervisor_has_cost_center(auth.uid(), i.cost_center_id)
    OR assigned_user_id = auth.uid()
  )
));
CREATE POLICY "status_hist_insert" ON public.checklist_tarefa_status_historico FOR INSERT TO authenticated
WITH CHECK (changed_by_user_id = auth.uid());

-- checklist_avaliacoes
CREATE POLICY "aval_select" ON public.checklist_avaliacoes FOR SELECT TO authenticated
USING (public.module_user_allowed(auth.uid()) AND EXISTS (
  SELECT 1 FROM public.checklist_instancias i WHERE i.id = checklist_instancia_id AND (
    public.module_is_admin(auth.uid())
    OR public.module_supervisor_has_cost_center(auth.uid(), i.cost_center_id)
    OR public.module_is_colaborador_in_cc(auth.uid(), i.cost_center_id)
  )
));
CREATE POLICY "aval_insert" ON public.checklist_avaliacoes FOR INSERT TO authenticated
WITH CHECK (avaliado_por_user_id = auth.uid() AND EXISTS (
  SELECT 1 FROM public.checklist_instancias i WHERE i.id = checklist_instancia_id
    AND public.can_review_checklist(auth.uid(), i.cost_center_id)
));
CREATE POLICY "aval_update" ON public.checklist_avaliacoes FOR UPDATE TO authenticated
USING (EXISTS (SELECT 1 FROM public.checklist_instancias i WHERE i.id = checklist_instancia_id AND public.can_review_checklist(auth.uid(), i.cost_center_id)))
WITH CHECK (EXISTS (SELECT 1 FROM public.checklist_instancias i WHERE i.id = checklist_instancia_id AND public.can_review_checklist(auth.uid(), i.cost_center_id)));

-- checklist_avaliacao_itens
CREATE POLICY "aval_itens_select" ON public.checklist_avaliacao_itens FOR SELECT TO authenticated
USING (public.module_user_allowed(auth.uid()) AND EXISTS (
  SELECT 1 FROM public.checklist_avaliacoes a JOIN public.checklist_instancias i ON i.id = a.checklist_instancia_id
  WHERE a.id = checklist_avaliacao_id AND (
    public.module_is_admin(auth.uid())
    OR public.module_supervisor_has_cost_center(auth.uid(), i.cost_center_id)
    OR public.module_is_colaborador_in_cc(auth.uid(), i.cost_center_id)
  )
));
CREATE POLICY "aval_itens_modify" ON public.checklist_avaliacao_itens FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.checklist_avaliacoes a JOIN public.checklist_instancias i ON i.id = a.checklist_instancia_id
               WHERE a.id = checklist_avaliacao_id AND public.can_review_checklist(auth.uid(), i.cost_center_id)))
WITH CHECK (EXISTS (SELECT 1 FROM public.checklist_avaliacoes a JOIN public.checklist_instancias i ON i.id = a.checklist_instancia_id
                    WHERE a.id = checklist_avaliacao_id AND public.can_review_checklist(auth.uid(), i.cost_center_id)));

-- checklist_feedbacks
CREATE POLICY "feedback_select" ON public.checklist_feedbacks FOR SELECT TO authenticated
USING (public.module_user_allowed(auth.uid()) AND (
  destinatario_user_id = auth.uid() OR autor_user_id = auth.uid()
  OR EXISTS (SELECT 1 FROM public.checklist_instancia_tarefas t
             JOIN public.checklist_instancias i ON i.id = t.checklist_instancia_id
             WHERE t.id = checklist_instancia_tarefa_id AND (
               public.module_is_admin(auth.uid())
               OR public.module_supervisor_has_cost_center(auth.uid(), i.cost_center_id)
             ))
));
CREATE POLICY "feedback_insert" ON public.checklist_feedbacks FOR INSERT TO authenticated
WITH CHECK (autor_user_id = auth.uid() AND EXISTS (
  SELECT 1 FROM public.checklist_instancia_tarefas t
  JOIN public.checklist_instancias i ON i.id = t.checklist_instancia_id
  WHERE t.id = checklist_instancia_tarefa_id AND public.can_review_checklist(auth.uid(), i.cost_center_id)
));
CREATE POLICY "feedback_update_ciencia" ON public.checklist_feedbacks FOR UPDATE TO authenticated
USING (destinatario_user_id = auth.uid()) WITH CHECK (destinatario_user_id = auth.uid());

-- planos_acao
CREATE POLICY "plano_select" ON public.planos_acao FOR SELECT TO authenticated
USING (public.module_user_allowed(auth.uid()) AND EXISTS (
  SELECT 1 FROM public.checklist_instancias i WHERE i.id = checklist_instancia_id AND (
    public.module_is_admin(auth.uid())
    OR public.module_supervisor_has_cost_center(auth.uid(), i.cost_center_id)
    OR EXISTS (SELECT 1 FROM public.plano_acao_responsaveis r WHERE r.plano_acao_id = planos_acao.id AND r.assigned_user_id = auth.uid())
  )
));
CREATE POLICY "plano_insert" ON public.planos_acao FOR INSERT TO authenticated
WITH CHECK (criado_por_user_id = auth.uid() AND EXISTS (
  SELECT 1 FROM public.checklist_instancias i WHERE i.id = checklist_instancia_id
    AND public.can_review_checklist(auth.uid(), i.cost_center_id)
));
CREATE POLICY "plano_update" ON public.planos_acao FOR UPDATE TO authenticated
USING (EXISTS (SELECT 1 FROM public.checklist_instancias i WHERE i.id = checklist_instancia_id AND public.can_update_action_plan_status(auth.uid(), i.cost_center_id)))
WITH CHECK (EXISTS (SELECT 1 FROM public.checklist_instancias i WHERE i.id = checklist_instancia_id AND public.can_update_action_plan_status(auth.uid(), i.cost_center_id)));
CREATE POLICY "plano_delete" ON public.planos_acao FOR DELETE TO authenticated
USING (public.module_is_admin(auth.uid()));

-- plano_acao_responsaveis
CREATE POLICY "plano_resp_select" ON public.plano_acao_responsaveis FOR SELECT TO authenticated
USING (public.module_user_allowed(auth.uid()) AND (
  assigned_user_id = auth.uid()
  OR EXISTS (SELECT 1 FROM public.planos_acao p JOIN public.checklist_instancias i ON i.id = p.checklist_instancia_id
             WHERE p.id = plano_acao_id AND (
               public.module_is_admin(auth.uid())
               OR public.module_supervisor_has_cost_center(auth.uid(), i.cost_center_id)
             ))
));
CREATE POLICY "plano_resp_insert" ON public.plano_acao_responsaveis FOR INSERT TO authenticated
WITH CHECK (assigned_by_user_id = auth.uid() AND EXISTS (
  SELECT 1 FROM public.planos_acao p JOIN public.checklist_instancias i ON i.id = p.checklist_instancia_id
  WHERE p.id = plano_acao_id
    AND public.can_review_checklist(auth.uid(), i.cost_center_id)
    AND public.can_assign_action_plan_user(assigned_user_id, i.cost_center_id)
));
CREATE POLICY "plano_resp_delete" ON public.plano_acao_responsaveis FOR DELETE TO authenticated
USING (EXISTS (SELECT 1 FROM public.planos_acao p JOIN public.checklist_instancias i ON i.id = p.checklist_instancia_id
               WHERE p.id = plano_acao_id AND public.can_review_checklist(auth.uid(), i.cost_center_id)));

-- plano_acao_atualizacoes
CREATE POLICY "plano_atu_select" ON public.plano_acao_atualizacoes FOR SELECT TO authenticated
USING (public.module_user_allowed(auth.uid()) AND EXISTS (
  SELECT 1 FROM public.planos_acao p JOIN public.checklist_instancias i ON i.id = p.checklist_instancia_id
  WHERE p.id = plano_acao_id AND (
    public.module_is_admin(auth.uid())
    OR public.module_supervisor_has_cost_center(auth.uid(), i.cost_center_id)
    OR EXISTS (SELECT 1 FROM public.plano_acao_responsaveis r WHERE r.plano_acao_id = p.id AND r.assigned_user_id = auth.uid())
  )
));
CREATE POLICY "plano_atu_insert" ON public.plano_acao_atualizacoes FOR INSERT TO authenticated
WITH CHECK (autor_user_id = auth.uid() AND EXISTS (
  SELECT 1 FROM public.planos_acao p JOIN public.checklist_instancias i ON i.id = p.checklist_instancia_id
  WHERE p.id = plano_acao_id AND (
    public.can_update_action_plan_status(auth.uid(), i.cost_center_id)
    OR EXISTS (SELECT 1 FROM public.plano_acao_responsaveis r WHERE r.plano_acao_id = p.id AND r.assigned_user_id = auth.uid() AND r.ativo = true)
  )
));

-- module_audit_logs (somente admin)
CREATE POLICY "audit_select_admin" ON public.module_audit_logs FOR SELECT TO authenticated
USING (public.module_is_admin(auth.uid()));
CREATE POLICY "audit_insert" ON public.module_audit_logs FOR INSERT TO authenticated
WITH CHECK (true);