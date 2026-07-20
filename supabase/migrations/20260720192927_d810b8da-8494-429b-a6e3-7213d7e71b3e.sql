
ALTER TABLE public.diaristas_historico
  ADD COLUMN IF NOT EXISTS alterado_por uuid REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_diaristas_historico_alterado_por
  ON public.diaristas_historico(alterado_por);

CREATE OR REPLACE FUNCTION public.fn_registrar_historico_diarista()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  k TEXT;
  old_json JSONB := to_jsonb(OLD);
  new_json JSONB := to_jsonb(NEW);
  motivo TEXT;
  status_mudando_para_restrito BOOLEAN;
  autor uuid := auth.uid();
BEGIN
  status_mudando_para_restrito := (
    OLD.status IS DISTINCT FROM NEW.status
    AND NEW.status = 'restrito'
  );

  IF NOT status_mudando_para_restrito THEN
    IF NEW.motivo_alteracao IS NULL
       OR btrim(NEW.motivo_alteracao) = '' THEN
      RAISE EXCEPTION
        'Atualização bloqueada: informe o motivo da alteração.';
    END IF;
  END IF;

  IF status_mudando_para_restrito AND (NEW.motivo_alteracao IS NULL OR btrim(NEW.motivo_alteracao) = '') THEN
    motivo := 'Status alterado para restrito';
  ELSE
    motivo := NEW.motivo_alteracao;
  END IF;

  FOR k IN
    SELECT jsonb_object_keys(new_json)
  LOOP
    IF k = 'motivo_alteracao' THEN
      CONTINUE;
    END IF;

    IF (old_json -> k) IS DISTINCT FROM (new_json -> k) THEN
      INSERT INTO public.diaristas_historico (
        diarista_id,
        campo_alterado,
        valor_anterior,
        valor_novo,
        motivo,
        alterado_por
      )
      VALUES (
        OLD.id,
        k,
        old_json ->> k,
        new_json ->> k,
        motivo,
        autor
      );
    END IF;
  END LOOP;

  NEW.motivo_alteracao := NULL;

  RETURN NEW;
END;
$function$;
