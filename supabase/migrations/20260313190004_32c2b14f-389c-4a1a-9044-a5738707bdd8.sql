-- 1) Garantir unicidade de falta vinculada por diária temporária (uma falta por diária)
WITH ranked AS (
  SELECT
    id,
    diaria_temporaria_id,
    row_number() OVER (
      PARTITION BY diaria_temporaria_id
      ORDER BY
        CASE WHEN motivo = 'FALTA JUSTIFICADA' THEN 0 ELSE 1 END,
        justificada_em DESC NULLS LAST,
        updated_at DESC NULLS LAST,
        created_at DESC NULLS LAST,
        id DESC
    ) AS rn
  FROM public.faltas_colaboradores_convenia
  WHERE diaria_temporaria_id IS NOT NULL
)
DELETE FROM public.faltas_colaboradores_convenia f
USING ranked r
WHERE f.id = r.id
  AND r.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS ux_faltas_por_diaria_unica
  ON public.faltas_colaboradores_convenia (diaria_temporaria_id)
  WHERE diaria_temporaria_id IS NOT NULL;

-- 2) Função de criação inicial da falta (INSERT em diária): upsert por diária vinculada
CREATE OR REPLACE FUNCTION public.criar_falta_colaborador_convenia()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.motivo_vago = 'DIÁRIA - FALTA'
     AND NEW.colaborador_ausente_convenia IS NOT NULL THEN
    INSERT INTO public.faltas_colaboradores_convenia (
      colaborador_convenia_id,
      diaria_temporaria_id,
      data_falta,
      motivo
    ) VALUES (
      NEW.colaborador_ausente_convenia,
      NEW.id,
      NEW.data_diaria,
      'FALTA INJUSTIFICADA'
    )
    ON CONFLICT (diaria_temporaria_id)
    WHERE diaria_temporaria_id IS NOT NULL
    DO UPDATE SET
      colaborador_convenia_id = EXCLUDED.colaborador_convenia_id,
      data_falta = EXCLUDED.data_falta,
      updated_at = now()
    WHERE public.faltas_colaboradores_convenia.motivo = 'FALTA INJUSTIFICADA';
  END IF;

  RETURN NEW;
END;
$$;

-- 3) Função de sincronização (UPDATE em diária): atualizar falta já vinculada, sem criar duplicada
CREATE OR REPLACE FUNCTION public.sync_falta_colaborador_convenia()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF current_setting('app.rpc_call', true) = 'justificar_falta' THEN
    RETURN NEW;
  END IF;

  IF NEW.motivo_vago = 'DIÁRIA - FALTA'
     AND NEW.colaborador_ausente_convenia IS NOT NULL THEN

    UPDATE public.faltas_colaboradores_convenia
    SET
      colaborador_convenia_id = NEW.colaborador_ausente_convenia,
      data_falta = NEW.data_diaria,
      updated_at = now()
    WHERE diaria_temporaria_id = NEW.id;

    IF NOT FOUND THEN
      INSERT INTO public.faltas_colaboradores_convenia (
        colaborador_convenia_id,
        diaria_temporaria_id,
        data_falta,
        motivo
      ) VALUES (
        NEW.colaborador_ausente_convenia,
        NEW.id,
        NEW.data_diaria,
        'FALTA INJUSTIFICADA'
      )
      ON CONFLICT (diaria_temporaria_id)
      WHERE diaria_temporaria_id IS NOT NULL
      DO UPDATE SET
        colaborador_convenia_id = EXCLUDED.colaborador_convenia_id,
        data_falta = EXCLUDED.data_falta,
        updated_at = now();
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- 4) Garantir disparo da sincronização também quando data_diaria for alterada
DROP TRIGGER IF EXISTS trg_sync_falta_convenia ON public.diarias_temporarias;

CREATE TRIGGER trg_sync_falta_convenia
AFTER UPDATE OF motivo_vago, colaborador_ausente_convenia, data_diaria
ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.sync_falta_colaborador_convenia();

-- 5) Reconciliar registros já vinculados para manter consistência atual
UPDATE public.faltas_colaboradores_convenia f
SET
  colaborador_convenia_id = d.colaborador_ausente_convenia,
  data_falta = d.data_diaria,
  updated_at = now()
FROM public.diarias_temporarias d
WHERE f.diaria_temporaria_id = d.id
  AND d.motivo_vago = 'DIÁRIA - FALTA'
  AND d.colaborador_ausente_convenia IS NOT NULL
  AND (
    f.colaborador_convenia_id IS DISTINCT FROM d.colaborador_ausente_convenia
    OR f.data_falta IS DISTINCT FROM d.data_diaria
  );