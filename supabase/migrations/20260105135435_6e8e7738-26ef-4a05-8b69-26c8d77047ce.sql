-- Criar tabela de logs para diarias_temporarias
CREATE TABLE public.diarias_temporarias_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  diaria_id BIGINT NOT NULL REFERENCES public.diarias_temporarias(id) ON DELETE CASCADE,
  operacao VARCHAR(10) NOT NULL,
  campo TEXT NOT NULL,
  valor_antigo TEXT,
  valor_novo TEXT,
  usuario_responsavel UUID REFERENCES public.usuarios(id),
  operacao_em TIMESTAMPTZ DEFAULT now(),
  criado_em TIMESTAMPTZ DEFAULT now()
);

-- Índices para otimização
CREATE INDEX idx_diarias_temporarias_logs_diaria_id ON public.diarias_temporarias_logs(diaria_id);
CREATE INDEX idx_diarias_temporarias_logs_operacao_em ON public.diarias_temporarias_logs(operacao_em);

-- Habilitar RLS
ALTER TABLE public.diarias_temporarias_logs ENABLE ROW LEVEL SECURITY;

-- Política para visualização (usuários autenticados)
CREATE POLICY "Usuários autenticados podem visualizar logs"
ON public.diarias_temporarias_logs
FOR SELECT
TO authenticated
USING (true);

-- Política para inserção (sistema via trigger)
CREATE POLICY "Sistema pode inserir logs"
ON public.diarias_temporarias_logs
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Criar trigger na tabela diarias_temporarias
CREATE TRIGGER trigger_log_diaria_temporaria_changes
AFTER INSERT OR UPDATE OR DELETE ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.log_diaria_temporaria_changes();