-- Criar enum tipos_requisito
CREATE TYPE public.tipos_requisito AS ENUM (
  'TQC (D.A. 06-01)',
  'TQC (D.A. 06-01) + exigências do cliente',
  'Solicitação do cliente'
);

-- Criar enum sexualidade
CREATE TYPE public.sexualidade AS ENUM (
  'Masculino',
  'Feminino',
  'Indiferente'
);

-- Criar enum estado_civil
CREATE TYPE public.estado_civil AS ENUM (
  'Solteiro',
  'Casado',
  'Divorciado',
  'Viúvo',
  'Indiferente'
);

-- Criar tabela perfil_candidato
CREATE TABLE public.perfil_candidato (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tipo_requisito public.tipos_requisito NOT NULL,
  requisito_descricao text,
  formacao text[],
  experiencia text[],
  habilidade text[],
  sexo public.sexualidade,
  altura numeric,
  peso numeric,
  idade_minima integer,
  idade_maxima integer,
  estado_civil public.estado_civil,
  tempo_minimo_experiencia numeric,
  curso_adicional text[],
  created_at timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo'),
  updated_at timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo')
);

-- Habilitar RLS
ALTER TABLE public.perfil_candidato ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Usuarios autenticados podem ler perfil_candidato"
  ON public.perfil_candidato
  FOR SELECT
  USING (true);

CREATE POLICY "Usuarios autorizados podem inserir perfil_candidato"
  ON public.perfil_candidato
  FOR INSERT
  WITH CHECK (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'gestor_operacoes'::app_role));

CREATE POLICY "Usuarios autorizados podem atualizar perfil_candidato"
  ON public.perfil_candidato
  FOR UPDATE
  USING (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'gestor_operacoes'::app_role));

CREATE POLICY "Usuarios autorizados podem deletar perfil_candidato"
  ON public.perfil_candidato
  FOR DELETE
  USING (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'gestor_operacoes'::app_role));