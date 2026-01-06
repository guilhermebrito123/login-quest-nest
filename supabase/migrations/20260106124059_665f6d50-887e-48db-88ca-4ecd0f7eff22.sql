-- Criar tabela de logs completos
CREATE TABLE public.diarias_temporarias_logs_completos (
    id BIGSERIAL PRIMARY KEY,
    diaria_id BIGINT NOT NULL,
    operacao TEXT NOT NULL CHECK (
        operacao IN ('INSERT', 'UPDATE', 'DELETE')
    ),
    usuario TEXT,
    data_operacao TIMESTAMPTZ NOT NULL DEFAULT now(),
    alteracoes JSONB,
    registro_completo JSONB
);

-- Habilitar RLS
ALTER TABLE public.diarias_temporarias_logs_completos ENABLE ROW LEVEL SECURITY;

-- Política para leitura (perfis internos podem ver)
CREATE POLICY "Perfis internos podem ver logs completos"
ON public.diarias_temporarias_logs_completos
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.usuarios u
        WHERE u.id = auth.uid()
        AND u.role = 'perfil_interno'
    )
);

-- Criar função de diff JSONB
CREATE OR REPLACE FUNCTION public.fn_diff_jsonb(
    old_row JSONB,
    new_row JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    result JSONB := '{}'::jsonb;
    key TEXT;
BEGIN
    FOR key IN
        SELECT jsonb_object_keys(new_row)
    LOOP
        IF old_row -> key IS DISTINCT FROM new_row -> key THEN
            result := result || jsonb_build_object(
                key,
                jsonb_build_object(
                    'old', old_row -> key,
                    'new', new_row -> key
                )
            );
        END IF;
    END LOOP;

    RETURN result;
END;
$$;

-- Criar função do trigger
CREATE OR REPLACE FUNCTION public.trg_diarias_temporarias_logs()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    old_json JSONB;
    new_json JSONB;
    diff JSONB;
BEGIN
    IF TG_OP = 'INSERT' THEN
        new_json := to_jsonb(NEW);

        INSERT INTO public.diarias_temporarias_logs_completos (
            diaria_id,
            operacao,
            usuario,
            registro_completo
        )
        VALUES (
            NEW.id,
            'INSERT',
            COALESCE(auth.uid()::text, current_user),
            new_json
        );

        RETURN NEW;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        old_json := to_jsonb(OLD);
        new_json := to_jsonb(NEW);

        diff := public.fn_diff_jsonb(old_json, new_json);

        IF diff <> '{}'::jsonb THEN
            INSERT INTO public.diarias_temporarias_logs_completos (
                diaria_id,
                operacao,
                usuario,
                alteracoes
            )
            VALUES (
                NEW.id,
                'UPDATE',
                COALESCE(auth.uid()::text, current_user),
                diff
            );
        END IF;

        RETURN NEW;
    END IF;

    IF TG_OP = 'DELETE' THEN
        old_json := to_jsonb(OLD);

        INSERT INTO public.diarias_temporarias_logs_completos (
            diaria_id,
            operacao,
            usuario,
            registro_completo
        )
        VALUES (
            OLD.id,
            'DELETE',
            COALESCE(auth.uid()::text, current_user),
            old_json
        );

        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;

-- Criar trigger
CREATE TRIGGER trg_diarias_temporarias_audit
AFTER INSERT OR UPDATE OR DELETE
ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.trg_diarias_temporarias_logs();

-- Criar índice para consultas por diaria_id
CREATE INDEX idx_diarias_temporarias_logs_completos_diaria_id 
ON public.diarias_temporarias_logs_completos(diaria_id);

-- Criar índice para consultas por data
CREATE INDEX idx_diarias_temporarias_logs_completos_data 
ON public.diarias_temporarias_logs_completos(data_operacao);