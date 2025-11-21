-- Criar triggers necessárias para dias_trabalho, posto_dias_vagos e status de postos

-- 1) Gerar dias_trabalho ao criar um novo posto_servico
DROP TRIGGER IF EXISTS gerar_dias_trabalho_mes_corrente_trg ON public.postos_servico;
CREATE TRIGGER gerar_dias_trabalho_mes_corrente_trg
AFTER INSERT ON public.postos_servico
FOR EACH ROW
EXECUTE FUNCTION public.gerar_dias_trabalho_mes_corrente();

-- 2) Sincronizar dias_trabalho.status/motivo_vago com posto_dias_vagos
DROP TRIGGER IF EXISTS sync_dias_vagos_trg ON public.dias_trabalho;
CREATE TRIGGER sync_dias_vagos_trg
AFTER INSERT OR UPDATE OF status, motivo_vago ON public.dias_trabalho
FOR EACH ROW
EXECUTE FUNCTION public.sync_dias_vagos();

-- 3) Atualizar status do posto quando colaboradores são vinculados/desvinculados
DROP TRIGGER IF EXISTS atualizar_status_posto_trg ON public.colaboradores;
CREATE TRIGGER atualizar_status_posto_trg
AFTER INSERT OR UPDATE OR DELETE ON public.colaboradores
FOR EACH ROW
EXECUTE FUNCTION public.atualizar_status_posto();

-- 4) Atribuir/remover dias_trabalho quando colaborador é vinculado/desvinculado ao posto
DROP TRIGGER IF EXISTS atribuir_dias_trabalho_colaborador_trg ON public.colaboradores;
CREATE TRIGGER atribuir_dias_trabalho_colaborador_trg
AFTER INSERT OR UPDATE ON public.colaboradores
FOR EACH ROW
EXECUTE FUNCTION public.atribuir_dias_trabalho_colaborador();

-- 5) Marcar todos os dias_trabalho como vago/ocupado quando o status do posto muda
DROP TRIGGER IF EXISTS marcar_dias_posto_vago_trg ON public.postos_servico;
CREATE TRIGGER marcar_dias_posto_vago_trg
AFTER UPDATE OF status ON public.postos_servico
FOR EACH ROW
EXECUTE FUNCTION public.marcar_dias_posto_vago();