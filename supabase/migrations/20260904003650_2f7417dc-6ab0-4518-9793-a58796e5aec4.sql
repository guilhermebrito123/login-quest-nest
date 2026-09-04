CREATE OR REPLACE FUNCTION public.bloquear_troca_motivo_diaria_com_falta()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rpc text;
  v_falta_id bigint;
  v_data date;
  v_nome text;
BEGIN
  IF OLD.motivo_vago IS DISTINCT FROM NEW.motivo_vago
     AND OLD.motivo_vago IN ('DIÁRIA - FALTA'::public.motivo_vago_type, 'DIÁRIA - FALTA ATESTADO'::public.motivo_vago_type)
     AND (NEW.motivo_vago IS NULL
          OR NEW.motivo_vago NOT IN ('DIÁRIA - FALTA'::public.motivo_vago_type, 'DIÁRIA - FALTA ATESTADO'::public.motivo_vago_type))
  THEN
    v_rpc := current_setting('app.rpc_call', true);

    IF v_rpc IN ('justificar_falta', 'reverter_justificativa', 'true') THEN
      RETURN NEW;
    END IF;

    IF NEW.status IN ('Cancelada'::public.status_diaria, 'Reprovada'::public.status_diaria) THEN
      RETURN NEW;
    END IF;

    SELECT f.id, f.data_falta, TRIM(CONCAT_WS(' ', c.name, c.last_name))
      INTO v_falta_id, v_data, v_nome
    FROM public.faltas_colaboradores_convenia f
    LEFT JOIN public.colaboradores_convenia c ON c.id = f.colaborador_convenia_id
    WHERE f.diaria_temporaria_id = NEW.id
    ORDER BY f.id
    LIMIT 1;

    IF v_falta_id IS NOT NULL THEN
      RAISE EXCEPTION 'Não é possível alterar o motivo desta diária: existe a falta #% vinculada ao colaborador % (data: %). Para corrigir o motivo, é necessário primeiro excluir essa falta. Atenção: a exclusão da falta também removerá esta diária automaticamente, e será necessário recriá-la com o motivo correto.',
        v_falta_id,
        COALESCE(NULLIF(v_nome, ''), 'não identificado'),
        to_char(v_data, 'DD/MM/YYYY');
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_a_bloquear_troca_motivo_diaria_com_falta ON public.diarias_temporarias;
CREATE TRIGGER trg_a_bloquear_troca_motivo_diaria_com_falta
BEFORE UPDATE ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.bloquear_troca_motivo_diaria_com_falta();

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
DECLARE
  v_level public.internal_access_level;
  v_motivo_diaria public.motivo_vago_type;
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
    RAISE EXCEPTION 'Atestado médico é obrigatório';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.faltas_colaboradores_convenia
    WHERE diaria_temporaria_id = p_diaria_temporaria_id
  ) THEN
    RAISE EXCEPTION 'Não existe registro de falta para esta diária';
  END IF;

  SELECT motivo_vago INTO v_motivo_diaria
  FROM public.diarias_temporarias
  WHERE id = p_diaria_temporaria_id;

  IF v_motivo_diaria IS NULL
     OR v_motivo_diaria NOT IN (
       'DIÁRIA - FALTA'::public.motivo_vago_type,
       'DIÁRIA - FALTA ATESTADO'::public.motivo_vago_type
     ) THEN
    RAISE EXCEPTION 'A diária vinculada a esta falta não é mais uma diária de falta (motivo atual: %). Desvincule ou corrija a diária antes de justificar a falta.',
      COALESCE(v_motivo_diaria::text, 'não informado');
  END IF;

  PERFORM set_config('app.rpc_call', 'justificar_falta', true);

  UPDATE public.faltas_colaboradores_convenia
  SET motivo = 'FALTA JUSTIFICADA',
      atestado_path = p_atestado_path,
      justificada_em = now(),
      justificada_por = p_user_id,
      updated_at = now()
  WHERE diaria_temporaria_id = p_diaria_temporaria_id;

  UPDATE public.diarias_temporarias
  SET motivo_vago = 'DIÁRIA - FALTA ATESTADO'::public.motivo_vago_type,
      updated_at = now()
  WHERE id = p_diaria_temporaria_id;
END;
$$;