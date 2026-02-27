
-- 1. Desabilitar trigger
ALTER TABLE public.faltas_colaboradores_convenia DISABLE TRIGGER trg_reverter_justificativa_ao_remover_atestado;

-- 2. Remover CHECK constraints
ALTER TABLE public.faltas_colaboradores_convenia DROP CONSTRAINT chk_falta_justificada_exige_atestado;
ALTER TABLE public.faltas_colaboradores_convenia DROP CONSTRAINT faltas_colaboradores_convenia_motivo_check;

-- 3. Alterar coluna motivo para text
ALTER TABLE public.faltas_colaboradores_convenia 
  ALTER COLUMN motivo TYPE text USING motivo::text;

-- 4. Atualizar dados ANTES de adicionar constraints
UPDATE public.faltas_colaboradores_convenia SET motivo = 'FALTA INJUSTIFICADA' WHERE motivo = 'DIÁRIA - FALTA';
UPDATE public.faltas_colaboradores_convenia SET motivo = 'FALTA JUSTIFICADA' WHERE motivo = 'DIÁRIA - FALTA ATESTADO';

-- 5. Adicionar CHECK constraints com novos valores
ALTER TABLE public.faltas_colaboradores_convenia 
  ADD CONSTRAINT faltas_colaboradores_convenia_motivo_check 
  CHECK (motivo IN ('FALTA INJUSTIFICADA', 'FALTA JUSTIFICADA'));

ALTER TABLE public.faltas_colaboradores_convenia 
  ADD CONSTRAINT chk_falta_justificada_exige_atestado 
  CHECK (motivo <> 'FALTA JUSTIFICADA' OR atestado_path IS NOT NULL);

-- 6. Recriar reverter_justificativa_ao_remover_atestado
CREATE OR REPLACE FUNCTION public.reverter_justificativa_ao_remover_atestado()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF OLD.atestado_path IS NOT NULL AND NEW.atestado_path IS NULL THEN
    PERFORM set_config('app.rpc_call', 'reverter_justificativa', true);
    NEW.justificada_em := NULL;
    NEW.justificada_por := NULL;
    NEW.motivo := 'FALTA INJUSTIFICADA';
    NEW.updated_at := now();
    UPDATE diarias_temporarias SET motivo_vago = 'DIÁRIA - FALTA'::motivo_vago_type, updated_at = now() WHERE id = NEW.diaria_temporaria_id;
  END IF;
  RETURN NEW;
END;
$$;

-- 7. Reabilitar trigger
ALTER TABLE public.faltas_colaboradores_convenia ENABLE TRIGGER trg_reverter_justificativa_ao_remover_atestado;

-- 8. Recriar sync_falta_colaborador_convenia
CREATE OR REPLACE FUNCTION public.sync_falta_colaborador_convenia()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF current_setting('app.rpc_call', true) = 'justificar_falta' THEN
    RETURN NEW;
  END IF;
  IF NEW.motivo_vago = 'DIÁRIA - FALTA' AND NEW.colaborador_ausente_convenia IS NOT NULL THEN
    INSERT INTO public.faltas_colaboradores_convenia (
      colaborador_convenia_id, diaria_temporaria_id, data_falta, motivo
    ) VALUES (
      NEW.colaborador_ausente_convenia, NEW.id, NEW.data_diaria, 'FALTA INJUSTIFICADA'
    )
    ON CONFLICT (colaborador_convenia_id, data_falta, diaria_temporaria_id)
    WHERE diaria_temporaria_id IS NOT NULL
    DO UPDATE SET
      colaborador_convenia_id = EXCLUDED.colaborador_convenia_id,
      data_falta = EXCLUDED.data_falta,
      motivo = EXCLUDED.motivo,
      updated_at = now()
    WHERE faltas_colaboradores_convenia.motivo = 'FALTA INJUSTIFICADA';
  END IF;
  RETURN NEW;
END;
$$;

-- 9. Recriar justificar_falta_convenia
CREATE OR REPLACE FUNCTION public.justificar_falta_convenia(p_diaria_temporaria_id bigint, p_atestado_path text, p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE v_level public.internal_access_level;
BEGIN
  v_level := public.current_internal_access_level();
  IF v_level IS NULL OR v_level NOT IN ('admin'::public.internal_access_level,'gestor_operacoes'::public.internal_access_level,'supervisor'::public.internal_access_level,'assistente_operacoes'::public.internal_access_level) THEN
    RAISE EXCEPTION 'Sem permissão para justificar faltas.';
  END IF;
  IF p_atestado_path IS NULL OR p_atestado_path = '' THEN RAISE EXCEPTION 'Atestado médico é obrigatório'; END IF;
  IF NOT EXISTS (SELECT 1 FROM faltas_colaboradores_convenia WHERE diaria_temporaria_id = p_diaria_temporaria_id) THEN
    RAISE EXCEPTION 'Não existe registro de falta para esta diária';
  END IF;
  PERFORM set_config('app.rpc_call', 'justificar_falta', true);
  UPDATE faltas_colaboradores_convenia SET motivo = 'FALTA JUSTIFICADA', atestado_path = p_atestado_path, justificada_em = now(), justificada_por = p_user_id, updated_at = now() WHERE diaria_temporaria_id = p_diaria_temporaria_id;
  UPDATE diarias_temporarias SET motivo_vago = 'DIÁRIA - FALTA ATESTADO'::motivo_vago_type, updated_at = now() WHERE id = p_diaria_temporaria_id;
END;
$$;

-- 10. Recriar justificar_falta_convenia_por_falta_id
CREATE OR REPLACE FUNCTION public.justificar_falta_convenia_por_falta_id(p_atestado_path text, p_falta_id bigint, p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_level public.internal_access_level;
  v_diaria_id bigint;
BEGIN
  v_level := public.current_internal_access_level();
  IF v_level IS NULL OR v_level NOT IN (
    'admin'::public.internal_access_level,
    'gestor_operacoes'::public.internal_access_level,
    'supervisor'::public.internal_access_level,
    'assistente_operacoes'::public.internal_access_level
  ) THEN
    RAISE EXCEPTION 'Sem permissão para justificar faltas.';
  END IF;
  IF p_atestado_path IS NULL OR p_atestado_path = '' THEN
    RAISE EXCEPTION 'Atestado é obrigatório para justificar falta';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.faltas_colaboradores_convenia WHERE id = p_falta_id) THEN
    RAISE EXCEPTION 'Registro de falta não encontrado';
  END IF;
  SELECT diaria_temporaria_id INTO v_diaria_id FROM public.faltas_colaboradores_convenia WHERE id = p_falta_id;
  PERFORM set_config('app.rpc_call', 'justificar_falta', true);
  UPDATE public.faltas_colaboradores_convenia
  SET motivo = 'FALTA JUSTIFICADA', atestado_path = p_atestado_path, justificada_em = now(), justificada_por = p_user_id, updated_at = now()
  WHERE id = p_falta_id;
  IF v_diaria_id IS NOT NULL THEN
    UPDATE public.diarias_temporarias SET motivo_vago = 'DIÁRIA - FALTA ATESTADO'::public.motivo_vago_type, updated_at = now() WHERE id = v_diaria_id;
  END IF;
END;
$$;

-- 11. Recriar reverter_justificativa_falta_convenia (overload uuid)
CREATE OR REPLACE FUNCTION public.reverter_justificativa_falta_convenia(p_falta_id uuid, p_user_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE v_level public.internal_access_level; v_falta public.faltas_colaboradores_convenia%ROWTYPE; v_atestado_path text;
BEGIN
  IF p_user_id <> auth.uid() THEN RAISE EXCEPTION 'Usuario invalido.'; END IF;
  v_level := public.current_internal_access_level();
  IF v_level IS NULL THEN RAISE EXCEPTION 'Usuario nao possui perfil interno.'; END IF;
  IF NOT (v_level = ANY(ARRAY['admin','gestor_operacoes','supervisor','assistente_operacoes','analista_centro_controle']::public.internal_access_level[])) THEN
    RAISE EXCEPTION 'Sem permissao para reverter justificativa.';
  END IF;
  SELECT * INTO v_falta FROM public.faltas_colaboradores_convenia WHERE id = p_falta_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Falta nao encontrada (id=%).', p_falta_id; END IF;
  IF v_falta.motivo IS DISTINCT FROM 'FALTA JUSTIFICADA' THEN
    RAISE EXCEPTION 'A falta nao esta como FALTA JUSTIFICADA.';
  END IF;
  IF v_falta.atestado_path IS NULL OR btrim(v_falta.atestado_path) = '' THEN RAISE EXCEPTION 'Nao existe atestado vinculado.'; END IF;
  v_atestado_path := v_falta.atestado_path;
  UPDATE public.faltas_colaboradores_convenia SET atestado_path = NULL, motivo = 'FALTA INJUSTIFICADA', justificada_em = NULL, justificada_por = NULL, updated_at = now() WHERE id = p_falta_id;
  IF v_falta.diaria_temporaria_id IS NOT NULL THEN
    PERFORM set_config('app.rpc_call', 'reverter_justificativa', true);
    UPDATE public.diarias_temporarias SET motivo_vago = 'DIÁRIA - FALTA'::public.motivo_vago_type, updated_at = now() WHERE id = v_falta.diaria_temporaria_id;
  END IF;
  RETURN v_atestado_path;
END;
$$;

-- 12. Recriar reverter_justificativa_falta_convenia (overload bigint)
CREATE OR REPLACE FUNCTION public.reverter_justificativa_falta_convenia(p_falta_id bigint, p_user_id uuid, p_bucket_id text DEFAULT 'atestados'::text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_level public.internal_access_level;
  v_falta public.faltas_colaboradores_convenia%ROWTYPE;
  v_atestado_path text;
BEGIN
  IF p_user_id <> auth.uid() THEN RAISE EXCEPTION 'Usuario invalido.'; END IF;
  v_level := public.current_internal_access_level();
  IF v_level IS NULL THEN RAISE EXCEPTION 'Usuario nao possui perfil interno.'; END IF;
  IF NOT (v_level = ANY(ARRAY['admin','gestor_operacoes','supervisor','assistente_operacoes','analista_centro_controle']::public.internal_access_level[])) THEN
    RAISE EXCEPTION 'Sem permissao para reverter justificativa.';
  END IF;
  SELECT * INTO v_falta FROM public.faltas_colaboradores_convenia WHERE id = p_falta_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Falta nao encontrada (id=%).', p_falta_id; END IF;
  IF v_falta.motivo IS DISTINCT FROM 'FALTA JUSTIFICADA' THEN
    RAISE EXCEPTION 'A falta nao esta como FALTA JUSTIFICADA.';
  END IF;
  IF v_falta.atestado_path IS NULL OR btrim(v_falta.atestado_path) = '' THEN RAISE EXCEPTION 'Nao existe atestado vinculado a esta falta.'; END IF;
  v_atestado_path := v_falta.atestado_path;
  UPDATE public.faltas_colaboradores_convenia SET atestado_path = NULL, motivo = 'FALTA INJUSTIFICADA', justificada_em = NULL, justificada_por = NULL, updated_at = now() WHERE id = p_falta_id;
  IF v_falta.diaria_temporaria_id IS NOT NULL THEN
    PERFORM set_config('app.rpc_call', 'reverter_justificativa', true);
    UPDATE public.diarias_temporarias SET motivo_vago = 'DIÁRIA - FALTA'::public.motivo_vago_type, updated_at = now() WHERE id = v_falta.diaria_temporaria_id;
  END IF;
  RETURN v_atestado_path;
END;
$$;
