-- Remover índice único problemático se existir
DROP INDEX IF EXISTS public.posto_dias_vagos_posto_data_colaborador_unique;

-- Criar constraint de exclusão para posto_dias_vagos
-- Isso permite usar COALESCE no ON CONFLICT
ALTER TABLE public.posto_dias_vagos
DROP CONSTRAINT IF EXISTS posto_dias_vagos_unique_constraint;

ALTER TABLE public.posto_dias_vagos
ADD CONSTRAINT posto_dias_vagos_unique_constraint 
EXCLUDE USING btree (
  posto_servico_id WITH =,
  data WITH =,
  (COALESCE(colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid)) WITH =
);

-- Atualizar função sync_dias_vagos para usar o nome correto da constraint
CREATE OR REPLACE FUNCTION public.sync_dias_vagos()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- Se o dia foi marcado como vago, inserir em posto_dias_vagos
  IF NEW.status = 'dia_vago' AND (OLD IS NULL OR OLD.status != 'dia_vago') THEN
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
      COALESCE(
        (SELECT 'Posto vago' FROM public.postos_servico WHERE id = NEW.posto_servico_id AND status = 'vago'),
        'Dia vago'
      ),
      COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
    )
    ON CONFLICT ON CONSTRAINT posto_dias_vagos_unique_constraint
    DO UPDATE SET motivo = EXCLUDED.motivo;
  
  -- Se o dia foi marcado como ativo, remover de posto_dias_vagos
  ELSIF NEW.status = 'ativo' AND OLD.status = 'dia_vago' THEN
    DELETE FROM public.posto_dias_vagos
    WHERE posto_servico_id = NEW.posto_servico_id
      AND data = NEW.data
      AND COALESCE(colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid) = 
          COALESCE(NEW.colaborador_id, '00000000-0000-0000-0000-000000000000'::uuid);
  END IF;
  
  RETURN NEW;
END;
$function$;