
-- Create the enum (if not exists - use DO block)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'operacao_hora_extra') THEN
    CREATE TYPE public.operacao_hora_extra AS ENUM (
      'cobertura_falta',
      'cobertura_falta_atestado',
      'cobertura_ferias',
      'cobertura_afastamento_inss',
      'cobertura_licenca',
      'demanda_extra',
      'bonus',
      'dobra_turno',
      'extensao_jornada',
      'outros'
    );
  END IF;
END$$;

-- Alter the column from text to the new enum
ALTER TABLE public.horas_extras
  ALTER COLUMN operacao TYPE public.operacao_hora_extra
  USING operacao::public.operacao_hora_extra;

-- Update the RPC criar_hora_extra to use the new enum type
CREATE OR REPLACE FUNCTION public.criar_hora_extra(
  p_falta_id bigint,
  p_colaborador_cobrindo_id uuid,
  p_operacao public.operacao_hora_extra,
  p_inicio_em timestamptz,
  p_fim_em timestamptz,
  p_intervalo_inicio_em timestamptz default null,
  p_intervalo_fim_em timestamptz default null,
  p_observacao text default null
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.internal_access_level;
  v_id uuid;
BEGIN
  v_role := public.current_internal_access_level();

  IF v_role IN ('assistente_financeiro', 'gestor_financeiro', 'cliente_view') THEN
    RAISE EXCEPTION 'Usuário sem permissão para cadastrar hora extra';
  END IF;

  INSERT INTO public.horas_extras (
    falta_id,
    colaborador_cobrindo_id,
    cost_center_id,
    operacao,
    inicio_em,
    intervalo_inicio_em,
    intervalo_fim_em,
    fim_em,
    observacao,
    status,
    criado_por
  )
  VALUES (
    p_falta_id,
    p_colaborador_cobrindo_id,
    '00000000-0000-0000-0000-000000000000'::uuid,
    p_operacao,
    p_inicio_em,
    p_intervalo_inicio_em,
    p_intervalo_fim_em,
    p_fim_em,
    p_observacao,
    'pendente',
    auth.uid()
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;
