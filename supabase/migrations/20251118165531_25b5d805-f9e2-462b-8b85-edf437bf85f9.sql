-- Criar função para prevenir exclusão de execuções concluídas
CREATE OR REPLACE FUNCTION public.prevent_delete_completed_execucao_checklist()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF OLD.status = 'concluido' THEN
    RAISE EXCEPTION 'Não é possível excluir uma execução de checklist com status concluído';
  END IF;
  
  RETURN OLD;
END;
$function$;

-- Criar trigger para executar a função antes de DELETE
CREATE TRIGGER prevent_delete_completed_execucao_checklist_trigger
BEFORE DELETE ON public.execucao_checklist
FOR EACH ROW
EXECUTE FUNCTION public.prevent_delete_completed_execucao_checklist();