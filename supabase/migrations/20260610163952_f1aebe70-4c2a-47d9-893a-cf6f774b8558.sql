CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE OR REPLACE FUNCTION public.validar_duplicidade_diaria_temporaria()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_conflito RECORD;
BEGIN
  IF NEW.status IN ('Cancelada', 'Reprovada') THEN
    RETURN NEW;
  END IF;

  IF NEW.diarista_id IS NOT NULL AND NEW.data_diaria IS NOT NULL THEN
    PERFORM pg_advisory_xact_lock(
      hashtextextended(NEW.diarista_id::text || '|' || NEW.data_diaria::text, 0)
    );
  END IF;

  FOR v_conflito IN
    SELECT id, horario_inicio, horario_fim
    FROM public.diarias_temporarias
    WHERE diarista_id = NEW.diarista_id
      AND data_diaria = NEW.data_diaria
      AND id <> COALESCE(NEW.id, -1)
      AND status NOT IN ('Cancelada', 'Reprovada')
  LOOP
    IF v_conflito.horario_inicio IS NULL OR v_conflito.horario_fim IS NULL
       OR NEW.horario_inicio IS NULL OR NEW.horario_fim IS NULL THEN
      RAISE EXCEPTION 'Este diarista já possui uma diária ativa para esta data. Informe os horários de início e fim para permitir múltiplas diárias no mesmo dia.';
    END IF;

    IF NEW.horario_fim > NEW.horario_inicio AND v_conflito.horario_fim > v_conflito.horario_inicio THEN
      IF NEW.horario_inicio < v_conflito.horario_fim AND NEW.horario_fim > v_conflito.horario_inicio THEN
        RAISE EXCEPTION 'Conflito de horário: este diarista já possui uma diária das % às % nesta data.', v_conflito.horario_inicio, v_conflito.horario_fim;
      END IF;
    ELSE
      IF NEW.horario_fim <= NEW.horario_inicio THEN
        IF v_conflito.horario_fim <= v_conflito.horario_inicio THEN
          RAISE EXCEPTION 'Conflito de horário: este diarista já possui uma diária noturna das % às % nesta data.', v_conflito.horario_inicio, v_conflito.horario_fim;
        ELSE
          IF v_conflito.horario_fim > NEW.horario_inicio OR v_conflito.horario_inicio < NEW.horario_fim THEN
            RAISE EXCEPTION 'Conflito de horário: este diarista já possui uma diária das % às % nesta data.', v_conflito.horario_inicio, v_conflito.horario_fim;
          END IF;
        END IF;
      ELSE
        IF NEW.horario_fim > v_conflito.horario_inicio OR NEW.horario_inicio < v_conflito.horario_fim THEN
          RAISE EXCEPTION 'Conflito de horário: este diarista já possui uma diária das % às % nesta data.', v_conflito.horario_inicio, v_conflito.horario_fim;
        END IF;
      END IF;
    END IF;
  END LOOP;

  RETURN NEW;
END;
$function$;

ALTER TABLE public.diarias_temporarias
  ADD CONSTRAINT diarias_temporarias_no_overlap
  EXCLUDE USING gist (
    diarista_id WITH =,
    data_diaria WITH =,
    tsrange(
      (data_diaria + horario_inicio)::timestamp,
      (data_diaria + horario_fim)::timestamp
        + CASE WHEN horario_fim <= horario_inicio THEN interval '1 day' ELSE interval '0' END,
      '[)'
    ) WITH &&
  )
  WHERE (status NOT IN ('Cancelada','Reprovada')
         AND diarista_id IS NOT NULL
         AND horario_inicio IS NOT NULL
         AND horario_fim IS NOT NULL);