CREATE OR REPLACE FUNCTION public.trg_diaristas_cpf_guard()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = public
AS $function$
DECLARE
  v_new_cpf_norm text;
  v_old_cpf_norm text;
  v_conflito_id text;
BEGIN
  v_new_cpf_norm := public.normalizar_cpf(new.cpf);

  IF v_new_cpf_norm IS NULL OR v_new_cpf_norm = '' THEN
    RAISE EXCEPTION 'Campo CPF é obrigatório';
  END IF;

  IF length(v_new_cpf_norm) <> 11 THEN
    RAISE EXCEPTION 'CPF inválido. Informe 11 dígitos.';
  END IF;

  IF tg_op = 'UPDATE' THEN
    v_old_cpf_norm := public.normalizar_cpf(old.cpf);
    IF v_new_cpf_norm = v_old_cpf_norm THEN
      RETURN new;
    END IF;
  END IF;

  SELECT d.id::text
    INTO v_conflito_id
  FROM public.diaristas d
  WHERE public.normalizar_cpf(d.cpf) = v_new_cpf_norm
    AND d.id::text <> new.id::text
  LIMIT 1;

  IF v_conflito_id IS NOT NULL THEN
    RAISE EXCEPTION 'Já existe um diarista cadastrado com este CPF.';
  END IF;

  RETURN new;
END;
$function$;