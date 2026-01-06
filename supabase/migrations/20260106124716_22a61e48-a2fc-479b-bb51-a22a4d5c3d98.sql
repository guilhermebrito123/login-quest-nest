-- Corrigir função fn_diff_jsonb com search_path
CREATE OR REPLACE FUNCTION public.fn_diff_jsonb(
    old_row JSONB,
    new_row JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
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