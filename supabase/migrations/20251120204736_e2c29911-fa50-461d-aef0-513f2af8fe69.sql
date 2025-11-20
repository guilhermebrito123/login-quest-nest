-- Create trigger to automatically update posto_servico status when colaborador is assigned
DROP TRIGGER IF EXISTS atualizar_status_posto_trigger ON public.colaboradores;

CREATE TRIGGER atualizar_status_posto_trigger
  AFTER INSERT OR UPDATE OF posto_servico_id OR DELETE ON public.colaboradores
  FOR EACH ROW EXECUTE FUNCTION public.atualizar_status_posto();