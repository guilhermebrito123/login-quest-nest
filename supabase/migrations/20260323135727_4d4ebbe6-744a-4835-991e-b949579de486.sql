CREATE OR REPLACE FUNCTION public.notificar_alteracoes_diaria()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
  v_user_id uuid;
  v_titulo text;
  v_mensagem text;
BEGIN
  IF tg_op <> 'UPDATE' THEN
    RETURN new;
  END IF;

  -- motivo_cancelamento
  IF old.motivo_cancelamento IS DISTINCT FROM new.motivo_cancelamento THEN
    FOR v_user_id IN
      SELECT user_id FROM public.obter_usuarios_envolvidos_diaria(old, new)
    LOOP
      v_titulo := 'Motivo de cancelamento atualizado';
      IF new.motivo_cancelamento IS NULL THEN
        v_mensagem := 'A diária #' || new.id || ' teve o motivo de cancelamento excluído.';
      ELSE
        v_mensagem := 'A diária #' || new.id || ' teve o motivo de cancelamento alterado para: ' || new.motivo_cancelamento;
      END IF;

      PERFORM public.criar_notificacao_diaria(
        new.id, v_user_id, 'motivo_cancelamento', 'campo_alterado',
        old.motivo_cancelamento, new.motivo_cancelamento, v_titulo, v_mensagem
      );
    END LOOP;
  END IF;

  -- motivo_reprovacao
  IF old.motivo_reprovacao IS DISTINCT FROM new.motivo_reprovacao THEN
    FOR v_user_id IN
      SELECT user_id FROM public.obter_usuarios_envolvidos_diaria(old, new)
    LOOP
      v_titulo := 'Motivo de reprovação atualizado';
      IF new.motivo_reprovacao IS NULL THEN
        v_mensagem := 'A diária #' || new.id || ' teve o motivo de reprovação excluído.';
      ELSE
        v_mensagem := 'A diária #' || new.id || ' teve o motivo de reprovação alterado para: ' || new.motivo_reprovacao::text;
      END IF;

      PERFORM public.criar_notificacao_diaria(
        new.id, v_user_id, 'motivo_reprovacao', 'campo_alterado',
        old.motivo_reprovacao::text, new.motivo_reprovacao::text, v_titulo, v_mensagem
      );
    END LOOP;
  END IF;

  -- motivo_reprovacao_observacao
  IF old.motivo_reprovacao_observacao IS DISTINCT FROM new.motivo_reprovacao_observacao THEN
    FOR v_user_id IN
      SELECT user_id FROM public.obter_usuarios_envolvidos_diaria(old, new)
    LOOP
      v_titulo := 'Observação de reprovação atualizada';
      IF new.motivo_reprovacao_observacao IS NULL THEN
        v_mensagem := 'A diária #' || new.id || ' teve a observação de reprovação excluída.';
      ELSE
        v_mensagem := 'A diária #' || new.id || ' teve a observação de reprovação alterada para: ' || new.motivo_reprovacao_observacao;
      END IF;

      PERFORM public.criar_notificacao_diaria(
        new.id, v_user_id, 'motivo_reprovacao_observacao', 'campo_alterado',
        old.motivo_reprovacao_observacao, new.motivo_reprovacao_observacao, v_titulo, v_mensagem
      );
    END LOOP;
  END IF;

  -- observacao_lancamento
  IF old.observacao_lancamento IS DISTINCT FROM new.observacao_lancamento THEN
    FOR v_user_id IN
      SELECT user_id FROM public.obter_usuarios_envolvidos_diaria(old, new)
    LOOP
      v_titulo := 'Observação de lançamento atualizada';
      IF new.observacao_lancamento IS NULL THEN
        v_mensagem := 'A diária #' || new.id || ' teve a observação de lançamento excluída.';
      ELSE
        v_mensagem := 'A diária #' || new.id || ' teve a observação de lançamento alterada para: ' || new.observacao_lancamento;
      END IF;

      PERFORM public.criar_notificacao_diaria(
        new.id, v_user_id, 'observacao_lancamento', 'campo_alterado',
        old.observacao_lancamento, new.observacao_lancamento, v_titulo, v_mensagem
      );
    END LOOP;
  END IF;

  -- observacao_pagamento
  IF old.observacao_pagamento IS DISTINCT FROM new.observacao_pagamento THEN
    FOR v_user_id IN
      SELECT user_id FROM public.obter_usuarios_envolvidos_diaria(old, new)
    LOOP
      v_titulo := 'Observação de pagamento atualizada';
      IF new.observacao_pagamento IS NULL THEN
        v_mensagem := 'A diária #' || new.id || ' teve a observação de pagamento excluída.';
      ELSE
        v_mensagem := 'A diária #' || new.id || ' teve a observação de pagamento alterada para: ' || array_to_string(new.observacao_pagamento, ', ');
      END IF;

      PERFORM public.criar_notificacao_diaria(
        new.id, v_user_id, 'observacao_pagamento', 'campo_alterado',
        CASE WHEN old.observacao_pagamento IS NOT NULL THEN array_to_string(old.observacao_pagamento, ', ') ELSE NULL END,
        CASE WHEN new.observacao_pagamento IS NOT NULL THEN array_to_string(new.observacao_pagamento, ', ') ELSE NULL END,
        v_titulo, v_mensagem
      );
    END LOOP;
  END IF;

  -- outros_motivos_reprovacao_pagamento
  IF old.outros_motivos_reprovacao_pagamento IS DISTINCT FROM new.outros_motivos_reprovacao_pagamento THEN
    FOR v_user_id IN
      SELECT user_id FROM public.obter_usuarios_envolvidos_diaria(old, new)
    LOOP
      v_titulo := 'Motivos adicionais de reprovação de pagamento atualizados';
      IF new.outros_motivos_reprovacao_pagamento IS NULL THEN
        v_mensagem := 'A diária #' || new.id || ' teve os motivos adicionais de reprovação de pagamento excluídos.';
      ELSE
        v_mensagem := 'A diária #' || new.id || ' teve os motivos adicionais de reprovação de pagamento alterados para: ' || new.outros_motivos_reprovacao_pagamento;
      END IF;

      PERFORM public.criar_notificacao_diaria(
        new.id, v_user_id, 'outros_motivos_reprovacao_pagamento', 'campo_alterado',
        old.outros_motivos_reprovacao_pagamento, new.outros_motivos_reprovacao_pagamento, v_titulo, v_mensagem
      );
    END LOOP;
  END IF;

  -- status -> Cancelada
  IF old.status IS DISTINCT FROM new.status AND new.status = 'Cancelada' THEN
    FOR v_user_id IN
      SELECT user_id FROM public.obter_usuarios_envolvidos_diaria(old, new)
    LOOP
      v_titulo := 'Diária cancelada';
      v_mensagem := 'A diária #' || new.id || ' teve o status alterado para Cancelada.';

      PERFORM public.criar_notificacao_diaria(
        new.id, v_user_id, 'status', 'status_cancelada',
        old.status::text, new.status::text, v_titulo, v_mensagem
      );
    END LOOP;
  END IF;

  -- status -> Reprovada
  IF old.status IS DISTINCT FROM new.status AND new.status = 'Reprovada' THEN
    FOR v_user_id IN
      SELECT user_id FROM public.obter_usuarios_envolvidos_diaria(old, new)
    LOOP
      v_titulo := 'Diária reprovada';
      v_mensagem := 'A diária #' || new.id || ' teve o status alterado para Reprovada.';

      PERFORM public.criar_notificacao_diaria(
        new.id, v_user_id, 'status', 'status_reprovada',
        old.status::text, new.status::text, v_titulo, v_mensagem
      );
    END LOOP;
  END IF;

  -- ok_pagamento -> false
  IF old.ok_pagamento IS DISTINCT FROM new.ok_pagamento AND new.ok_pagamento = false THEN
    FOR v_user_id IN
      SELECT user_id FROM public.obter_usuarios_envolvidos_diaria(old, new)
    LOOP
      v_titulo := 'Pagamento da diária marcado como não OK';
      v_mensagem := 'A diária #' || new.id || ' teve a validação de pagamento alterada para false.';

      PERFORM public.criar_notificacao_diaria(
        new.id, v_user_id, 'ok_pagamento', 'pagamento_nao_ok',
        coalesce(old.ok_pagamento::text, 'null'),
        coalesce(new.ok_pagamento::text, 'null'),
        v_titulo, v_mensagem
      );
    END LOOP;
  END IF;

  RETURN new;
END;
$function$;