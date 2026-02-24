
-- Criar RPC para justificar falta por falta_id (para faltas sem diária vinculada)
CREATE OR REPLACE FUNCTION public.justificar_falta_convenia_por_falta_id(
  p_atestado_path text,
  p_falta_id bigint,
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_level public.internal_access_level;
  v_diaria_id bigint;
BEGIN
  -- Verificar permissão do usuário
  v_level := public.current_internal_access_level();
  IF v_level IS NULL OR v_level NOT IN (
    'admin'::public.internal_access_level,
    'gestor_operacoes'::public.internal_access_level,
    'supervisor'::public.internal_access_level,
    'assistente_operacoes'::public.internal_access_level
  ) THEN
    RAISE EXCEPTION 'Sem permissão para justificar faltas.';
  END IF;

  -- Validar que o atestado foi fornecido
  IF p_atestado_path IS NULL OR p_atestado_path = '' THEN
    RAISE EXCEPTION 'Atestado é obrigatório para justificar falta';
  END IF;

  -- Verificar se a falta existe
  IF NOT EXISTS (
    SELECT 1 FROM faltas_colaboradores_convenia WHERE id = p_falta_id
  ) THEN
    RAISE EXCEPTION 'Registro de falta não encontrado';
  END IF;

  -- Buscar diaria_temporaria_id associada (pode ser NULL)
  SELECT diaria_temporaria_id INTO v_diaria_id
  FROM faltas_colaboradores_convenia
  WHERE id = p_falta_id;

  -- Setar configuração para bypass da trigger
  PERFORM set_config('app.rpc_call', 'justificar_falta', true);

  -- Atualizar a falta para justificada
  UPDATE faltas_colaboradores_convenia
  SET 
    motivo = 'FALTA JUSTIFICADA'::motivo_vago_type,
    atestado_path = p_atestado_path,
    justificada_em = now(),
    justificada_por = p_user_id,
    updated_at = now()
  WHERE id = p_falta_id;

  -- Se houver diária vinculada, atualizar também
  IF v_diaria_id IS NOT NULL THEN
    UPDATE diarias_temporarias
    SET 
      motivo_vago = 'FALTA JUSTIFICADA'::motivo_vago_type,
      updated_at = now()
    WHERE id = v_diaria_id;
  END IF;
END;
$$;

-- Permissão para usuários autenticados
GRANT EXECUTE ON FUNCTION public.justificar_falta_convenia_por_falta_id(text, bigint, uuid) TO authenticated;
