-- Verificar e recriar a trigger que gera dias_trabalho ao criar/atualizar posto_servico

-- Dropar trigger se existir
DROP TRIGGER IF EXISTS trigger_gerar_dias_trabalho_mes_corrente ON public.postos_servico;

-- Recriar trigger para gerar dias_trabalho ao inserir ou atualizar posto
CREATE TRIGGER trigger_gerar_dias_trabalho_mes_corrente
  AFTER INSERT OR UPDATE OF escala, dias_semana, horario_inicio, horario_fim, intervalo_refeicao, primeiro_dia_atividade
  ON public.postos_servico
  FOR EACH ROW
  EXECUTE FUNCTION public.gerar_dias_trabalho_mes_corrente();