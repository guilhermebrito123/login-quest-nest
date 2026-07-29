-- 1) Colunas de autoria
ALTER TABLE public.faltas_colaboradores_convenia
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES public.usuarios(id),
  ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES public.usuarios(id);

CREATE OR REPLACE FUNCTION public.fn_stamp_faltas_convenia_autoria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid;
BEGIN
  BEGIN
    v_uid := auth.uid();
    IF v_uid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.usuarios WHERE id = v_uid) THEN
      v_uid := NULL;
    END IF;

    IF TG_OP = 'INSERT' THEN
      NEW.created_by := COALESCE(NEW.created_by, v_uid);
      NEW.updated_by := v_uid;
    ELSIF TG_OP = 'UPDATE' THEN
      NEW.updated_by := v_uid;
      NEW.created_by := OLD.created_by;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'fn_stamp_faltas_convenia_autoria: %', SQLERRM;
  END;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_faltas_convenia_autoria ON public.faltas_colaboradores_convenia;
CREATE TRIGGER trg_faltas_convenia_autoria
BEFORE INSERT OR UPDATE ON public.faltas_colaboradores_convenia
FOR EACH ROW EXECUTE FUNCTION public.fn_stamp_faltas_convenia_autoria();

-- 2) Tabela de auditoria
CREATE TABLE IF NOT EXISTS public.faltas_colaboradores_convenia_auditoria (
  id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  falta_id           bigint NOT NULL,
  operacao           text   NOT NULL CHECK (operacao IN ('INSERT','UPDATE','DELETE')),
  evento             text   NOT NULL,
  alterado_em        timestamptz NOT NULL DEFAULT now(),
  alterado_por       uuid,
  alterado_por_nome  text,
  alterado_por_email text,
  dados_antigos      jsonb,
  dados_novos        jsonb,
  campos_alterados   jsonb,
  ip_origem          text,
  user_agent         text
);

CREATE INDEX IF NOT EXISTS idx_faltas_convenia_auditoria_falta_id     ON public.faltas_colaboradores_convenia_auditoria (falta_id);
CREATE INDEX IF NOT EXISTS idx_faltas_convenia_auditoria_alterado_em  ON public.faltas_colaboradores_convenia_auditoria (alterado_em DESC);
CREATE INDEX IF NOT EXISTS idx_faltas_convenia_auditoria_alterado_por ON public.faltas_colaboradores_convenia_auditoria (alterado_por);
CREATE INDEX IF NOT EXISTS idx_faltas_convenia_auditoria_evento       ON public.faltas_colaboradores_convenia_auditoria (evento);

GRANT SELECT ON public.faltas_colaboradores_convenia_auditoria TO authenticated;
GRANT ALL ON public.faltas_colaboradores_convenia_auditoria TO service_role;

ALTER TABLE public.faltas_colaboradores_convenia_auditoria ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Auditores podem visualizar auditoria de faltas" ON public.faltas_colaboradores_convenia_auditoria;
CREATE POLICY "Auditores podem visualizar auditoria de faltas"
ON public.faltas_colaboradores_convenia_auditoria
FOR SELECT
TO authenticated
USING (
  has_role(auth.uid(), 'admin'::internal_access_level)
  OR has_role(auth.uid(), 'gestor_operacoes'::internal_access_level)
  OR has_role(auth.uid(), 'supervisor'::internal_access_level)
);

-- 3) Trigger de auditoria
CREATE OR REPLACE FUNCTION public.fn_auditar_faltas_colaboradores_convenia()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_evento      text;
  v_old_json    jsonb;
  v_new_json    jsonb;
  v_diff        jsonb;
  v_nome        text;
  v_email       text;
  v_headers     jsonb;
  v_ip          text;
  v_user_agent  text;
BEGIN
  BEGIN
    v_old_json := CASE WHEN TG_OP IN ('UPDATE','DELETE') THEN to_jsonb(OLD) ELSE NULL END;
    v_new_json := CASE WHEN TG_OP IN ('UPDATE','INSERT') THEN to_jsonb(NEW) ELSE NULL END;

    IF TG_OP = 'INSERT' THEN
      v_evento := 'CRIACAO';
      SELECT jsonb_agg(jsonb_build_object('campo', n.key, 'valor_antigo', NULL, 'valor_novo', n.value))
        INTO v_diff FROM jsonb_each(v_new_json) n;
    ELSIF TG_OP = 'DELETE' THEN
      v_evento := 'EXCLUSAO';
      SELECT jsonb_agg(jsonb_build_object('campo', o.key, 'valor_antigo', o.value, 'valor_novo', NULL))
        INTO v_diff FROM jsonb_each(v_old_json) o;
    ELSE
      IF OLD.justificada_por IS NULL AND NEW.justificada_por IS NOT NULL THEN
        v_evento := 'JUSTIFICATIVA_REGISTRADA';
      ELSIF OLD.justificada_por IS NOT NULL AND NEW.justificada_por IS NULL THEN
        v_evento := 'JUSTIFICATIVA_REVERTIDA';
      ELSIF OLD.justificada_por IS DISTINCT FROM NEW.justificada_por THEN
        v_evento := 'JUSTIFICATIVA_ALTERADA';
      ELSE
        v_evento := 'ATUALIZACAO';
      END IF;

      SELECT jsonb_agg(jsonb_build_object('campo', o.key, 'valor_antigo', o.value, 'valor_novo', n.value))
        INTO v_diff
        FROM jsonb_each(v_old_json) o
        JOIN jsonb_each(v_new_json) n ON n.key = o.key
        WHERE o.value IS DISTINCT FROM n.value;
    END IF;

    BEGIN
      SELECT full_name, email INTO v_nome, v_email FROM public.usuarios WHERE id = auth.uid();
    EXCEPTION WHEN OTHERS THEN
      v_nome := NULL; v_email := NULL;
    END;

    BEGIN
      v_headers := current_setting('request.headers', true)::jsonb;
      v_ip := COALESCE(v_headers->>'x-forwarded-for', v_headers->>'cf-connecting-ip');
      v_user_agent := v_headers->>'user-agent';
    EXCEPTION WHEN OTHERS THEN
      v_ip := NULL; v_user_agent := NULL;
    END;

    INSERT INTO public.faltas_colaboradores_convenia_auditoria (
      falta_id, operacao, evento, alterado_por, alterado_por_nome, alterado_por_email,
      dados_antigos, dados_novos, campos_alterados, ip_origem, user_agent
    ) VALUES (
      COALESCE(NEW.id, OLD.id), TG_OP, v_evento, auth.uid(), v_nome, v_email,
      v_old_json, v_new_json, v_diff, v_ip, v_user_agent
    );
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'fn_auditar_faltas_colaboradores_convenia: %', SQLERRM;
  END;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_faltas_convenia_auditoria ON public.faltas_colaboradores_convenia;
CREATE TRIGGER trg_faltas_convenia_auditoria
AFTER INSERT OR UPDATE OR DELETE ON public.faltas_colaboradores_convenia
FOR EACH ROW EXECUTE FUNCTION public.fn_auditar_faltas_colaboradores_convenia();

-- 4) View de leitura
DROP VIEW IF EXISTS public.vw_faltas_colaboradores_convenia_auditoria;
CREATE VIEW public.vw_faltas_colaboradores_convenia_auditoria
WITH (security_invoker = on) AS
SELECT
  a.id,
  a.falta_id,
  a.operacao,
  a.evento,
  a.alterado_em,
  a.alterado_por,
  COALESCE(a.alterado_por_nome, u.full_name) AS alterado_por_nome,
  COALESCE(a.alterado_por_email, u.email)    AS alterado_por_email,
  a.campos_alterados,
  a.dados_antigos,
  a.dados_novos,
  a.ip_origem,
  a.user_agent
FROM public.faltas_colaboradores_convenia_auditoria a
LEFT JOIN public.usuarios u ON u.id = a.alterado_por;

GRANT SELECT ON public.vw_faltas_colaboradores_convenia_auditoria TO authenticated;