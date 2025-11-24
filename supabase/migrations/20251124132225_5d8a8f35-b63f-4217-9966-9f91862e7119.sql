-- Criar função para arquivar dias_trabalho em presencas
CREATE OR REPLACE FUNCTION public.arquivar_dias_trabalho_em_presencas()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_data_ontem DATE;
BEGIN
  -- Calcular data de ontem no timezone brasileiro
  v_data_ontem := (now() AT TIME ZONE 'America/Sao_Paulo')::DATE - INTERVAL '1 day';
  
  -- Inserir registros de dias_trabalho com status específicos na tabela presencas
  INSERT INTO public.presencas (
    colaborador_id,
    data,
    horario_entrada,
    horario_saida,
    tipo,
    observacao,
    registrado_por
  )
  SELECT 
    dt.colaborador_id,
    dt.data,
    (dt.data || ' ' || dt.horario_inicio)::timestamp with time zone,
    (dt.data || ' ' || dt.horario_fim)::timestamp with time zone,
    'presente',
    'Arquivado automaticamente - Status: ' || dt.status::text,
    '00000000-0000-0000-0000-000000000000'::uuid
  FROM public.dias_trabalho dt
  WHERE dt.data = v_data_ontem
    AND dt.colaborador_id IS NOT NULL
    AND dt.status IN ('ocupado'::status_posto, 'ocupado_temporariamente'::status_posto, 'presenca_confirmada'::status_posto)
  ON CONFLICT (colaborador_id, data) DO NOTHING;
END;
$function$;

-- Agendar execução diária às 00:01 BRT (03:01 UTC)
SELECT cron.schedule(
  'arquivar-dias-trabalho-presencas',
  '1 3 * * *',
  $$SELECT public.arquivar_dias_trabalho_em_presencas();$$
);