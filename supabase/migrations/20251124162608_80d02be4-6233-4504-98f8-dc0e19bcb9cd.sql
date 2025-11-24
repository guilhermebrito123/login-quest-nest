-- Criar função para sincronizar presencas ao alterar status de dia_trabalho
CREATE OR REPLACE FUNCTION public.sync_presencas_on_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- Se o status mudou de presenca_confirmada para outro status, deletar da tabela presencas
  IF OLD.status = 'presenca_confirmada'::status_posto AND NEW.status != 'presenca_confirmada'::status_posto THEN
    DELETE FROM public.presencas
    WHERE colaborador_id = OLD.colaborador_id
      AND data = OLD.data
      AND posto_servico_id = OLD.posto_servico_id;
  END IF;
  
  -- Se o novo status é vago, inserir em posto_dias_vagos
  IF NEW.status = 'vago'::status_posto AND (OLD.status IS NULL OR OLD.status != 'vago'::status_posto) THEN
    -- Se tem colaborador, usa índice com colaborador
    IF NEW.colaborador_id IS NOT NULL THEN
      INSERT INTO public.posto_dias_vagos (
        posto_servico_id,
        colaborador_id,
        data,
        motivo,
        created_by
      ) VALUES (
        NEW.posto_servico_id,
        NEW.colaborador_id,
        NEW.data,
        COALESCE(NEW.motivo_vago::text, 'Dia vago'),
        COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
      )
      ON CONFLICT (posto_servico_id, data, colaborador_id) 
      WHERE colaborador_id IS NOT NULL
      DO NOTHING;
    ELSE
      -- Se não tem colaborador, usa índice sem colaborador
      INSERT INTO public.posto_dias_vagos (
        posto_servico_id,
        colaborador_id,
        data,
        motivo,
        created_by
      ) VALUES (
        NEW.posto_servico_id,
        NULL,
        NEW.data,
        COALESCE(NEW.motivo_vago::text, 'Posto vago'),
        COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
      )
      ON CONFLICT (posto_servico_id, data) 
      WHERE colaborador_id IS NULL
      DO NOTHING;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Criar trigger para sincronizar presencas ao atualizar dias_trabalho
DROP TRIGGER IF EXISTS sync_presencas_on_dias_trabalho_update ON public.dias_trabalho;
CREATE TRIGGER sync_presencas_on_dias_trabalho_update
  AFTER UPDATE OF status ON public.dias_trabalho
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_presencas_on_status_change();