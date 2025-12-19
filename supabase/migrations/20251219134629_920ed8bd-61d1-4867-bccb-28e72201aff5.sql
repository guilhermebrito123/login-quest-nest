
-- Criar enum status_vaga
CREATE TYPE public.status_vaga AS ENUM (
  'Aberta',
  'Em seleção',
  'Em aprovação',
  'Aguardando documentação',
  'Aguardando exame',
  'Em Admissão',
  'Fechada',
  'Cancelada',
  'Reprovada'
);

-- Criar enum tipo_de_vaga
CREATE TYPE public.tipo_de_vaga AS ENUM (
  'Efetivo',
  'Temporário',
  'Seleção',
  'Estágio'
);

-- Criar enum motivo_contratacao
CREATE TYPE public.motivo_contratacao AS ENUM (
  'Substituição efetivo',
  'Substituição férias licença',
  'Implantação/Abertura de novo contrato',
  'Solicitação do cliente'
);

-- Criar tabela vagas_temp
CREATE TABLE public.vagas_temp (
  id SERIAL PRIMARY KEY,
  posto_servico_id UUID NOT NULL REFERENCES public.postos_servico(id) ON DELETE CASCADE,
  nome_vaga TEXT NOT NULL,
  horario_inicio TIME NOT NULL,
  horario_fim TIME NOT NULL,
  criado_por UUID NOT NULL REFERENCES public.usuarios(id),
  status public.status_vaga NOT NULL DEFAULT 'Aberta',
  tipo_vaga public.tipo_de_vaga NOT NULL,
  motivo_contratacao public.motivo_contratacao NOT NULL,
  nome_colaborador UUID REFERENCES public.colaboradores(id),
  nome_candidato UUID REFERENCES public.candidatos(id),
  data_inicio TIMESTAMP WITH TIME ZONE NOT NULL,
  data_fim TIMESTAMP WITH TIME ZONE,
  entrevistador UUID REFERENCES public.usuarios(id),
  observacoes TEXT,
  aberta_por UUID NOT NULL REFERENCES public.usuarios(id),
  aprovada_por UUID REFERENCES public.usuarios(id),
  fechada_por UUID REFERENCES public.usuarios(id),
  cancelada_por UUID REFERENCES public.usuarios(id),
  reprovada_por UUID REFERENCES public.usuarios(id),
  data_abertura TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  data_selecao TIMESTAMP WITH TIME ZONE,
  data_aprovacao TIMESTAMP WITH TIME ZONE,
  data_fechamento TIMESTAMP WITH TIME ZONE,
  data_cancelamento TIMESTAMP WITH TIME ZONE,
  data_reprovacao TIMESTAMP WITH TIME ZONE,
  tipo_requisito public.tipos_requisito NOT NULL,
  requisito_descricao TEXT,
  formacao TEXT[],
  experiencia TEXT[],
  habilidade TEXT[],
  sexo public.sexualidade,
  altura NUMERIC,
  peso NUMERIC,
  idade_minima INTEGER,
  idade_maxima INTEGER,
  estado_civil public.estado_civil,
  tempo_minimo_experiencia NUMERIC,
  curso_adicional TEXT[],
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE public.vagas_temp ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Usuarios autenticados podem ler vagas_temp"
ON public.vagas_temp
FOR SELECT
USING (true);

CREATE POLICY "Usuarios autorizados podem criar vagas_temp"
ON public.vagas_temp
FOR INSERT
WITH CHECK (
  has_role(auth.uid(), 'admin'::internal_access_level) OR
  has_role(auth.uid(), 'gestor_operacoes'::internal_access_level) OR
  has_role(auth.uid(), 'supervisor'::internal_access_level)
);

CREATE POLICY "Usuarios autorizados podem atualizar vagas_temp"
ON public.vagas_temp
FOR UPDATE
USING (
  has_role(auth.uid(), 'admin'::internal_access_level) OR
  has_role(auth.uid(), 'gestor_operacoes'::internal_access_level) OR
  has_role(auth.uid(), 'supervisor'::internal_access_level)
);

CREATE POLICY "Usuarios autorizados podem deletar vagas_temp"
ON public.vagas_temp
FOR DELETE
USING (
  has_role(auth.uid(), 'admin'::internal_access_level) OR
  has_role(auth.uid(), 'gestor_operacoes'::internal_access_level)
);

-- Trigger para atualizar updated_at
CREATE TRIGGER update_vagas_temp_updated_at
BEFORE UPDATE ON public.vagas_temp
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();
