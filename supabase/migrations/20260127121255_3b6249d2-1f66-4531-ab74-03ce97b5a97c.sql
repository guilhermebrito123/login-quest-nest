-- Dropar função existente para recriar com novos parâmetros
DROP FUNCTION IF EXISTS public.justificar_falta_diaria_temporaria(bigint, text, uuid);

-- 3️⃣ FUNÇÃO PARA JUSTIFICAR FALTA (OPERAÇÃO ATÔMICA)
CREATE OR REPLACE FUNCTION public.justificar_falta_diaria_temporaria(
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
  -- Valida se a diária existe e está como falta injustificada
  IF NOT EXISTS (
    SELECT 1
    FROM public.diarias_temporarias
    WHERE id = p_diaria_temporaria_id
      AND motivo_vago = 'FALTA INJUSTIFICADA'
  ) THEN
    RAISE EXCEPTION 'Diária inválida ou não está como FALTA INJUSTIFICADA';
  END IF;

  -- Atualiza a diária
  UPDATE public.diarias_temporarias
  SET
    motivo_vago = 'FALTA JUSTIFICADA',
    atestado_path = p_atestado_path,
    falta_justificada_em = NOW() AT TIME ZONE 'America/Sao_Paulo',
    falta_justificada_por = p_user_id,
    updated_at = NOW() AT TIME ZONE 'America/Sao_Paulo'
  WHERE id = p_diaria_temporaria_id;
END;
$$;

-- Conceder permissão para usuários autenticados chamarem a função
GRANT EXECUTE ON FUNCTION public.justificar_falta_diaria_temporaria(bigint, text, uuid) TO authenticated;

-- 5️⃣ FUNÇÃO AUXILIAR PARA CRIAR DIÁRIA COM FALTA JUSTIFICADA (já com atestado)
DROP FUNCTION IF EXISTS public.criar_diaria_falta_justificada(integer, uuid, date, numeric, text, text, uuid, uuid, text, uuid, text, time, time, integer, numeric, text, uuid);

CREATE OR REPLACE FUNCTION public.criar_diaria_falta_justificada(
  p_cliente_id integer,
  p_diarista_id uuid,
  p_data_diaria date,
  p_valor_diaria numeric,
  p_unidade text,
  p_atestado_path text,
  p_colaborador_ausente uuid DEFAULT NULL,
  p_colaborador_ausente_convenia uuid DEFAULT NULL,
  p_colaborador_ausente_nome text DEFAULT NULL,
  p_posto_servico_id uuid DEFAULT NULL,
  p_posto_servico text DEFAULT NULL,
  p_horario_inicio time DEFAULT NULL,
  p_horario_fim time DEFAULT NULL,
  p_intervalo integer DEFAULT NULL,
  p_jornada_diaria numeric DEFAULT NULL,
  p_observacao text DEFAULT NULL,
  p_user_id uuid DEFAULT NULL
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_diaria_id bigint;
BEGIN
  -- Validar que tem atestado
  IF p_atestado_path IS NULL OR p_atestado_path = '' THEN
    RAISE EXCEPTION 'Diária com FALTA JUSTIFICADA exige atestado médico';
  END IF;
  
  -- Validar que tem colaborador vinculado
  IF p_colaborador_ausente IS NULL AND p_colaborador_ausente_convenia IS NULL THEN
    RAISE EXCEPTION 'Diária de falta exige colaborador vinculado';
  END IF;

  INSERT INTO public.diarias_temporarias (
    cliente_id,
    diarista_id,
    data_diaria,
    valor_diaria,
    unidade,
    motivo_vago,
    atestado_path,
    falta_justificada_em,
    falta_justificada_por,
    colaborador_ausente,
    colaborador_ausente_convenia,
    colaborador_ausente_nome,
    posto_servico_id,
    posto_servico,
    horario_inicio,
    horario_fim,
    intervalo,
    jornada_diaria,
    observacao,
    criado_por,
    status
  ) VALUES (
    p_cliente_id,
    p_diarista_id,
    p_data_diaria,
    p_valor_diaria,
    p_unidade,
    'FALTA JUSTIFICADA',
    p_atestado_path,
    NOW() AT TIME ZONE 'America/Sao_Paulo',
    p_user_id,
    p_colaborador_ausente,
    p_colaborador_ausente_convenia,
    p_colaborador_ausente_nome,
    p_posto_servico_id,
    p_posto_servico,
    p_horario_inicio,
    p_horario_fim,
    p_intervalo,
    p_jornada_diaria,
    p_observacao,
    p_user_id,
    'Aguardando confirmacao'
  )
  RETURNING id INTO v_diaria_id;

  RETURN v_diaria_id;
END;
$$;

-- Conceder permissão para usuários autenticados
GRANT EXECUTE ON FUNCTION public.criar_diaria_falta_justificada(
  integer, uuid, date, numeric, text, text, uuid, uuid, text, uuid, text, time, time, integer, numeric, text, uuid
) TO authenticated;