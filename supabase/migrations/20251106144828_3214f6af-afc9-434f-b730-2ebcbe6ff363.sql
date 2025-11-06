-- ============================================
-- FACILITIES CENTER - DATABASE SCHEMA
-- ============================================

-- Enum para roles (já existe, mas garantindo)
-- CREATE TYPE IF NOT EXISTS app_role AS ENUM ('admin', 'gestor_operacoes', 'supervisor', 'analista_centro_controle', 'tecnico', 'cliente_view');

-- ============================================
-- TABELA: clientes
-- ============================================
CREATE TABLE IF NOT EXISTS public.clientes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  razao_social TEXT NOT NULL,
  cnpj TEXT UNIQUE NOT NULL,
  contato_nome TEXT,
  contato_email TEXT,
  contato_telefone TEXT,
  status TEXT DEFAULT 'ativo' CHECK (status IN ('ativo', 'inativo')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELA: contratos
-- ============================================
CREATE TABLE IF NOT EXISTS public.contratos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id UUID REFERENCES public.clientes(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  codigo TEXT UNIQUE NOT NULL,
  data_inicio DATE NOT NULL,
  data_fim DATE,
  sla_alvo_pct DECIMAL(5,2) DEFAULT 95.00,
  nps_meta DECIMAL(5,2),
  status TEXT DEFAULT 'ativo' CHECK (status IN ('ativo', 'inativo', 'suspenso')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELA: unidades
-- ============================================
CREATE TABLE IF NOT EXISTS public.unidades (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contrato_id UUID REFERENCES public.contratos(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  codigo TEXT UNIQUE NOT NULL,
  endereco TEXT,
  cidade TEXT,
  uf TEXT,
  cep TEXT,
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  criticidade TEXT DEFAULT 'media' CHECK (criticidade IN ('baixa', 'media', 'alta', 'critica')),
  status TEXT DEFAULT 'ativo' CHECK (status IN ('ativo', 'inativo')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELA: postos_servico
-- ============================================
CREATE TABLE IF NOT EXISTS public.postos_servico (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unidade_id UUID REFERENCES public.unidades(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  codigo TEXT UNIQUE NOT NULL,
  funcao TEXT NOT NULL,
  escala TEXT,
  turno TEXT,
  jornada TEXT,
  horario_inicio TIME,
  horario_fim TIME,
  intervalo_refeicao INTEGER, -- minutos
  efetivo_planejado INTEGER DEFAULT 1,
  dias_semana TEXT[], -- array de dias: ['seg', 'ter', 'qua', 'qui', 'sex', 'sab', 'dom']
  status TEXT DEFAULT 'ativo' CHECK (status IN ('ativo', 'inativo', 'vago')),
  observacoes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELA: cargos
-- ============================================
CREATE TABLE IF NOT EXISTS public.cargos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL UNIQUE,
  descricao TEXT,
  is_lideranca BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELA: escalas
-- ============================================
CREATE TABLE IF NOT EXISTS public.escalas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  tipo TEXT NOT NULL CHECK (tipo IN ('12x36', '6x1', '5x2', 'administrativa', 'personalizada')),
  dias_trabalhados INTEGER,
  dias_folga INTEGER,
  descricao TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELA: colaboradores
-- ============================================
CREATE TABLE IF NOT EXISTS public.colaboradores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome_completo TEXT NOT NULL,
  cpf TEXT UNIQUE NOT NULL,
  email TEXT,
  telefone TEXT,
  cargo_id UUID REFERENCES public.cargos(id),
  unidade_id UUID REFERENCES public.unidades(id),
  posto_servico_id UUID REFERENCES public.postos_servico(id),
  escala_id UUID REFERENCES public.escalas(id),
  data_admissao DATE,
  data_desligamento DATE,
  status TEXT DEFAULT 'ativo' CHECK (status IN ('ativo', 'inativo', 'ferias', 'afastado')),
  observacoes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELA: ordens_servico
-- ============================================
CREATE TABLE IF NOT EXISTS public.ordens_servico (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero TEXT UNIQUE NOT NULL,
  unidade_id UUID REFERENCES public.unidades(id),
  tipo TEXT NOT NULL CHECK (tipo IN ('corretiva', 'preventiva', 'emergencial', 'melhoria')),
  prioridade TEXT DEFAULT 'media' CHECK (prioridade IN ('baixa', 'media', 'alta', 'urgente')),
  titulo TEXT NOT NULL,
  descricao TEXT,
  solicitante_id UUID REFERENCES auth.users(id),
  responsavel_id UUID REFERENCES public.colaboradores(id),
  data_abertura TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_prevista DATE,
  data_conclusao TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'aberta' CHECK (status IN ('aberta', 'em_andamento', 'pausada', 'concluida', 'cancelada')),
  observacoes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELA: incidentes
-- ============================================
CREATE TABLE IF NOT EXISTS public.incidentes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero TEXT UNIQUE NOT NULL,
  unidade_id UUID REFERENCES public.unidades(id),
  severidade TEXT NOT NULL CHECK (severidade IN ('baixa', 'media', 'alta', 'critica')),
  titulo TEXT NOT NULL,
  descricao TEXT,
  categoria TEXT,
  reportado_por_id UUID REFERENCES auth.users(id),
  responsavel_id UUID REFERENCES public.colaboradores(id),
  data_ocorrencia TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_resolucao TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'aberto' CHECK (status IN ('aberto', 'em_investigacao', 'resolvido', 'fechado')),
  impacto TEXT,
  acao_tomada TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELA: checklists
-- ============================================
CREATE TABLE IF NOT EXISTS public.checklists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  descricao TEXT,
  tipo TEXT CHECK (tipo IN ('diario', 'semanal', 'mensal', 'pontual')),
  unidade_id UUID REFERENCES public.unidades(id),
  status TEXT DEFAULT 'ativo' CHECK (status IN ('ativo', 'inativo')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELA: checklist_itens
-- ============================================
CREATE TABLE IF NOT EXISTS public.checklist_itens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_id UUID REFERENCES public.checklists(id) ON DELETE CASCADE,
  ordem INTEGER NOT NULL,
  descricao TEXT NOT NULL,
  tipo_resposta TEXT DEFAULT 'sim_nao' CHECK (tipo_resposta IN ('sim_nao', 'texto', 'numero', 'foto')),
  obrigatorio BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELA: checklist_execucoes
-- ============================================
CREATE TABLE IF NOT EXISTS public.checklist_execucoes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_id UUID REFERENCES public.checklists(id),
  colaborador_id UUID REFERENCES public.colaboradores(id),
  data_execucao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status TEXT DEFAULT 'em_andamento' CHECK (status IN ('em_andamento', 'concluido')),
  observacoes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELA: checklist_respostas
-- ============================================
CREATE TABLE IF NOT EXISTS public.checklist_respostas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  execucao_id UUID REFERENCES public.checklist_execucoes(id) ON DELETE CASCADE,
  item_id UUID REFERENCES public.checklist_itens(id),
  resposta TEXT,
  conforme BOOLEAN,
  foto_url TEXT,
  observacao TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELA: recursos_materiais
-- ============================================
CREATE TABLE IF NOT EXISTS public.recursos_materiais (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  tipo TEXT CHECK (tipo IN ('equipamento', 'ferramenta', 'material', 'epi')),
  unidade_id UUID REFERENCES public.unidades(id),
  quantidade INTEGER DEFAULT 0,
  quantidade_minima INTEGER DEFAULT 0,
  status TEXT DEFAULT 'disponivel' CHECK (status IN ('disponivel', 'em_uso', 'manutencao', 'indisponivel')),
  observacoes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELA: chamados
-- ============================================
CREATE TABLE IF NOT EXISTS public.chamados (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero TEXT UNIQUE NOT NULL,
  unidade_id UUID REFERENCES public.unidades(id),
  tipo TEXT NOT NULL,
  prioridade TEXT DEFAULT 'media' CHECK (prioridade IN ('baixa', 'media', 'alta', 'urgente')),
  titulo TEXT NOT NULL,
  descricao TEXT,
  solicitante_id UUID REFERENCES auth.users(id),
  responsavel_id UUID REFERENCES public.colaboradores(id),
  data_abertura TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_conclusao TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'aberto' CHECK (status IN ('aberto', 'em_atendimento', 'resolvido', 'fechado', 'cancelado')),
  avaliacao INTEGER CHECK (avaliacao >= 1 AND avaliacao <= 5),
  comentario_avaliacao TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- INDICES PARA PERFORMANCE
-- ============================================
CREATE INDEX IF NOT EXISTS idx_contratos_cliente ON public.contratos(cliente_id);
CREATE INDEX IF NOT EXISTS idx_unidades_contrato ON public.unidades(contrato_id);
CREATE INDEX IF NOT EXISTS idx_postos_unidade ON public.postos_servico(unidade_id);
CREATE INDEX IF NOT EXISTS idx_colaboradores_unidade ON public.colaboradores(unidade_id);
CREATE INDEX IF NOT EXISTS idx_colaboradores_posto ON public.colaboradores(posto_servico_id);
CREATE INDEX IF NOT EXISTS idx_os_unidade ON public.ordens_servico(unidade_id);
CREATE INDEX IF NOT EXISTS idx_os_status ON public.ordens_servico(status);
CREATE INDEX IF NOT EXISTS idx_incidentes_unidade ON public.incidentes(unidade_id);
CREATE INDEX IF NOT EXISTS idx_incidentes_status ON public.incidentes(status);
CREATE INDEX IF NOT EXISTS idx_chamados_unidade ON public.chamados(unidade_id);
CREATE INDEX IF NOT EXISTS idx_chamados_status ON public.chamados(status);

-- ============================================
-- TRIGGERS PARA UPDATED_AT
-- ============================================
CREATE TRIGGER update_clientes_updated_at BEFORE UPDATE ON public.clientes
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_contratos_updated_at BEFORE UPDATE ON public.contratos
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_unidades_updated_at BEFORE UPDATE ON public.unidades
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_postos_servico_updated_at BEFORE UPDATE ON public.postos_servico
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_cargos_updated_at BEFORE UPDATE ON public.cargos
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_escalas_updated_at BEFORE UPDATE ON public.escalas
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_colaboradores_updated_at BEFORE UPDATE ON public.colaboradores
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_ordens_servico_updated_at BEFORE UPDATE ON public.ordens_servico
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_incidentes_updated_at BEFORE UPDATE ON public.incidentes
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_recursos_materiais_updated_at BEFORE UPDATE ON public.recursos_materiais
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_chamados_updated_at BEFORE UPDATE ON public.chamados
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- RLS POLICIES
-- ============================================

-- Habilitar RLS em todas as tabelas
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contratos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.unidades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.postos_servico ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cargos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escalas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.colaboradores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ordens_servico ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incidentes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_itens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_execucoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_respostas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recursos_materiais ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chamados ENABLE ROW LEVEL SECURITY;

-- Policies para CLIENTES
CREATE POLICY "Usuarios autenticados podem ler clientes" ON public.clientes FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins e gestores podem inserir clientes" ON public.clientes FOR INSERT TO authenticated WITH CHECK (
  public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'gestor_operacoes')
);
CREATE POLICY "Admins e gestores podem atualizar clientes" ON public.clientes FOR UPDATE TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'gestor_operacoes')
);
CREATE POLICY "Apenas admins podem deletar clientes" ON public.clientes FOR DELETE TO authenticated USING (
  public.has_role(auth.uid(), 'admin')
);

-- Policies para CONTRATOS
CREATE POLICY "Usuarios autenticados podem ler contratos" ON public.contratos FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins e gestores podem inserir contratos" ON public.contratos FOR INSERT TO authenticated WITH CHECK (
  public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'gestor_operacoes')
);
CREATE POLICY "Admins e gestores podem atualizar contratos" ON public.contratos FOR UPDATE TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'gestor_operacoes')
);
CREATE POLICY "Apenas admins podem deletar contratos" ON public.contratos FOR DELETE TO authenticated USING (
  public.has_role(auth.uid(), 'admin')
);

-- Policies para UNIDADES
CREATE POLICY "Usuarios autenticados podem ler unidades" ON public.unidades FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins e gestores podem inserir unidades" ON public.unidades FOR INSERT TO authenticated WITH CHECK (
  public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'gestor_operacoes')
);
CREATE POLICY "Admins e gestores podem atualizar unidades" ON public.unidades FOR UPDATE TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'gestor_operacoes')
);
CREATE POLICY "Apenas admins podem deletar unidades" ON public.unidades FOR DELETE TO authenticated USING (
  public.has_role(auth.uid(), 'admin')
);

-- Policies para POSTOS_SERVICO
CREATE POLICY "Usuarios autenticados podem ler postos" ON public.postos_servico FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins, gestores e supervisores podem inserir postos" ON public.postos_servico FOR INSERT TO authenticated WITH CHECK (
  public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'gestor_operacoes') OR public.has_role(auth.uid(), 'supervisor')
);
CREATE POLICY "Admins, gestores e supervisores podem atualizar postos" ON public.postos_servico FOR UPDATE TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'gestor_operacoes') OR public.has_role(auth.uid(), 'supervisor')
);
CREATE POLICY "Admins e gestores podem deletar postos" ON public.postos_servico FOR DELETE TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'gestor_operacoes')
);

-- Policies para CARGOS
CREATE POLICY "Usuarios autenticados podem ler cargos" ON public.cargos FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins e gestores podem gerenciar cargos" ON public.cargos FOR ALL TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'gestor_operacoes')
);

-- Policies para ESCALAS
CREATE POLICY "Usuarios autenticados podem ler escalas" ON public.escalas FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins e gestores podem gerenciar escalas" ON public.escalas FOR ALL TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'gestor_operacoes')
);

-- Policies para COLABORADORES
CREATE POLICY "Usuarios autenticados podem ler colaboradores" ON public.colaboradores FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins, gestores e supervisores podem inserir colaboradores" ON public.colaboradores FOR INSERT TO authenticated WITH CHECK (
  public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'gestor_operacoes') OR public.has_role(auth.uid(), 'supervisor')
);
CREATE POLICY "Admins, gestores e supervisores podem atualizar colaboradores" ON public.colaboradores FOR UPDATE TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'gestor_operacoes') OR public.has_role(auth.uid(), 'supervisor')
);
CREATE POLICY "Admins e gestores podem deletar colaboradores" ON public.colaboradores FOR DELETE TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'gestor_operacoes')
);

-- Policies para ORDENS_SERVICO
CREATE POLICY "Usuarios autenticados podem ler OS" ON public.ordens_servico FOR SELECT TO authenticated USING (true);
CREATE POLICY "Usuarios podem criar OS" ON public.ordens_servico FOR INSERT TO authenticated WITH CHECK (
  public.has_role(auth.uid(), 'admin') OR 
  public.has_role(auth.uid(), 'gestor_operacoes') OR 
  public.has_role(auth.uid(), 'supervisor') OR 
  public.has_role(auth.uid(), 'analista_centro_controle')
);
CREATE POLICY "Usuarios autorizados podem atualizar OS" ON public.ordens_servico FOR UPDATE TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR 
  public.has_role(auth.uid(), 'gestor_operacoes') OR 
  public.has_role(auth.uid(), 'supervisor')
);
CREATE POLICY "Usuarios autorizados podem deletar OS" ON public.ordens_servico FOR DELETE TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR 
  public.has_role(auth.uid(), 'gestor_operacoes') OR 
  public.has_role(auth.uid(), 'supervisor')
);

-- Policies para INCIDENTES
CREATE POLICY "Usuarios autenticados podem ler incidentes" ON public.incidentes FOR SELECT TO authenticated USING (true);
CREATE POLICY "Usuarios podem criar incidentes" ON public.incidentes FOR INSERT TO authenticated WITH CHECK (
  public.has_role(auth.uid(), 'admin') OR 
  public.has_role(auth.uid(), 'gestor_operacoes') OR 
  public.has_role(auth.uid(), 'supervisor') OR 
  public.has_role(auth.uid(), 'analista_centro_controle')
);
CREATE POLICY "Usuarios autorizados podem atualizar incidentes" ON public.incidentes FOR UPDATE TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR 
  public.has_role(auth.uid(), 'gestor_operacoes') OR 
  public.has_role(auth.uid(), 'supervisor')
);
CREATE POLICY "Usuarios autorizados podem deletar incidentes" ON public.incidentes FOR DELETE TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR 
  public.has_role(auth.uid(), 'gestor_operacoes') OR 
  public.has_role(auth.uid(), 'supervisor')
);

-- Policies para CHECKLISTS e relacionados
CREATE POLICY "Usuarios autenticados podem ler checklists" ON public.checklists FOR SELECT TO authenticated USING (true);
CREATE POLICY "Usuarios autorizados podem gerenciar checklists" ON public.checklists FOR ALL TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR 
  public.has_role(auth.uid(), 'gestor_operacoes') OR 
  public.has_role(auth.uid(), 'supervisor')
);

CREATE POLICY "Usuarios autenticados podem ler itens checklist" ON public.checklist_itens FOR SELECT TO authenticated USING (true);
CREATE POLICY "Usuarios autorizados podem gerenciar itens checklist" ON public.checklist_itens FOR ALL TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR 
  public.has_role(auth.uid(), 'gestor_operacoes') OR 
  public.has_role(auth.uid(), 'supervisor')
);

CREATE POLICY "Usuarios autenticados podem ler execucoes" ON public.checklist_execucoes FOR SELECT TO authenticated USING (true);
CREATE POLICY "Usuarios podem criar execucoes" ON public.checklist_execucoes FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Usuarios podem atualizar suas execucoes" ON public.checklist_execucoes FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Usuarios autenticados podem ler respostas" ON public.checklist_respostas FOR SELECT TO authenticated USING (true);
CREATE POLICY "Usuarios podem criar respostas" ON public.checklist_respostas FOR INSERT TO authenticated WITH CHECK (true);

-- Policies para RECURSOS_MATERIAIS
CREATE POLICY "Usuarios autenticados podem ler recursos" ON public.recursos_materiais FOR SELECT TO authenticated USING (true);
CREATE POLICY "Usuarios autorizados podem gerenciar recursos" ON public.recursos_materiais FOR ALL TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR 
  public.has_role(auth.uid(), 'gestor_operacoes') OR 
  public.has_role(auth.uid(), 'supervisor')
);

-- Policies para CHAMADOS
CREATE POLICY "Usuarios autenticados podem ler chamados" ON public.chamados FOR SELECT TO authenticated USING (true);
CREATE POLICY "Usuarios podem criar chamados" ON public.chamados FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Usuarios autorizados podem atualizar chamados" ON public.chamados FOR UPDATE TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR 
  public.has_role(auth.uid(), 'gestor_operacoes') OR 
  public.has_role(auth.uid(), 'supervisor') OR 
  public.has_role(auth.uid(), 'analista_centro_controle')
);
CREATE POLICY "Usuarios autorizados podem deletar chamados" ON public.chamados FOR DELETE TO authenticated USING (
  public.has_role(auth.uid(), 'admin') OR 
  public.has_role(auth.uid(), 'gestor_operacoes')
);