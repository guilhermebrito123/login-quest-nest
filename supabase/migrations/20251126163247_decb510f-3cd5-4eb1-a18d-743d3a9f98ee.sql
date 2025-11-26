-- Adicionar coluna valor_diaria na tabela postos_servico
ALTER TABLE public.postos_servico
ADD COLUMN valor_diaria numeric NOT NULL DEFAULT 0;

-- Criar função para preencher automaticamente o valor da diária
CREATE OR REPLACE FUNCTION public.preencher_valor_diaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_valor_diaria numeric;
  v_posto_servico_id uuid;
BEGIN
  -- Buscar o posto_servico_id através do posto_dia_vago_id
  SELECT posto_servico_id INTO v_posto_servico_id
  FROM public.posto_dias_vagos
  WHERE id = NEW.posto_dia_vago_id;
  
  -- Buscar o valor_diaria do posto de serviço
  SELECT valor_diaria INTO v_valor_diaria
  FROM public.postos_servico
  WHERE id = v_posto_servico_id;
  
  -- Preencher o valor da diária automaticamente
  NEW.valor := v_valor_diaria;
  
  RETURN NEW;
END;
$function$;

-- Criar trigger para executar antes de insert
DROP TRIGGER IF EXISTS preencher_valor_diaria_trigger ON public.diarias;
CREATE TRIGGER preencher_valor_diaria_trigger
  BEFORE INSERT ON public.diarias
  FOR EACH ROW
  EXECUTE FUNCTION public.preencher_valor_diaria();