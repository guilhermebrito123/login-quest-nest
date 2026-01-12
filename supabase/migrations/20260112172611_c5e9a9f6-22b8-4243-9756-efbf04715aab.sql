-- 1) Garantir extensão UUID (Supabase normalmente já tem)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2) Tabela de histórico
CREATE TABLE IF NOT EXISTS public.diaristas_historico (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  diarista_id UUID NOT NULL REFERENCES public.diaristas(id) ON DELETE CASCADE,
  campo_alterado TEXT NOT NULL,
  valor_anterior TEXT,
  valor_novo TEXT,
  motivo TEXT NOT NULL,
  alterado_em TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Habilitar RLS na tabela de histórico
ALTER TABLE public.diaristas_historico ENABLE ROW LEVEL SECURITY;

-- Política para permitir leitura do histórico
CREATE POLICY "Permitir leitura do histórico de diaristas"
ON public.diaristas_historico
FOR SELECT
USING (true);

-- Política para permitir inserção (via trigger)
CREATE POLICY "Permitir inserção no histórico de diaristas"
ON public.diaristas_historico
FOR INSERT
WITH CHECK (true);

-- 3) Campo auxiliar de motivo na tabela diaristas
ALTER TABLE public.diaristas
ADD COLUMN IF NOT EXISTS motivo_alteracao TEXT;

-- 4) Função com validação obrigatória
CREATE OR REPLACE FUNCTION public.fn_registrar_historico_diarista()
RETURNS TRIGGER AS $$
DECLARE
  k TEXT;
  old_json JSONB := to_jsonb(OLD);
  new_json JSONB := to_jsonb(NEW);
  motivo TEXT;
BEGIN
  -- 🔴 BLOQUEIA UPDATE SEM MOTIVO
  IF NEW.motivo_alteracao IS NULL
     OR btrim(NEW.motivo_alteracao) = '' THEN
    RAISE EXCEPTION
      'Atualização bloqueada: informe o motivo da alteração.';
  END IF;

  motivo := NEW.motivo_alteracao;

  -- percorre todos os campos
  FOR k IN
    SELECT jsonb_object_keys(new_json)
  LOOP
    -- ignora o próprio campo de motivo
    IF k = 'motivo_alteracao' THEN
      CONTINUE;
    END IF;

    -- (opcional) ignore timestamps automáticos
    -- IF k IN ('updated_at', 'created_at') THEN CONTINUE; END IF;

    IF (old_json -> k) IS DISTINCT FROM (new_json -> k) THEN
      INSERT INTO public.diaristas_historico (
        diarista_id,
        campo_alterado,
        valor_anterior,
        valor_novo,
        motivo
      )
      VALUES (
        OLD.id,
        k,
        old_json ->> k,
        new_json ->> k,
        motivo
      );
    END IF;
  END LOOP;

  -- limpa o motivo após registrar
  NEW.motivo_alteracao := NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- 5) Trigger
DROP TRIGGER IF EXISTS trg_registrar_historico_diarista ON public.diaristas;

CREATE TRIGGER trg_registrar_historico_diarista
BEFORE UPDATE ON public.diaristas
FOR EACH ROW
EXECUTE FUNCTION public.fn_registrar_historico_diarista();