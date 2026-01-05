-- Criar tabela blacklist
CREATE TABLE public.blacklist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  diarista_id UUID NOT NULL,
  motivo TEXT NOT NULL,
  bloqueado_em TIMESTAMP WITH TIME ZONE DEFAULT now(),
  bloqueado_por UUID REFERENCES public.usuarios(id)
);

-- Adicionar foreign key para diaristas
ALTER TABLE public.blacklist
ADD CONSTRAINT fk_blacklist_diarista
FOREIGN KEY (diarista_id)
REFERENCES public.diaristas(id)
ON DELETE CASCADE;

-- Criar índice único para diarista_id
CREATE UNIQUE INDEX unique_blacklist_diarista
ON public.blacklist(diarista_id);

-- Criar função para adicionar diarista à blacklist
CREATE OR REPLACE FUNCTION public.adicionar_diarista_blacklist(
  p_diarista_id UUID,
  p_motivo TEXT,
  p_bloqueado_por UUID
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.blacklist (diarista_id, motivo, bloqueado_por)
  VALUES (p_diarista_id, p_motivo, p_bloqueado_por);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Habilitar RLS
ALTER TABLE public.blacklist ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Usuários autenticados podem visualizar blacklist"
ON public.blacklist
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Usuários autenticados podem inserir na blacklist"
ON public.blacklist
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem remover da blacklist"
ON public.blacklist
FOR DELETE
TO authenticated
USING (true);