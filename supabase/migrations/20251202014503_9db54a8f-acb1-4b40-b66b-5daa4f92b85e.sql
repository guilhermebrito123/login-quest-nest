CREATE OR REPLACE FUNCTION public.sync_dias_vagos()
 RETURNS trigger
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
      -- Antes de inserir um registro genérico (sem colaborador), remover registros específicos
      -- do mesmo posto e data que ainda não possuem diárias vinculadas, evitando duplicação.
      DELETE FROM public.posto_dias_vagos pdv
      WHERE pdv.posto_servico_id = NEW.posto_servico_id
        AND pdv.data = NEW.data
        AND pdv.colaborador_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1
          FROM public.diarias d
          WHERE d.posto_dia_vago_id = pdv.id
        );

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