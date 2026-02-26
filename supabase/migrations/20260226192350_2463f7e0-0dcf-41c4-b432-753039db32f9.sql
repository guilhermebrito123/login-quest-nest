CREATE OR REPLACE FUNCTION public.justificar_falta_convenia_por_falta_id(
  p_atestado_path text,
  p_falta_id bigint,
  p_user_id uuid
)
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

  IF NOT EXISTS (
    SELECT 1 FROM public.faltas_colaboradores_convenia WHERE id = p_falta_id
  ) THEN
    RAISE EXCEPTION 'Registro de falta não encontrado';
  END IF;

  SELECT diaria_temporaria_id INTO v_diaria_id
  FROM public.faltas_colaboradores_convenia
  WHERE id = p_falta_id;

  PERFORM set_config('app.rpc_call', 'justificar_falta', true);

  UPDATE public.faltas_colaboradores_convenia
  SET 
    motivo = 'DIÁRIA - FALTA ATESTADO'::public.motivo_vago_type,
    atestado_path = p_atestado_path,
    justificada_em = now(),
    justificada_por = p_user_id,
    updated_at = now()
  WHERE id = p_falta_id;

  IF v_diaria_id IS NOT NULL THEN
    UPDATE public.diarias_temporarias
    SET 
      motivo_vago = 'DIÁRIA - FALTA ATESTADO'::public.motivo_vago_type,
      updated_at = now()
    WHERE id = v_diaria_id;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.justificar_falta_convenia_por_falta_id(text, bigint, uuid) TO authenticated;