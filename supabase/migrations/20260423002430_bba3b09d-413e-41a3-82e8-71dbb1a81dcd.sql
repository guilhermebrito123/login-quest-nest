CREATE OR REPLACE FUNCTION public.generate_due_checklist_instances()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  tpl RECORD;
  new_instance_id uuid;
  total integer := 0;
BEGIN
  FOR tpl IN
    SELECT *
    FROM public.checklist_templates
    WHERE status = 'published'
      AND ativo = true
      AND recorrencia <> 'one_time'
      AND proxima_geracao_em IS NOT NULL
      AND proxima_geracao_em <= now()
      AND (encerra_em IS NULL OR encerra_em > now())
  LOOP
    INSERT INTO public.checklist_instancias (
      checklist_template_id, template_versao,
      titulo_snapshot, descricao_snapshot, observacao_snapshot,
      criado_por_user_id, cost_center_id, local_id,
      agendado_para, prazo_em, status, exige_plano_acao
    ) VALUES (
      tpl.id, tpl.versao,
      tpl.titulo, tpl.descricao, tpl.observacao,
      tpl.criado_por_user_id, tpl.cost_center_id, tpl.local_id,
      tpl.proxima_geracao_em,
      CASE WHEN tpl.prazo_padrao_horas IS NOT NULL
           THEN tpl.proxima_geracao_em + (tpl.prazo_padrao_horas || ' hours')::interval
           ELSE NULL END,
      'open', tpl.exige_plano_acao
    ) RETURNING id INTO new_instance_id;

    UPDATE public.checklist_templates
    SET proxima_geracao_em = public.calc_next_recurrence(
      tpl.recorrencia, tpl.recorrencia_intervalo, tpl.proxima_geracao_em
    )
    WHERE id = tpl.id;

    total := total + 1;
  END LOOP;
  RETURN total;
END;
$function$;