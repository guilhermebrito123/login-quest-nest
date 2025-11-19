-- Adicionar coluna colaborador_id à tabela dias_trabalho
ALTER TABLE public.dias_trabalho
ADD COLUMN colaborador_id uuid REFERENCES public.colaboradores(id) ON DELETE CASCADE;

COMMENT ON COLUMN public.dias_trabalho.colaborador_id IS 'Colaborador atribuído a este dia de trabalho. Se NULL, o dia é genérico do posto.';

-- Criar índice para melhorar performance de consultas
CREATE INDEX idx_dias_trabalho_colaborador_id ON public.dias_trabalho(colaborador_id);

-- Função para copiar dias_trabalho do posto para o colaborador
CREATE OR REPLACE FUNCTION public.atribuir_dias_trabalho_colaborador()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  -- Se o colaborador foi atribuído a um posto (INSERT ou UPDATE com novo posto)
  IF NEW.posto_servico_id IS NOT NULL AND (TG_OP = 'INSERT' OR OLD.posto_servico_id IS DISTINCT FROM NEW.posto_servico_id) THEN
    
    -- Remover dias_trabalho anteriores deste colaborador (se estiver mudando de posto)
    IF TG_OP = 'UPDATE' AND OLD.posto_servico_id IS NOT NULL THEN
      DELETE FROM public.dias_trabalho
      WHERE colaborador_id = NEW.id;
    END IF;
    
    -- Copiar dias_trabalho do posto para o colaborador
    INSERT INTO public.dias_trabalho (posto_servico_id, data, horario_inicio, horario_fim, intervalo_refeicao, colaborador_id)
    SELECT 
      posto_servico_id,
      data,
      horario_inicio,
      horario_fim,
      intervalo_refeicao,
      NEW.id
    FROM public.dias_trabalho
    WHERE posto_servico_id = NEW.posto_servico_id
      AND colaborador_id IS NULL  -- Apenas os dias genéricos do posto
      AND data >= CURRENT_DATE;   -- Apenas dias futuros e de hoje
      
  -- Se o colaborador foi removido do posto
  ELSIF NEW.posto_servico_id IS NULL AND TG_OP = 'UPDATE' AND OLD.posto_servico_id IS NOT NULL THEN
    -- Remover dias_trabalho do colaborador
    DELETE FROM public.dias_trabalho
    WHERE colaborador_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Criar trigger para atribuir dias_trabalho quando colaborador for atribuído a posto
CREATE TRIGGER trigger_atribuir_dias_trabalho_colaborador
AFTER INSERT OR UPDATE ON public.colaboradores
FOR EACH ROW
EXECUTE FUNCTION public.atribuir_dias_trabalho_colaborador();

-- Atualizar RLS policy para dias_trabalho incluir acesso por colaborador_id
DROP POLICY IF EXISTS "Usuarios autenticados podem ler dias_trabalho" ON public.dias_trabalho;

CREATE POLICY "Usuarios autenticados podem ler dias_trabalho"
ON public.dias_trabalho
FOR SELECT
TO authenticated
USING (true);