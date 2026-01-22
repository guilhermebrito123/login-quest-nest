-- PASSO 1: Criar tabela de histórico de faltas do colaborador
CREATE TABLE IF NOT EXISTS public.colaborador_faltas (
  id bigserial PRIMARY KEY,
  colaborador_id uuid NOT NULL
    REFERENCES public.colaboradores(id) ON DELETE CASCADE,
  diaria_temporaria_id bigint NOT NULL UNIQUE
    REFERENCES public.diarias_temporarias(id) ON DELETE CASCADE,
  motivo public.motivo_vago_type NOT NULL,
  documento_url text NULL,
  justificada_em timestamptz NULL,
  justificada_por uuid NULL
    REFERENCES public.usuarios(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Índice para consultas rápidas
CREATE INDEX idx_colaborador_faltas_colaborador
  ON public.colaborador_faltas(colaborador_id);

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  new.updated_at = now();
  RETURN new;
END $$;

CREATE TRIGGER trg_colaborador_faltas_updated_at
BEFORE UPDATE ON public.colaborador_faltas
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- RLS para colaborador_faltas
ALTER TABLE public.colaborador_faltas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios autenticados podem ler faltas"
ON public.colaborador_faltas
FOR SELECT
USING (true);

CREATE POLICY "Usuarios autorizados podem inserir faltas"
ON public.colaborador_faltas
FOR INSERT
WITH CHECK (
  has_role(auth.uid(), 'admin'::internal_access_level) OR
  has_role(auth.uid(), 'gestor_operacoes'::internal_access_level) OR
  has_role(auth.uid(), 'supervisor'::internal_access_level)
);

CREATE POLICY "Usuarios autorizados podem atualizar faltas"
ON public.colaborador_faltas
FOR UPDATE
USING (
  has_role(auth.uid(), 'admin'::internal_access_level) OR
  has_role(auth.uid(), 'gestor_operacoes'::internal_access_level) OR
  has_role(auth.uid(), 'supervisor'::internal_access_level)
);

CREATE POLICY "Usuarios autorizados podem deletar faltas"
ON public.colaborador_faltas
FOR DELETE
USING (
  has_role(auth.uid(), 'admin'::internal_access_level) OR
  has_role(auth.uid(), 'gestor_operacoes'::internal_access_level)
);

-- PASSO 2: Trigger para sincronizar faltas automaticamente
CREATE OR REPLACE FUNCTION public.sync_falta_from_diaria_temporaria()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  -- Se não há colaborador ausente, não há falta
  IF new.colaborador_ausente IS NULL THEN
    RETURN new;
  END IF;

  -- Se a diaria_temporaria representa falta injustificada
  IF new.motivo_vago = 'FALTA INJUSTIFICADA' THEN
    INSERT INTO public.colaborador_faltas (
      colaborador_id,
      diaria_temporaria_id,
      motivo
    )
    VALUES (
      new.colaborador_ausente::uuid,
      new.id,
      new.motivo_vago
    )
    ON CONFLICT (diaria_temporaria_id)
    DO UPDATE SET
      colaborador_id = excluded.colaborador_id,
      motivo = excluded.motivo;
  END IF;

  RETURN new;
END $$;

CREATE TRIGGER trg_diaria_temporaria_sync_falta
AFTER INSERT OR UPDATE OF motivo_vago, colaborador_ausente
ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.sync_falta_from_diaria_temporaria();

-- PASSO 3: Função para justificar falta (operação atômica)
CREATE OR REPLACE FUNCTION public.justificar_falta_diaria_temporaria(
  p_diaria_temporaria_id bigint,
  p_documento_url text,
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_colaborador_id uuid;
BEGIN
  -- Garante que a diária existe e está vinculada a um colaborador
  SELECT colaborador_ausente::uuid
    INTO v_colaborador_id
  FROM public.diarias_temporarias
  WHERE id = p_diaria_temporaria_id
  FOR UPDATE;

  IF v_colaborador_id IS NULL THEN
    RAISE EXCEPTION 'Diária % não possui colaborador ausente', p_diaria_temporaria_id;
  END IF;

  -- Atualiza a falta
  UPDATE public.colaborador_faltas
  SET
    motivo = 'FALTA JUSTIFICADA',
    documento_url = p_documento_url,
    justificada_em = now(),
    justificada_por = p_user_id
  WHERE diaria_temporaria_id = p_diaria_temporaria_id;

  -- Caso não exista (fallback de segurança)
  IF NOT FOUND THEN
    INSERT INTO public.colaborador_faltas (
      colaborador_id,
      diaria_temporaria_id,
      motivo,
      documento_url,
      justificada_em,
      justificada_por
    )
    VALUES (
      v_colaborador_id,
      p_diaria_temporaria_id,
      'FALTA JUSTIFICADA',
      p_documento_url,
      now(),
      p_user_id
    );
  END IF;

  -- Atualiza a diária de origem
  UPDATE public.diarias_temporarias
  SET motivo_vago = 'FALTA JUSTIFICADA'
  WHERE id = p_diaria_temporaria_id;
END;
$$;