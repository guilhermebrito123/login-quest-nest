-- Função para processar agendamento de vinculação imediatamente
CREATE OR REPLACE FUNCTION public.processar_agendamento_vinculacao()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- Processar vinculação agendada
  IF NEW.data_vinculacao IS NOT NULL AND NEW.posto_servico_id_destino IS NOT NULL THEN
    -- Atualizar dias_trabalho para ocupado a partir da data de vinculação
    UPDATE public.dias_trabalho
    SET colaborador_id = NEW.colaborador_id,
        status = 'ocupado'::status_posto,
        motivo_vago = NULL,
        updated_at = now()
    WHERE posto_servico_id = NEW.posto_servico_id_destino
      AND data >= NEW.data_vinculacao
      AND colaborador_id IS NULL;
    
    -- Deletar dias de posto_dias_vagos a partir da data de vinculação
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.posto_servico_id_destino
      AND data >= NEW.data_vinculacao;
  END IF;
  
  -- Processar desvinculação agendada
  IF NEW.data_desvinculacao IS NOT NULL AND NEW.posto_servico_id_origem IS NOT NULL THEN
    -- Atualizar dias_trabalho para vago a partir da data de desvinculação
    UPDATE public.dias_trabalho
    SET colaborador_id = NULL,
        status = 'vago'::status_posto,
        motivo_vago = 'Posto vago'::motivo_vago_type,
        updated_at = now()
    WHERE posto_servico_id = NEW.posto_servico_id_origem
      AND colaborador_id = NEW.colaborador_id
      AND data >= NEW.data_desvinculacao;
    
    -- Inserir dias em posto_dias_vagos a partir da data de desvinculação
    INSERT INTO public.posto_dias_vagos (
      posto_servico_id,
      colaborador_id,
      data,
      motivo,
      created_by
    )
    SELECT 
      NEW.posto_servico_id_origem,
      NULL,
      data,
      'Posto vago',
      NEW.created_by
    FROM public.dias_trabalho
    WHERE posto_servico_id = NEW.posto_servico_id_origem
      AND colaborador_id IS NULL
      AND data >= NEW.data_desvinculacao
    ON CONFLICT (posto_servico_id, data) 
    WHERE colaborador_id IS NULL
    DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Criar trigger para processar agendamentos imediatamente ao inserir
CREATE TRIGGER trigger_processar_agendamento_vinculacao
AFTER INSERT ON public.colaborador_movimentacoes_posto
FOR EACH ROW
EXECUTE FUNCTION public.processar_agendamento_vinculacao();