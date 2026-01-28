-- =============================================
-- MÓDULO DE FALTAS PARA COLABORADORES_CONVENIA
-- =============================================

-- 1. Criar tabela de faltas
CREATE TABLE public.faltas_colaboradores_convenia (
  id bigserial PRIMARY KEY,
  colaborador_convenia_id uuid NOT NULL 
    REFERENCES public.colaboradores_convenia(id) ON DELETE CASCADE,
  diaria_temporaria_id bigint NOT NULL UNIQUE 
    REFERENCES public.diarias_temporarias(id) ON DELETE CASCADE,
  data_falta date NOT NULL,
  motivo public.motivo_vago_type NOT NULL 
    CHECK (motivo IN ('FALTA JUSTIFICADA', 'FALTA INJUSTIFICADA')),
  atestado_path text NULL,
  justificada_em timestamptz NULL,
  justificada_por uuid NULL 
    REFERENCES public.usuarios(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  -- Constraint: FALTA JUSTIFICADA exige atestado
  CONSTRAINT chk_falta_justificada_exige_atestado 
    CHECK (motivo <> 'FALTA JUSTIFICADA' OR atestado_path IS NOT NULL)
);

-- 2. Índices para performance
CREATE INDEX idx_faltas_colab_convenia 
  ON public.faltas_colaboradores_convenia(colaborador_convenia_id);
CREATE INDEX idx_faltas_data 
  ON public.faltas_colaboradores_convenia(data_falta);
CREATE INDEX idx_faltas_diaria 
  ON public.faltas_colaboradores_convenia(diaria_temporaria_id);

-- 3. Habilitar RLS
ALTER TABLE public.faltas_colaboradores_convenia ENABLE ROW LEVEL SECURITY;

-- 4. Políticas RLS
CREATE POLICY "Usuarios autenticados podem ler faltas_convenia"
  ON public.faltas_colaboradores_convenia
  FOR SELECT
  USING (true);

CREATE POLICY "Usuarios autorizados podem inserir faltas_convenia"
  ON public.faltas_colaboradores_convenia
  FOR INSERT
  WITH CHECK (
    has_role(auth.uid(), 'admin'::internal_access_level) OR
    has_role(auth.uid(), 'gestor_operacoes'::internal_access_level) OR
    has_role(auth.uid(), 'supervisor'::internal_access_level)
  );

CREATE POLICY "Usuarios autorizados podem atualizar faltas_convenia"
  ON public.faltas_colaboradores_convenia
  FOR UPDATE
  USING (
    has_role(auth.uid(), 'admin'::internal_access_level) OR
    has_role(auth.uid(), 'gestor_operacoes'::internal_access_level) OR
    has_role(auth.uid(), 'supervisor'::internal_access_level)
  );

CREATE POLICY "Admins podem deletar faltas_convenia"
  ON public.faltas_colaboradores_convenia
  FOR DELETE
  USING (has_role(auth.uid(), 'admin'::internal_access_level));

-- =============================================
-- 5. VALIDAÇÃO: Impedir criação de diária com FALTA JUSTIFICADA direta
-- =============================================
CREATE OR REPLACE FUNCTION public.validar_falta_justificada_diaria()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Impedir INSERT com FALTA JUSTIFICADA
  IF TG_OP = 'INSERT' AND NEW.motivo_vago = 'FALTA JUSTIFICADA' THEN
    RAISE EXCEPTION 'Não é permitido criar diária diretamente como FALTA JUSTIFICADA. Crie como FALTA INJUSTIFICADA e justifique via RPC.';
  END IF;
  
  -- Impedir UPDATE para FALTA JUSTIFICADA (exceto se vier da RPC - security definer)
  -- A RPC usa SECURITY DEFINER, então passa por cima desta validação
  -- Mas updates normais do frontend serão bloqueados
  IF TG_OP = 'UPDATE' 
     AND OLD.motivo_vago = 'FALTA INJUSTIFICADA'
     AND NEW.motivo_vago = 'FALTA JUSTIFICADA'
     AND current_setting('app.rpc_call', true) IS DISTINCT FROM 'justificar_falta' THEN
    RAISE EXCEPTION 'Não é permitido alterar para FALTA JUSTIFICADA diretamente. Use a função justificar_falta_convenia com atestado.';
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validar_falta_justificada_diaria
BEFORE INSERT OR UPDATE OF motivo_vago ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.validar_falta_justificada_diaria();

-- =============================================
-- 6. TRIGGER: Criar falta ao inserir diária INJUSTIFICADA
-- =============================================
CREATE OR REPLACE FUNCTION public.criar_falta_colaborador_convenia()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Só cria falta se for FALTA INJUSTIFICADA e tiver colaborador_ausente_convenia
  IF NEW.motivo_vago = 'FALTA INJUSTIFICADA'
     AND NEW.colaborador_ausente_convenia IS NOT NULL THEN
    INSERT INTO public.faltas_colaboradores_convenia (
      colaborador_convenia_id,
      diaria_temporaria_id,
      data_falta,
      motivo
    ) VALUES (
      NEW.colaborador_ausente_convenia,
      NEW.id,
      NEW.data_diaria,
      'FALTA INJUSTIFICADA'
    );
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_criar_falta_convenia
AFTER INSERT ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.criar_falta_colaborador_convenia();

-- =============================================
-- 7. TRIGGER: Sincronizar falta ao atualizar diária (SEM DELETE)
-- =============================================
CREATE OR REPLACE FUNCTION public.sync_falta_colaborador_convenia()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Se mudou para FALTA INJUSTIFICADA e tem colaborador, criar/atualizar
  IF NEW.motivo_vago = 'FALTA INJUSTIFICADA'
     AND NEW.colaborador_ausente_convenia IS NOT NULL THEN
    INSERT INTO public.faltas_colaboradores_convenia (
      colaborador_convenia_id,
      diaria_temporaria_id,
      data_falta,
      motivo
    ) VALUES (
      NEW.colaborador_ausente_convenia,
      NEW.id,
      NEW.data_diaria,
      'FALTA INJUSTIFICADA'
    )
    ON CONFLICT (diaria_temporaria_id)
    DO UPDATE SET
      colaborador_convenia_id = EXCLUDED.colaborador_convenia_id,
      data_falta = EXCLUDED.data_falta,
      updated_at = now();
  
  -- Se já existe falta e mudou o colaborador, atualizar vínculo
  ELSIF EXISTS (
    SELECT 1 FROM public.faltas_colaboradores_convenia 
    WHERE diaria_temporaria_id = NEW.id
  ) AND NEW.colaborador_ausente_convenia IS NOT NULL 
    AND OLD.colaborador_ausente_convenia IS DISTINCT FROM NEW.colaborador_ausente_convenia THEN
    UPDATE public.faltas_colaboradores_convenia
    SET 
      colaborador_convenia_id = NEW.colaborador_ausente_convenia,
      updated_at = now()
    WHERE diaria_temporaria_id = NEW.id;
  END IF;
  
  -- NOTA: NÃO deletamos faltas quando o motivo muda
  -- Isso preserva o histórico para auditoria
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sync_falta_convenia
AFTER UPDATE OF motivo_vago, colaborador_ausente_convenia ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.sync_falta_colaborador_convenia();

-- =============================================
-- 8. RPC: Justificar falta com atestado
-- =============================================
CREATE OR REPLACE FUNCTION public.justificar_falta_convenia(
  p_diaria_temporaria_id bigint,
  p_atestado_path text,
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Marcar contexto para bypass da validação
  PERFORM set_config('app.rpc_call', 'justificar_falta', true);

  -- Validar existência da falta injustificada
  IF NOT EXISTS (
    SELECT 1
    FROM public.faltas_colaboradores_convenia
    WHERE diaria_temporaria_id = p_diaria_temporaria_id
      AND motivo = 'FALTA INJUSTIFICADA'
  ) THEN
    RAISE EXCEPTION 'Falta inexistente ou já justificada';
  END IF;

  -- Validar atestado obrigatório
  IF p_atestado_path IS NULL OR p_atestado_path = '' THEN
    RAISE EXCEPTION 'Atestado é obrigatório para justificar falta';
  END IF;

  -- Atualizar a falta
  UPDATE public.faltas_colaboradores_convenia
  SET
    motivo = 'FALTA JUSTIFICADA',
    atestado_path = p_atestado_path,
    justificada_em = now(),
    justificada_por = p_user_id,
    updated_at = now()
  WHERE diaria_temporaria_id = p_diaria_temporaria_id;

  -- Atualizar a diária de origem
  UPDATE public.diarias_temporarias
  SET
    motivo_vago = 'FALTA JUSTIFICADA',
    updated_at = now()
  WHERE id = p_diaria_temporaria_id;
  
  -- Limpar contexto
  PERFORM set_config('app.rpc_call', '', true);
END;
$$;

-- Permissão para usuários autenticados
GRANT EXECUTE ON FUNCTION public.justificar_falta_convenia(bigint, text, uuid) TO authenticated;

-- =============================================
-- 9. MIGRAÇÃO: Popular tabela com faltas existentes
-- =============================================
INSERT INTO public.faltas_colaboradores_convenia (
  colaborador_convenia_id,
  diaria_temporaria_id,
  data_falta,
  motivo,
  created_at,
  updated_at
)
SELECT 
  dt.colaborador_ausente_convenia,
  dt.id,
  dt.data_diaria,
  'FALTA INJUSTIFICADA'::motivo_vago_type,
  dt.created_at,
  now()
FROM public.diarias_temporarias dt
WHERE dt.motivo_vago = 'FALTA INJUSTIFICADA'
  AND dt.colaborador_ausente_convenia IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.faltas_colaboradores_convenia f 
    WHERE f.diaria_temporaria_id = dt.id
  )
ON CONFLICT (diaria_temporaria_id) DO NOTHING;