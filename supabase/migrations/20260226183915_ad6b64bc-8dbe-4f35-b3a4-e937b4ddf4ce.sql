
-- Rename enum values in motivo_vago_type
ALTER TYPE public.motivo_vago_type RENAME VALUE 'VAGA EM ABERTO (COBERTURA SALÁRIO)' TO 'DIÁRIA - SALÁRIO';
ALTER TYPE public.motivo_vago_type RENAME VALUE 'SERVIÇO EXTRA' TO 'DIÁRIA - DEMANDA EXTRA';
ALTER TYPE public.motivo_vago_type RENAME VALUE 'FÉRIAS' TO 'DIÁRIA - FÉRIAS';
ALTER TYPE public.motivo_vago_type RENAME VALUE 'FALTA INJUSTIFICADA' TO 'DIÁRIA - FALTA';
ALTER TYPE public.motivo_vago_type RENAME VALUE 'FALTA JUSTIFICADA' TO 'DIÁRIA - FALTA ATESTADO';
ALTER TYPE public.motivo_vago_type RENAME VALUE 'DIÁRIA BÔNUS' TO 'DIÁRIA - BÔNUS';

-- Update default value
ALTER TABLE public.diarias_temporarias ALTER COLUMN motivo_vago SET DEFAULT 'DIÁRIA - FALTA'::motivo_vago_type;

-- ============================================================
-- RECREATE ALL AFFECTED FUNCTIONS
-- ============================================================

CREATE OR REPLACE FUNCTION public.criar_falta_colaborador_convenia()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.motivo_vago = 'DIÁRIA - FALTA'
     AND NEW.colaborador_ausente_convenia IS NOT NULL THEN
    INSERT INTO public.faltas_colaboradores_convenia (
      colaborador_convenia_id, diaria_temporaria_id, data_falta, motivo
    ) VALUES (
      NEW.colaborador_ausente_convenia, NEW.id, NEW.data_diaria, 'DIÁRIA - FALTA'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.sync_falta_colaborador_convenia()
RETURNS TRIGGER AS $$
BEGIN
  IF current_setting('app.rpc_call', true) = 'justificar_falta' THEN
    RETURN NEW;
  END IF;
  IF NEW.motivo_vago = 'DIÁRIA - FALTA' AND NEW.colaborador_ausente_convenia IS NOT NULL THEN
    INSERT INTO public.faltas_colaboradores_convenia (
      colaborador_convenia_id, diaria_temporaria_id, data_falta, motivo
    ) VALUES (
      NEW.colaborador_ausente_convenia, NEW.id, NEW.data_diaria, 'DIÁRIA - FALTA'::motivo_vago_type
    )
    ON CONFLICT (diaria_temporaria_id) WHERE diaria_temporaria_id IS NOT NULL
    DO UPDATE SET
      colaborador_convenia_id = EXCLUDED.colaborador_convenia_id,
      data_falta = EXCLUDED.data_falta,
      motivo = EXCLUDED.motivo,
      updated_at = now()
    WHERE faltas_colaboradores_convenia.motivo = 'DIÁRIA - FALTA';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.sync_falta_from_diaria_temporaria()
RETURNS TRIGGER AS $$
BEGIN
  IF new.colaborador_ausente IS NULL THEN RETURN new; END IF;
  IF new.motivo_vago = 'DIÁRIA - FALTA' THEN
    INSERT INTO public.colaborador_faltas (colaborador_id, diaria_temporaria_id, motivo)
    VALUES (new.colaborador_ausente::uuid, new.id, new.motivo_vago)
    ON CONFLICT (diaria_temporaria_id)
    DO UPDATE SET colaborador_id = excluded.colaborador_id, motivo = excluded.motivo;
  END IF;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.validar_falta_justificada_diaria()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.motivo_vago = 'DIÁRIA - FALTA ATESTADO' THEN
    RAISE EXCEPTION 'Não é permitido criar diária diretamente como DIÁRIA - FALTA ATESTADO. Crie como DIÁRIA - FALTA e justifique via RPC.';
  END IF;
  IF TG_OP = 'UPDATE' 
     AND OLD.motivo_vago = 'DIÁRIA - FALTA'
     AND NEW.motivo_vago = 'DIÁRIA - FALTA ATESTADO'
     AND current_setting('app.rpc_call', true) IS DISTINCT FROM 'justificar_falta' THEN
    RAISE EXCEPTION 'Não é permitido alterar para DIÁRIA - FALTA ATESTADO diretamente. Use a função justificar_falta_convenia com atestado.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.validar_motivos_diaria_temporaria()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.motivo_vago = 'DIÁRIA - SALÁRIO' THEN
    IF NEW.demissao IS NULL THEN
      RAISE EXCEPTION 'O campo "demissao" deve ser informado quando o motivo é DIÁRIA - SALÁRIO';
    END IF;
    IF NEW.demissao = TRUE THEN
      IF NEW.colaborador_demitido_nome IS NULL OR TRIM(NEW.colaborador_demitido_nome) = '' THEN
        RAISE EXCEPTION 'O campo "colaborador demitido" é obrigatório quando for demissão';
      END IF;
      NEW.novo_posto := FALSE;
    ELSE
      NEW.novo_posto := TRUE;
      NEW.colaborador_demitido_nome := NULL;
    END IF;
    NEW.colaborador_ausente_nome := NULL;
  ELSIF NEW.motivo_vago IS NOT NULL THEN
    IF NEW.colaborador_ausente_nome IS NULL OR TRIM(NEW.colaborador_ausente_nome) = '' THEN
      RAISE EXCEPTION 'O campo "colaborador ausente" é obrigatório para este motivo de vaga';
    END IF;
    NEW.demissao := NULL;
    NEW.colaborador_demitido_nome := NULL;
    NEW.novo_posto := NULL;
  ELSE
    NEW.demissao := NULL;
    NEW.colaborador_demitido_nome := NULL;
    NEW.novo_posto := NULL;
    NEW.colaborador_ausente_nome := NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.validate_diarias_temporarias_required_fields()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.motivo_vago = 'DIÁRIA - SALÁRIO' THEN
    IF NEW.demissao IS NULL THEN
      RAISE EXCEPTION 'O campo "demissao" é obrigatório quando o motivo da vaga for "DIÁRIA - SALÁRIO"';
    END IF;
    IF NEW.demissao = TRUE THEN NEW.novo_posto := FALSE;
    ELSE NEW.novo_posto := TRUE; END IF;
    NEW.colaborador_ausente_nome := NULL;
    NEW.colaborador_ausente := NULL;
    NEW.colaborador_ausente_convenia := NULL;
  ELSIF NEW.motivo_vago IS NOT NULL THEN
    NEW.demissao := NULL;
    NEW.colaborador_demitido_nome := NULL;
    NEW.colaborador_demitido := NULL;
    NEW.colaborador_demitido_convenia := NULL;
    NEW.novo_posto := NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.desvincular_colaborador_posto()
RETURNS TRIGGER AS $$
DECLARE
  v_posto_id UUID;
BEGIN
  IF TG_OP = 'DELETE' THEN v_posto_id := OLD.posto_servico_id;
  ELSIF TG_OP = 'UPDATE' AND OLD.posto_servico_id IS NOT NULL AND NEW.posto_servico_id IS NULL THEN
    v_posto_id := OLD.posto_servico_id;
  ELSE RETURN NEW; END IF;
  IF v_posto_id IS NULL THEN
    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;
  DELETE FROM public.posto_dias_vagos WHERE posto_servico_id = v_posto_id AND colaborador_id = OLD.id AND data >= CURRENT_DATE;
  DELETE FROM public.presencas WHERE colaborador_id = OLD.id AND posto_servico_id = v_posto_id AND data >= CURRENT_DATE;
  UPDATE public.dias_trabalho
  SET colaborador_id = NULL, status = 'vago'::status_posto, motivo_vago = 'DIÁRIA - SALÁRIO'::motivo_vago_type, updated_at = now()
  WHERE colaborador_id = OLD.id AND posto_servico_id = v_posto_id AND data >= CURRENT_DATE;
  INSERT INTO public.posto_dias_vagos (posto_servico_id, colaborador_id, data, motivo, created_by)
  SELECT v_posto_id, NULL, data, 'DIÁRIA - SALÁRIO',
    COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
  FROM public.dias_trabalho
  WHERE posto_servico_id = v_posto_id AND colaborador_id IS NULL AND data >= CURRENT_DATE AND status = 'vago'::status_posto
  ON CONFLICT (posto_servico_id, data) WHERE colaborador_id IS NULL
  DO UPDATE SET motivo = 'DIÁRIA - SALÁRIO', created_by = COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid);
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.justificar_falta_convenia(p_diaria_temporaria_id bigint, p_atestado_path text, p_user_id uuid)
RETURNS void AS $$
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
  UPDATE faltas_colaboradores_convenia SET motivo = 'DIÁRIA - FALTA ATESTADO'::motivo_vago_type, atestado_path = p_atestado_path, justificada_em = now(), justificada_por = p_user_id, updated_at = now() WHERE diaria_temporaria_id = p_diaria_temporaria_id;
  UPDATE diarias_temporarias SET motivo_vago = 'DIÁRIA - FALTA ATESTADO'::motivo_vago_type, updated_at = now() WHERE id = p_diaria_temporaria_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.justificar_falta_convenia_por_falta_id(p_falta_id uuid, p_atestado_path text, p_user_id uuid)
RETURNS void AS $$
DECLARE v_level public.internal_access_level; v_diaria_id bigint;
BEGIN
  v_level := public.current_internal_access_level();
  IF v_level IS NULL OR v_level NOT IN ('admin'::public.internal_access_level,'gestor_operacoes'::public.internal_access_level,'supervisor'::public.internal_access_level,'assistente_operacoes'::public.internal_access_level) THEN
    RAISE EXCEPTION 'Sem permissão para justificar faltas.';
  END IF;
  IF p_atestado_path IS NULL OR p_atestado_path = '' THEN RAISE EXCEPTION 'Atestado é obrigatório'; END IF;
  IF NOT EXISTS (SELECT 1 FROM faltas_colaboradores_convenia WHERE id = p_falta_id) THEN RAISE EXCEPTION 'Falta não encontrada'; END IF;
  SELECT diaria_temporaria_id INTO v_diaria_id FROM faltas_colaboradores_convenia WHERE id = p_falta_id;
  PERFORM set_config('app.rpc_call', 'justificar_falta', true);
  UPDATE faltas_colaboradores_convenia SET motivo = 'DIÁRIA - FALTA ATESTADO'::motivo_vago_type, atestado_path = p_atestado_path, justificada_em = now(), justificada_por = p_user_id, updated_at = now() WHERE id = p_falta_id;
  IF v_diaria_id IS NOT NULL THEN
    UPDATE diarias_temporarias SET motivo_vago = 'DIÁRIA - FALTA ATESTADO'::motivo_vago_type, updated_at = now() WHERE id = v_diaria_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.justificar_falta_diaria_temporaria(p_diaria_temporaria_id bigint, p_atestado_path text, p_user_id uuid)
RETURNS void AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.diarias_temporarias WHERE id = p_diaria_temporaria_id AND motivo_vago = 'DIÁRIA - FALTA') THEN
    RAISE EXCEPTION 'Diária inválida ou não está como DIÁRIA - FALTA';
  END IF;
  UPDATE public.diarias_temporarias SET motivo_vago = 'DIÁRIA - FALTA ATESTADO', atestado_path = p_atestado_path, falta_justificada_em = NOW() AT TIME ZONE 'America/Sao_Paulo', falta_justificada_por = p_user_id, updated_at = NOW() AT TIME ZONE 'America/Sao_Paulo' WHERE id = p_diaria_temporaria_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.reverter_justificativa_ao_remover_atestado()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.atestado_path IS NOT NULL AND NEW.atestado_path IS NULL THEN
    PERFORM set_config('app.rpc_call', 'reverter_justificativa', true);
    NEW.justificada_em := NULL;
    NEW.justificada_por := NULL;
    NEW.motivo := 'DIÁRIA - FALTA'::motivo_vago_type;
    NEW.updated_at := now();
    UPDATE diarias_temporarias SET motivo_vago = 'DIÁRIA - FALTA'::motivo_vago_type, updated_at = now() WHERE id = NEW.diaria_temporaria_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.reverter_justificativa_falta_convenia(p_falta_id uuid, p_user_id uuid)
RETURNS text AS $$
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
  IF v_falta.motivo IS DISTINCT FROM 'DIÁRIA - FALTA ATESTADO'::public.motivo_vago_type THEN
    RAISE EXCEPTION 'A falta nao esta como DIÁRIA - FALTA ATESTADO.';
  END IF;
  IF v_falta.atestado_path IS NULL OR btrim(v_falta.atestado_path) = '' THEN RAISE EXCEPTION 'Nao existe atestado vinculado.'; END IF;
  v_atestado_path := v_falta.atestado_path;
  UPDATE public.faltas_colaboradores_convenia SET atestado_path = NULL, motivo = 'DIÁRIA - FALTA'::public.motivo_vago_type, justificada_em = NULL, justificada_por = NULL, updated_at = now() WHERE id = p_falta_id;
  IF v_falta.diaria_temporaria_id IS NOT NULL THEN
    PERFORM set_config('app.rpc_call', 'reverter_justificativa', true);
    UPDATE public.diarias_temporarias SET motivo_vago = 'DIÁRIA - FALTA'::public.motivo_vago_type, updated_at = now() WHERE id = v_falta.diaria_temporaria_id;
  END IF;
  RETURN v_atestado_path;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.criar_diaria_falta_justificada(
  p_cliente_id integer, p_diarista_id uuid, p_data_diaria date, p_valor_diaria numeric, p_unidade text, p_atestado_path text, p_user_id uuid,
  p_colaborador_ausente uuid DEFAULT NULL, p_colaborador_ausente_convenia uuid DEFAULT NULL, p_colaborador_ausente_nome text DEFAULT NULL,
  p_posto_servico_id uuid DEFAULT NULL, p_posto_servico text DEFAULT NULL,
  p_horario_inicio time DEFAULT NULL, p_horario_fim time DEFAULT NULL, p_intervalo integer DEFAULT NULL, p_jornada_diaria numeric DEFAULT NULL, p_observacao text DEFAULT NULL
)
RETURNS bigint AS $$
DECLARE v_diaria_id bigint;
BEGIN
  IF p_atestado_path IS NULL OR p_atestado_path = '' THEN RAISE EXCEPTION 'Diária com DIÁRIA - FALTA ATESTADO exige atestado médico'; END IF;
  IF p_colaborador_ausente IS NULL AND p_colaborador_ausente_convenia IS NULL THEN RAISE EXCEPTION 'Diária de falta exige colaborador vinculado'; END IF;
  INSERT INTO public.diarias_temporarias (
    cliente_id, diarista_id, data_diaria, valor_diaria, unidade, motivo_vago, atestado_path, falta_justificada_em, falta_justificada_por,
    colaborador_ausente, colaborador_ausente_convenia, colaborador_ausente_nome, posto_servico_id, posto_servico,
    horario_inicio, horario_fim, intervalo, jornada_diaria, observacao, criado_por, status
  ) VALUES (
    p_cliente_id, p_diarista_id, p_data_diaria, p_valor_diaria, p_unidade, 'DIÁRIA - FALTA ATESTADO', p_atestado_path,
    NOW() AT TIME ZONE 'America/Sao_Paulo', p_user_id,
    p_colaborador_ausente, p_colaborador_ausente_convenia, p_colaborador_ausente_nome, p_posto_servico_id, p_posto_servico,
    p_horario_inicio, p_horario_fim, p_intervalo, p_jornada_diaria, p_observacao, p_user_id, 'Aguardando confirmacao'
  ) RETURNING id INTO v_diaria_id;
  RETURN v_diaria_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
