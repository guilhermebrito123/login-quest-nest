
-- 1. Remover o índice único que impedia mais de uma diária ativa por diarista+data
DROP INDEX IF EXISTS public.uniq_diaria_ativa_por_diarista_data;

-- 2. Substituir a função de validação de duplicidade por validação de sobreposição de horários
CREATE OR REPLACE FUNCTION public.validar_duplicidade_diaria_temporaria()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_conflito RECORD;
BEGIN
  -- Ignorar registros cancelados/reprovados
  IF NEW.status IN ('Cancelada', 'Reprovada') THEN
    RETURN NEW;
  END IF;

  -- Verificar se existe outra diária ativa do mesmo diarista na mesma data
  FOR v_conflito IN
    SELECT id, horario_inicio, horario_fim
    FROM public.diarias_temporarias
    WHERE diarista_id = NEW.diarista_id
      AND data_diaria = NEW.data_diaria
      AND id <> COALESCE(NEW.id, -1)
      AND status NOT IN ('Cancelada', 'Reprovada')
  LOOP
    -- Se a diária existente ou a nova não tiver horários definidos, bloquear
    IF v_conflito.horario_inicio IS NULL OR v_conflito.horario_fim IS NULL
       OR NEW.horario_inicio IS NULL OR NEW.horario_fim IS NULL THEN
      RAISE EXCEPTION 'Este diarista já possui uma diária ativa para esta data. Informe os horários de início e fim para permitir múltiplas diárias no mesmo dia.';
    END IF;

    -- Verificar sobreposição de horários (suporta turnos noturnos que cruzam meia-noite)
    IF NEW.horario_fim > NEW.horario_inicio AND v_conflito.horario_fim > v_conflito.horario_inicio THEN
      -- Ambos são turnos diurnos (não cruzam meia-noite)
      IF NEW.horario_inicio < v_conflito.horario_fim AND NEW.horario_fim > v_conflito.horario_inicio THEN
        RAISE EXCEPTION 'Conflito de horário: este diarista já possui uma diária das % às % nesta data.', v_conflito.horario_inicio, v_conflito.horario_fim;
      END IF;
    ELSE
      -- Pelo menos um dos turnos cruza meia-noite: tratamento especial
      -- Turno noturno é representado como horario_fim <= horario_inicio (ex: 22:00 - 06:00)
      -- Neste caso, a verificação conservadora bloqueia sobreposição
      IF NEW.horario_fim <= NEW.horario_inicio THEN
        -- Novo turno é noturno: conflita se o existente começa antes do fim do novo OU termina depois do início do novo
        IF v_conflito.horario_fim <= v_conflito.horario_inicio THEN
          -- Ambos noturnos: sempre conflitam (dois turnos noturnos no mesmo dia)
          RAISE EXCEPTION 'Conflito de horário: este diarista já possui uma diária noturna das % às % nesta data.', v_conflito.horario_inicio, v_conflito.horario_fim;
        ELSE
          -- Novo noturno, existente diurno
          IF v_conflito.horario_fim > NEW.horario_inicio OR v_conflito.horario_inicio < NEW.horario_fim THEN
            RAISE EXCEPTION 'Conflito de horário: este diarista já possui uma diária das % às % nesta data.', v_conflito.horario_inicio, v_conflito.horario_fim;
          END IF;
        END IF;
      ELSE
        -- Novo turno é diurno, existente é noturno
        IF NEW.horario_fim > v_conflito.horario_inicio OR NEW.horario_inicio < v_conflito.horario_fim THEN
          RAISE EXCEPTION 'Conflito de horário: este diarista já possui uma diária das % às % nesta data.', v_conflito.horario_inicio, v_conflito.horario_fim;
        END IF;
      END IF;
    END IF;
  END LOOP;

  RETURN NEW;
END;
$function$;
