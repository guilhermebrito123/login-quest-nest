-- Criar tabela de notificações
CREATE TABLE public.notificacoes (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  titulo TEXT NOT NULL,
  mensagem TEXT NOT NULL,
  tipo TEXT NOT NULL DEFAULT 'info',
  lida BOOLEAN NOT NULL DEFAULT false,
  link TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.notificacoes ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para notificações
CREATE POLICY "Usuarios podem ver suas proprias notificacoes"
  ON public.notificacoes FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Usuarios podem atualizar suas proprias notificacoes"
  ON public.notificacoes FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Sistema pode criar notificacoes"
  ON public.notificacoes FOR INSERT
  WITH CHECK (true);

-- Trigger para updated_at
CREATE TRIGGER update_notificacoes_updated_at
  BEFORE UPDATE ON public.notificacoes
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();