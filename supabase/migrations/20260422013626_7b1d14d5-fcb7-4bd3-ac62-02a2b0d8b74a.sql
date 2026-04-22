
-- HELPER: bloqueia delete de template se houver instâncias
CREATE OR REPLACE FUNCTION public.template_has_instancias(_template_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM public.checklist_instancias WHERE checklist_template_id = _template_id)
$$;

-- HELPER unificado: admin OU supervisor do CC
CREATE OR REPLACE FUNCTION public.can_manage_checklist_cc(_user_id uuid, _cost_center_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT public.module_is_admin(_user_id)
      OR public.module_supervisor_has_cost_center(_user_id, _cost_center_id)
$$;

-- HELPER: pode gerenciar equipe (admin OU supervisor de TODOS os CCs vinculados)
CREATE OR REPLACE FUNCTION public.can_manage_equipe(_user_id uuid, _equipe_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT public.module_is_admin(_user_id)
      OR (
        EXISTS (SELECT 1 FROM public.module_equipe_cost_centers ecc WHERE ecc.equipe_id = _equipe_id)
        AND NOT EXISTS (
          SELECT 1 FROM public.module_equipe_cost_centers ecc
          WHERE ecc.equipe_id = _equipe_id
            AND NOT public.module_supervisor_has_cost_center(_user_id, ecc.cost_center_id)
        )
      )
$$;

-- =========== CHECKLIST_TEMPLATES ===========
DROP POLICY IF EXISTS tpl_update ON public.checklist_templates;
CREATE POLICY tpl_update ON public.checklist_templates FOR UPDATE
USING (public.can_manage_checklist_cc(auth.uid(), cost_center_id))
WITH CHECK (public.can_manage_checklist_cc(auth.uid(), cost_center_id));

DROP POLICY IF EXISTS tpl_delete ON public.checklist_templates;
CREATE POLICY tpl_delete ON public.checklist_templates FOR DELETE
USING (
  public.can_manage_checklist_cc(auth.uid(), cost_center_id)
  AND NOT public.template_has_instancias(id)
);

-- =========== CHECKLIST_TEMPLATE_TAREFAS ===========
DROP POLICY IF EXISTS tpl_tarefas_update ON public.checklist_template_tarefas;
CREATE POLICY tpl_tarefas_update ON public.checklist_template_tarefas FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM public.checklist_templates t
  WHERE t.id = checklist_template_tarefas.checklist_template_id
    AND public.can_manage_checklist_cc(auth.uid(), t.cost_center_id)
))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.checklist_templates t
  WHERE t.id = checklist_template_tarefas.checklist_template_id
    AND public.can_manage_checklist_cc(auth.uid(), t.cost_center_id)
));

DROP POLICY IF EXISTS tpl_tarefas_delete ON public.checklist_template_tarefas;
CREATE POLICY tpl_tarefas_delete ON public.checklist_template_tarefas FOR DELETE
USING (EXISTS (
  SELECT 1 FROM public.checklist_templates t
  WHERE t.id = checklist_template_tarefas.checklist_template_id
    AND public.can_manage_checklist_cc(auth.uid(), t.cost_center_id)
));

-- =========== CHECKLIST_INSTANCIAS ===========
DROP POLICY IF EXISTS inst_update ON public.checklist_instancias;
CREATE POLICY inst_update ON public.checklist_instancias FOR UPDATE
USING (public.can_manage_checklist_cc(auth.uid(), cost_center_id))
WITH CHECK (public.can_manage_checklist_cc(auth.uid(), cost_center_id));

DROP POLICY IF EXISTS inst_delete ON public.checklist_instancias;
CREATE POLICY inst_delete ON public.checklist_instancias FOR DELETE
USING (public.can_manage_checklist_cc(auth.uid(), cost_center_id));

-- =========== CHECKLIST_INSTANCIA_TAREFAS ===========
DROP POLICY IF EXISTS inst_tarefas_update ON public.checklist_instancia_tarefas;
CREATE POLICY inst_tarefas_update ON public.checklist_instancia_tarefas FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM public.checklist_instancias i
  WHERE i.id = checklist_instancia_tarefas.checklist_instancia_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.checklist_instancias i
  WHERE i.id = checklist_instancia_tarefas.checklist_instancia_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
));

DROP POLICY IF EXISTS inst_tarefas_delete ON public.checklist_instancia_tarefas;
CREATE POLICY inst_tarefas_delete ON public.checklist_instancia_tarefas FOR DELETE
USING (EXISTS (
  SELECT 1 FROM public.checklist_instancias i
  WHERE i.id = checklist_instancia_tarefas.checklist_instancia_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
));

-- =========== CHECKLIST_TAREFA_RESPONSAVEIS ===========
DROP POLICY IF EXISTS responsaveis_update ON public.checklist_tarefa_responsaveis;
DROP POLICY IF EXISTS responsaveis_update_kanban ON public.checklist_tarefa_responsaveis;
DROP POLICY IF EXISTS responsaveis_delete ON public.checklist_tarefa_responsaveis;

CREATE POLICY responsaveis_update ON public.checklist_tarefa_responsaveis FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.checklist_instancia_tarefas it
    JOIN public.checklist_instancias i ON i.id = it.checklist_instancia_id
    WHERE it.id = checklist_tarefa_responsaveis.checklist_instancia_tarefa_id
      AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
  )
  OR (assigned_user_id = auth.uid() AND pode_alterar_status = true)
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.checklist_instancia_tarefas it
    JOIN public.checklist_instancias i ON i.id = it.checklist_instancia_id
    WHERE it.id = checklist_tarefa_responsaveis.checklist_instancia_tarefa_id
      AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
  )
  OR (assigned_user_id = auth.uid() AND pode_alterar_status = true)
);

CREATE POLICY responsaveis_delete ON public.checklist_tarefa_responsaveis FOR DELETE
USING (EXISTS (
  SELECT 1 FROM public.checklist_instancia_tarefas it
  JOIN public.checklist_instancias i ON i.id = it.checklist_instancia_id
  WHERE it.id = checklist_tarefa_responsaveis.checklist_instancia_tarefa_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
));

-- =========== CHECKLIST_TAREFA_RESPOSTAS (supervisor NÃO pode) ===========
DROP POLICY IF EXISTS respostas_update ON public.checklist_tarefa_respostas;
CREATE POLICY respostas_update ON public.checklist_tarefa_respostas FOR UPDATE
USING (respondido_por_user_id = auth.uid() OR public.module_is_admin(auth.uid()))
WITH CHECK (respondido_por_user_id = auth.uid() OR public.module_is_admin(auth.uid()));

DROP POLICY IF EXISTS respostas_delete ON public.checklist_tarefa_respostas;
CREATE POLICY respostas_delete ON public.checklist_tarefa_respostas FOR DELETE
USING (respondido_por_user_id = auth.uid() OR public.module_is_admin(auth.uid()));

-- =========== CHECKLIST_TAREFA_STATUS_HISTORICO ===========
DROP POLICY IF EXISTS status_historico_update ON public.checklist_tarefa_status_historico;
CREATE POLICY status_historico_update ON public.checklist_tarefa_status_historico FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM public.checklist_instancia_tarefas it
  JOIN public.checklist_instancias i ON i.id = it.checklist_instancia_id
  WHERE it.id = checklist_tarefa_status_historico.checklist_instancia_tarefa_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.checklist_instancia_tarefas it
  JOIN public.checklist_instancias i ON i.id = it.checklist_instancia_id
  WHERE it.id = checklist_tarefa_status_historico.checklist_instancia_tarefa_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
));

DROP POLICY IF EXISTS status_historico_delete ON public.checklist_tarefa_status_historico;
CREATE POLICY status_historico_delete ON public.checklist_tarefa_status_historico FOR DELETE
USING (EXISTS (
  SELECT 1 FROM public.checklist_instancia_tarefas it
  JOIN public.checklist_instancias i ON i.id = it.checklist_instancia_id
  WHERE it.id = checklist_tarefa_status_historico.checklist_instancia_tarefa_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
));

-- =========== CHECKLIST_AVALIACOES ===========
DROP POLICY IF EXISTS aval_update ON public.checklist_avaliacoes;
CREATE POLICY aval_update ON public.checklist_avaliacoes FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM public.checklist_instancias i
  WHERE i.id = checklist_avaliacoes.checklist_instancia_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.checklist_instancias i
  WHERE i.id = checklist_avaliacoes.checklist_instancia_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
));

DROP POLICY IF EXISTS aval_delete ON public.checklist_avaliacoes;
CREATE POLICY aval_delete ON public.checklist_avaliacoes FOR DELETE
USING (EXISTS (
  SELECT 1 FROM public.checklist_instancias i
  WHERE i.id = checklist_avaliacoes.checklist_instancia_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
));

-- =========== CHECKLIST_AVALIACAO_ITENS ===========
DROP POLICY IF EXISTS aval_itens_update ON public.checklist_avaliacao_itens;
CREATE POLICY aval_itens_update ON public.checklist_avaliacao_itens FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM public.checklist_avaliacoes a
  JOIN public.checklist_instancias i ON i.id = a.checklist_instancia_id
  WHERE a.id = checklist_avaliacao_itens.checklist_avaliacao_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.checklist_avaliacoes a
  JOIN public.checklist_instancias i ON i.id = a.checklist_instancia_id
  WHERE a.id = checklist_avaliacao_itens.checklist_avaliacao_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
));

DROP POLICY IF EXISTS aval_itens_delete ON public.checklist_avaliacao_itens;
CREATE POLICY aval_itens_delete ON public.checklist_avaliacao_itens FOR DELETE
USING (EXISTS (
  SELECT 1 FROM public.checklist_avaliacoes a
  JOIN public.checklist_instancias i ON i.id = a.checklist_instancia_id
  WHERE a.id = checklist_avaliacao_itens.checklist_avaliacao_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
));

-- =========== CHECKLIST_FEEDBACKS ===========
DROP POLICY IF EXISTS feedback_update_admin ON public.checklist_feedbacks;
CREATE POLICY feedback_update_admin ON public.checklist_feedbacks FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM public.checklist_instancia_tarefas it
  JOIN public.checklist_instancias i ON i.id = it.checklist_instancia_id
  WHERE it.id = checklist_feedbacks.checklist_instancia_tarefa_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.checklist_instancia_tarefas it
  JOIN public.checklist_instancias i ON i.id = it.checklist_instancia_id
  WHERE it.id = checklist_feedbacks.checklist_instancia_tarefa_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
));

DROP POLICY IF EXISTS feedback_delete ON public.checklist_feedbacks;
CREATE POLICY feedback_delete ON public.checklist_feedbacks FOR DELETE
USING (EXISTS (
  SELECT 1 FROM public.checklist_instancia_tarefas it
  JOIN public.checklist_instancias i ON i.id = it.checklist_instancia_id
  WHERE it.id = checklist_feedbacks.checklist_instancia_tarefa_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
));

-- =========== MODULE_EQUIPES ===========
DROP POLICY IF EXISTS equipes_update ON public.module_equipes;
CREATE POLICY equipes_update ON public.module_equipes FOR UPDATE
USING (public.can_manage_equipe(auth.uid(), id))
WITH CHECK (public.can_manage_equipe(auth.uid(), id));

DROP POLICY IF EXISTS equipes_delete ON public.module_equipes;
CREATE POLICY equipes_delete ON public.module_equipes FOR DELETE
USING (public.can_manage_equipe(auth.uid(), id));

-- =========== MODULE_EQUIPE_MEMBROS ===========
DROP POLICY IF EXISTS equipe_membros_update ON public.module_equipe_membros;
CREATE POLICY equipe_membros_update ON public.module_equipe_membros FOR UPDATE
USING (public.can_manage_equipe(auth.uid(), equipe_id))
WITH CHECK (public.can_manage_equipe(auth.uid(), equipe_id));

DROP POLICY IF EXISTS equipe_membros_delete ON public.module_equipe_membros;
CREATE POLICY equipe_membros_delete ON public.module_equipe_membros FOR DELETE
USING (public.can_manage_equipe(auth.uid(), equipe_id));

-- =========== MODULE_EQUIPE_COST_CENTERS ===========
DROP POLICY IF EXISTS equipe_cc_update ON public.module_equipe_cost_centers;
CREATE POLICY equipe_cc_update ON public.module_equipe_cost_centers FOR UPDATE
USING (
  public.module_is_admin(auth.uid())
  OR public.module_supervisor_has_cost_center(auth.uid(), cost_center_id)
)
WITH CHECK (
  public.module_is_admin(auth.uid())
  OR public.module_supervisor_has_cost_center(auth.uid(), cost_center_id)
);

DROP POLICY IF EXISTS equipe_cc_delete ON public.module_equipe_cost_centers;
CREATE POLICY equipe_cc_delete ON public.module_equipe_cost_centers FOR DELETE
USING (
  public.module_is_admin(auth.uid())
  OR public.module_supervisor_has_cost_center(auth.uid(), cost_center_id)
);

-- =========== PLANOS_ACAO ===========
DROP POLICY IF EXISTS plano_update ON public.planos_acao;
CREATE POLICY plano_update ON public.planos_acao FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM public.checklist_instancias i
  WHERE i.id = planos_acao.checklist_instancia_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.checklist_instancias i
  WHERE i.id = planos_acao.checklist_instancia_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
));

DROP POLICY IF EXISTS plano_delete ON public.planos_acao;
CREATE POLICY plano_delete ON public.planos_acao FOR DELETE
USING (EXISTS (
  SELECT 1 FROM public.checklist_instancias i
  WHERE i.id = planos_acao.checklist_instancia_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
));

-- =========== PLANO_ACAO_RESPONSAVEIS ===========
DROP POLICY IF EXISTS plano_resp_update ON public.plano_acao_responsaveis;
CREATE POLICY plano_resp_update ON public.plano_acao_responsaveis FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM public.planos_acao p
  JOIN public.checklist_instancias i ON i.id = p.checklist_instancia_id
  WHERE p.id = plano_acao_responsaveis.plano_acao_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.planos_acao p
  JOIN public.checklist_instancias i ON i.id = p.checklist_instancia_id
  WHERE p.id = plano_acao_responsaveis.plano_acao_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
));

DROP POLICY IF EXISTS plano_resp_delete ON public.plano_acao_responsaveis;
CREATE POLICY plano_resp_delete ON public.plano_acao_responsaveis FOR DELETE
USING (EXISTS (
  SELECT 1 FROM public.planos_acao p
  JOIN public.checklist_instancias i ON i.id = p.checklist_instancia_id
  WHERE p.id = plano_acao_responsaveis.plano_acao_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
));

-- =========== PLANO_ACAO_ATUALIZACOES ===========
DROP POLICY IF EXISTS plano_atualizacoes_update ON public.plano_acao_atualizacoes;
CREATE POLICY plano_atualizacoes_update ON public.plano_acao_atualizacoes FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM public.planos_acao p
  JOIN public.checklist_instancias i ON i.id = p.checklist_instancia_id
  WHERE p.id = plano_acao_atualizacoes.plano_acao_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.planos_acao p
  JOIN public.checklist_instancias i ON i.id = p.checklist_instancia_id
  WHERE p.id = plano_acao_atualizacoes.plano_acao_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
));

DROP POLICY IF EXISTS plano_atualizacoes_delete ON public.plano_acao_atualizacoes;
CREATE POLICY plano_atualizacoes_delete ON public.plano_acao_atualizacoes FOR DELETE
USING (EXISTS (
  SELECT 1 FROM public.planos_acao p
  JOIN public.checklist_instancias i ON i.id = p.checklist_instancia_id
  WHERE p.id = plano_acao_atualizacoes.plano_acao_id
    AND public.can_manage_checklist_cc(auth.uid(), i.cost_center_id)
));
