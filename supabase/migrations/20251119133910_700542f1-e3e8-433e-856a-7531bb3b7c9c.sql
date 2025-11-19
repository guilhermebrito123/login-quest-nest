-- Criar tabela dias_trabalho
CREATE TABLE IF NOT EXISTS public.dias_trabalho (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  posto_servico_id UUID NOT NULL REFERENCES public.postos_servico(id) ON DELETE CASCADE,
  data DATE NOT NULL,
  horario_inicio TIME,
  horario_fim TIME,
  intervalo_refeicao INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(posto_servico_id, data)
);

-- Habilitar RLS
ALTER TABLE public.dias_trabalho ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Usuarios autenticados podem ler dias_trabalho"
ON public.dias_trabalho FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Usuarios autorizados podem inserir dias_trabalho"
ON public.dias_trabalho FOR INSERT
TO authenticated
WITH CHECK (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
  has_role(auth.uid(), 'supervisor'::app_role)
);

CREATE POLICY "Usuarios autorizados podem atualizar dias_trabalho"
ON public.dias_trabalho FOR UPDATE
TO authenticated
USING (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role) OR 
  has_role(auth.uid(), 'supervisor'::app_role)
);

CREATE POLICY "Usuarios autorizados podem deletar dias_trabalho"
ON public.dias_trabalho FOR DELETE
TO authenticated
USING (
  has_role(auth.uid(), 'admin'::app_role) OR 
  has_role(auth.uid(), 'gestor_operacoes'::app_role)
);

-- Função para gerar dias de trabalho do mês corrente
CREATE OR REPLACE FUNCTION public.gerar_dias_trabalho_mes_corrente()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_data DATE;
  v_mes_inicio DATE;
  v_mes_fim DATE;
  v_dia_semana INTEGER;
BEGIN
  -- Se não há dias_semana configurados, retornar
  IF NEW.dias_semana IS NULL OR array_length(NEW.dias_semana, 1) IS NULL THEN
    RETURN NEW;
  END IF;
  
  -- Definir início e fim do mês corrente
  v_mes_inicio := date_trunc('month', CURRENT_DATE)::DATE;
  v_mes_fim := (date_trunc('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE;
  
  -- Iterar pelos dias do mês
  FOR v_data IN SELECT generate_series(v_mes_inicio, v_mes_fim, '1 day'::INTERVAL)::DATE
  LOOP
    -- Obter dia da semana (0=domingo, 1=segunda, ..., 6=sábado)
    v_dia_semana := EXTRACT(DOW FROM v_data);
    
    -- Se o dia da semana está na lista dias_semana, inserir
    IF v_dia_semana = ANY(NEW.dias_semana) THEN
      INSERT INTO public.dias_trabalho (
        posto_servico_id,
        data,
        horario_inicio,
        horario_fim,
        intervalo_refeicao
      ) VALUES (
        NEW.id,
        v_data,
        NEW.horario_inicio,
        NEW.horario_fim,
        NEW.intervalo_refeicao
      )
      ON CONFLICT (posto_servico_id, data) DO NOTHING;
    END IF;
  END LOOP;
  
  RETURN NEW;
END;
$$;

-- Trigger para gerar dias de trabalho após criar posto
CREATE TRIGGER trigger_gerar_dias_trabalho
AFTER INSERT ON public.postos_servico
FOR EACH ROW
EXECUTE FUNCTION public.gerar_dias_trabalho_mes_corrente();

-- Trigger para atualizar updated_at
CREATE TRIGGER update_dias_trabalho_updated_at
BEFORE UPDATE ON public.dias_trabalho
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();