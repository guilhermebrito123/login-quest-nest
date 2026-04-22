CREATE OR REPLACE FUNCTION public.snapshot_template_tarefas_on_instancia()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.checklist_instancia_tarefas (
    checklist_instancia_id,
    checklist_template_tarefa_id,
    titulo_snapshot,
    descricao_snapshot,
    ajuda_snapshot,
    ordem,
    tipo_resposta_snapshot,
    obrigatoria,
    permite_comentario,
    permite_anexo,
    nota_min,
    nota_max,
    config_json_snapshot
  )
  SELECT
    NEW.id,
    tt.id,
    tt.titulo,
    tt.descricao,
    tt.ajuda,
    tt.ordem,
    tt.tipo_resposta,
    tt.obrigatoria,
    tt.permite_comentario,
    tt.permite_anexo,
    tt.nota_min,
    tt.nota_max,
    tt.config_json
  FROM public.checklist_template_tarefas tt
  WHERE tt.checklist_template_id = NEW.checklist_template_id
  ORDER BY tt.ordem, tt.created_at;

  RETURN NEW;
END;
$$;