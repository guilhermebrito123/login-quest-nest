-- Adicionar novos campos à tabela chamados
ALTER TABLE public.chamados
ADD COLUMN IF NOT EXISTS posto_servico_id uuid REFERENCES public.postos_servico(id),
ADD COLUMN IF NOT EXISTS contrato_id uuid REFERENCES public.contratos(id),
ADD COLUMN IF NOT EXISTS categoria text CHECK (categoria IN ('manutencao', 'rh', 'suprimentos', 'atendimento')),
ADD COLUMN IF NOT EXISTS subcategoria text,
ADD COLUMN IF NOT EXISTS sla_horas integer DEFAULT 24,
ADD COLUMN IF NOT EXISTS canal text DEFAULT 'app' CHECK (canal IN ('app', 'webhook', 'qr')),
ADD COLUMN IF NOT EXISTS atribuido_para_id uuid REFERENCES public.colaboradores(id);

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_chamados_posto_servico ON public.chamados(posto_servico_id);
CREATE INDEX IF NOT EXISTS idx_chamados_contrato ON public.chamados(contrato_id);
CREATE INDEX IF NOT EXISTS idx_chamados_categoria ON public.chamados(categoria);
CREATE INDEX IF NOT EXISTS idx_chamados_status ON public.chamados(status);
CREATE INDEX IF NOT EXISTS idx_chamados_atribuido ON public.chamados(atribuido_para_id);
CREATE INDEX IF NOT EXISTS idx_chamados_data_abertura ON public.chamados(data_abertura);

-- Criar tabela para comentários dos chamados
CREATE TABLE IF NOT EXISTS public.chamados_comentarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chamado_id uuid NOT NULL REFERENCES public.chamados(id) ON DELETE CASCADE,
  usuario_id uuid NOT NULL REFERENCES auth.users(id),
  comentario text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Criar tabela para anexos dos chamados
CREATE TABLE IF NOT EXISTS public.chamados_anexos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chamado_id uuid NOT NULL REFERENCES public.chamados(id) ON DELETE CASCADE,
  usuario_id uuid NOT NULL REFERENCES auth.users(id),
  nome_arquivo text NOT NULL,
  caminho_storage text NOT NULL,
  tipo_arquivo text,
  tamanho_bytes bigint,
  created_at timestamp with time zone DEFAULT now()
);

-- Habilitar RLS nas novas tabelas
ALTER TABLE public.chamados_comentarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chamados_anexos ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para comentários
CREATE POLICY "Usuarios autenticados podem ler comentarios"
ON public.chamados_comentarios FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Usuarios autenticados podem criar comentarios"
ON public.chamados_comentarios FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "Usuarios podem editar seus comentarios"
ON public.chamados_comentarios FOR UPDATE
TO authenticated
USING (auth.uid() = usuario_id);

CREATE POLICY "Usuarios podem deletar seus comentarios"
ON public.chamados_comentarios FOR DELETE
TO authenticated
USING (auth.uid() = usuario_id);

-- Políticas RLS para anexos
CREATE POLICY "Usuarios autenticados podem ler anexos"
ON public.chamados_anexos FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Usuarios autenticados podem criar anexos"
ON public.chamados_anexos FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "Usuarios podem deletar seus anexos"
ON public.chamados_anexos FOR DELETE
TO authenticated
USING (auth.uid() = usuario_id);

-- Atualizar políticas RLS da tabela chamados para incluir perfil tecnico
DROP POLICY IF EXISTS "Usuarios autorizados podem atualizar chamados" ON public.chamados;
DROP POLICY IF EXISTS "Usuarios autorizados podem deletar chamados" ON public.chamados;

CREATE POLICY "Usuarios autorizados podem atualizar chamados"
ON public.chamados FOR UPDATE
TO authenticated
USING (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
  has_role(auth.uid(), 'supervisor'::app_role) OR 
  has_role(auth.uid(), 'analista_centro_controle'::app_role) OR
  has_role(auth.uid(), 'tecnico'::app_role)
);

CREATE POLICY "Usuarios autorizados podem deletar chamados"
ON public.chamados FOR DELETE
TO authenticated
USING (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
  has_role(auth.uid(), 'supervisor'::app_role)
);

-- Criar trigger para atualização de comentários apenas se não existir
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_chamados_comentarios_updated_at'
  ) THEN
    CREATE TRIGGER update_chamados_comentarios_updated_at
    BEFORE UPDATE ON public.chamados_comentarios
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
  END IF;
END$$;