CREATE OR REPLACE FUNCTION public.trg_chamados_auditoria()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_old jsonb;
  v_new jsonb;
  v_key text;
  v_usuario_id uuid;
  v_timestamp timestamptz;
BEGIN
  v_timestamp := now() AT TIME ZONE 'America/Sao_Paulo';
  -- Usuário autenticado que está realizando a operação
  v_usuario_id := auth.uid();

  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.chamado_historico (
      chamado_id, usuario_id, operacao, alteracoes, registro_completo, created_at
    ) VALUES (
      NEW.id,
      COALESCE(v_usuario_id, NEW.solicitante_id),
      'insert',
      NULL,
      to_jsonb(NEW),
      v_timestamp
    );
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    v_old := to_jsonb(OLD);
    v_new := to_jsonb(NEW);

    FOR v_key IN
      SELECT key FROM jsonb_object_keys(v_new) AS key
    LOOP
      IF (v_old ->> v_key) IS DISTINCT FROM (v_new ->> v_key) THEN
        INSERT INTO public.chamado_historico (
          chamado_id, usuario_id, operacao, campo_alterado,
          valor_anterior, valor_novo, registro_completo, created_at
        ) VALUES (
          NEW.id,
          v_usuario_id,
          'update',
          v_key,
          v_old ->> v_key,
          v_new ->> v_key,
          v_new,
          v_timestamp
        );
      END IF;
    END LOOP;
    RETURN NEW;
  END IF;

  IF TG_OP = 'DELETE' THEN
    INSERT INTO public.chamado_historico (
      chamado_id, usuario_id, operacao, alteracoes, registro_completo, created_at
    ) VALUES (
      OLD.id,
      v_usuario_id,
      'delete',
      NULL,
      to_jsonb(OLD),
      v_timestamp
    );
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$function$;