-- Alterar dias_semana para permitir NULL
ALTER TABLE public.postos_servico 
ALTER COLUMN dias_semana DROP NOT NULL;

-- Adicionar coluna beneficios (array de strings, aceita null)
ALTER TABLE public.postos_servico 
ADD COLUMN beneficios TEXT[] NULL;

-- Adicionar coluna primeiro_dia_atividade (data, aceita null)
ALTER TABLE public.postos_servico 
ADD COLUMN primeiro_dia_atividade DATE NULL;

-- Criar função de validação para dias_semana baseado na escala
CREATE OR REPLACE FUNCTION public.validar_dias_semana_escala()
RETURNS TRIGGER AS $$
BEGIN
  -- Se a escala for 5x2 ou 6x1, dias_semana é obrigatório
  IF NEW.escala IN ('5x2', '6x1') AND NEW.dias_semana IS NULL THEN
    RAISE EXCEPTION 'Para escalas 5x2 e 6x1, o campo dias_semana é obrigatório';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger para validar dias_semana
DROP TRIGGER IF EXISTS validar_dias_semana_trigger ON public.postos_servico;
CREATE TRIGGER validar_dias_semana_trigger
  BEFORE INSERT OR UPDATE ON public.postos_servico
  FOR EACH ROW
  EXECUTE FUNCTION public.validar_dias_semana_escala();