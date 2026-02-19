
-- Atualizar a RPC justificar_falta_convenia para incluir verificação de permissão com assistente_operacoes
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
BEGIN
  -- Verificar permissão do usuário
  v_level := public.current_internal_access_level();
  IF v_level IS NULL OR v_level NOT IN (
    'admin'::public.internal_access_level,
    'gestor_operacoes'::public.internal_access_level,
    'supervisor'::public.internal_access_level,
    'assistente_operacoes'::public.internal_access_level
  ) THEN
    RAISE EXCEPTION 'Sem permissão para justificar faltas. Requer admin, gestor_operacoes, supervisor ou assistente_operacoes.';
  END IF;

  -- Validar que o atestado foi fornecido
  IF p_atestado_path IS NULL OR p_atestado_path = '' THEN
    RAISE EXCEPTION 'Atestado médico é obrigatório para justificar falta';
  END IF;

  -- Verificar se existe uma falta para essa diária
  IF NOT EXISTS (
    SELECT 1 FROM faltas_colaboradores_convenia 
    WHERE diaria_temporaria_id = p_diaria_temporaria_id
  ) THEN
    RAISE EXCEPTION 'Não existe registro de falta para esta diária';
  END IF;

  -- Setar configuração para indicar que estamos na RPC (permite bypass da trigger)
  PERFORM set_config('app.rpc_call', 'justificar_falta', true);

  -- Atualizar a falta para justificada
  UPDATE faltas_colaboradores_convenia
  SET 
    motivo = 'FALTA JUSTIFICADA'::motivo_vago_type,
    atestado_path = p_atestado_path,
    justificada_em = now(),
    justificada_por = p_user_id,
    updated_at = now()
  WHERE diaria_temporaria_id = p_diaria_temporaria_id;

  -- Atualizar o motivo_vago da diarias_temporarias para FALTA JUSTIFICADA
  UPDATE diarias_temporarias
  SET 
    motivo_vago = 'FALTA JUSTIFICADA'::motivo_vago_type,
    updated_at = now()
  WHERE id = p_diaria_temporaria_id;

END;
$$;
