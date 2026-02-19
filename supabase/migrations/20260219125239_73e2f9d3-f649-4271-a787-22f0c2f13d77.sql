
CREATE OR REPLACE FUNCTION public.reverter_justificativa_falta_convenia(
  p_falta_id bigint,
  p_user_id uuid,
  p_bucket_id text DEFAULT 'atestados'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_level public.internal_access_level;
  v_falta public.faltas_colaboradores_convenia%ROWTYPE;
  v_obj_name text;
BEGIN
  IF p_user_id <> auth.uid() THEN
    RAISE EXCEPTION 'Usuário inválido.';
  END IF;

  v_level := public.current_internal_access_level();

  IF v_level IS NULL THEN
    RAISE EXCEPTION 'Usuário não possui perfil interno.';
  END IF;

  IF NOT (v_level = ANY(ARRAY[
    'admin',
    'gestor_operacoes',
    'supervisor',
    'assistente_operacoes',
    'analista_centro_controle'
  ]::public.internal_access_level[])) THEN
    RAISE EXCEPTION 'Sem permissão para reverter justificativa.';
  END IF;

  SELECT *
    INTO v_falta
  FROM public.faltas_colaboradores_convenia
  WHERE id = p_falta_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Falta não encontrada (id=%).', p_falta_id;
  END IF;

  IF v_falta.motivo IS DISTINCT FROM 'FALTA JUSTIFICADA'::public.motivo_vago_type THEN
    RAISE EXCEPTION 'A falta não está como FALTA JUSTIFICADA.';
  END IF;

  IF v_falta.atestado_path IS NULL OR btrim(v_falta.atestado_path) = '' THEN
    RAISE EXCEPTION 'Não existe atestado vinculado a esta falta.';
  END IF;

  v_obj_name := v_falta.atestado_path;

  DELETE FROM storage.objects
  WHERE bucket_id = p_bucket_id
    AND name = v_obj_name;

  UPDATE public.faltas_colaboradores_convenia
  SET
    atestado_path = NULL,
    motivo = 'FALTA INJUSTIFICADA'::public.motivo_vago_type,
    justificada_em = NULL,
    justificada_por = NULL,
    updated_at = now()
  WHERE id = p_falta_id;

  PERFORM set_config('app.rpc_call', 'reverter_justificativa', true);

  UPDATE public.diarias_temporarias
  SET
    motivo_vago = 'FALTA INJUSTIFICADA'::public.motivo_vago_type,
    updated_at = now()
  WHERE id = v_falta.diaria_temporaria_id;

END;
$$;

GRANT EXECUTE ON FUNCTION public.reverter_justificativa_falta_convenia(bigint, uuid, text)
TO authenticated;
