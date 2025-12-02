-- Corrigir trigger sync_dias_vagos para evitar duplicação
DROP TRIGGER IF EXISTS sync_dias_vagos_trg ON public.dias_trabalho;

CREATE OR REPLACE FUNCTION public.sync_dias_vagos()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.status = 'vago'::status_posto AND (OLD IS NULL OR OLD.status != 'vago'::status_posto) THEN
    -- Inserir apenas UMA vez: se tem colaborador, usa índice com colaborador; se não tem, usa índice sem colaborador
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
  
  ELSIF NEW.status = 'ocupado'::status_posto AND OLD.status = 'vago'::status_posto THEN
    -- Deletar apenas o registro correspondente ao colaborador_id
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.posto_servico_id
      AND data = NEW.data
      AND (
        (NEW.colaborador_id IS NOT NULL AND colaborador_id = NEW.colaborador_id)
        OR (NEW.colaborador_id IS NULL AND colaborador_id IS NULL)
      );
  END IF;
  
  RETURN NEW;
END;
$function$;

CREATE TRIGGER sync_dias_vagos_trg
AFTER INSERT OR UPDATE ON public.dias_trabalho
FOR EACH ROW
EXECUTE FUNCTION public.sync_dias_vagos();

-- Corrigir trigger sync_presencas_on_status_change para evitar duplicação
DROP TRIGGER IF EXISTS sync_presencas_on_status_change_trg ON public.dias_trabalho;

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
  
  -- Se o novo status é vago, NÃO inserir aqui - deixar o sync_dias_vagos fazer isso
  -- Remover lógica duplicada que causava a duplicação
  
  RETURN NEW;
END;
$function$;

CREATE TRIGGER sync_presencas_on_status_change_trg
AFTER UPDATE ON public.dias_trabalho
FOR EACH ROW
EXECUTE FUNCTION public.sync_presencas_on_status_change();