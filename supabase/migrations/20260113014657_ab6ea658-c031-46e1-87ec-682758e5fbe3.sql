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
BEGIN
  -- Verifica se o status está sendo alterado para 'restrito'
  status_mudando_para_restrito := (
    OLD.status IS DISTINCT FROM NEW.status 
    AND NEW.status = 'restrito'
  );

  -- 🔴 BLOQUEIA UPDATE SEM MOTIVO (exceto quando status muda para 'restrito')
  IF NOT status_mudando_para_restrito THEN
    IF NEW.motivo_alteracao IS NULL
       OR btrim(NEW.motivo_alteracao) = '' THEN
      RAISE EXCEPTION
        'Atualização bloqueada: informe o motivo da alteração.';
    END IF;
  END IF;

  -- Usa o motivo_alteracao se fornecido, ou usa mensagem padrão para restrição
  IF status_mudando_para_restrito AND (NEW.motivo_alteracao IS NULL OR btrim(NEW.motivo_alteracao) = '') THEN
    motivo := 'Status alterado para restrito';
  ELSE
    motivo := NEW.motivo_alteracao;
  END IF;

  -- percorre todos os campos
  FOR k IN
    SELECT jsonb_object_keys(new_json)
  LOOP
    -- ignora o próprio campo de motivo
    IF k = 'motivo_alteracao' THEN
      CONTINUE;
    END IF;

    IF (old_json -> k) IS DISTINCT FROM (new_json -> k) THEN
      INSERT INTO public.diaristas_historico (
        diarista_id,
        campo_alterado,
        valor_anterior,
        valor_novo,
        motivo
      )
      VALUES (
        OLD.id,
        k,
        old_json ->> k,
        new_json ->> k,
        motivo
      );
    END IF;
  END LOOP;

  -- limpa o motivo após registrar
  NEW.motivo_alteracao := NULL;

  RETURN NEW;
END;
$function$;