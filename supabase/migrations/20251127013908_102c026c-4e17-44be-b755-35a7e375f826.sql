-- Criar trigger para validar status de dias_trabalho com colaborador alocado
CREATE OR REPLACE FUNCTION public.validar_status_dia_trabalho()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Se há colaborador alocado, status não pode ser "vago"
  IF NEW.colaborador_id IS NOT NULL AND NEW.status = 'vago'::status_posto THEN
    RAISE EXCEPTION 'Dia de trabalho com colaborador alocado não pode ter status "vago"';
  END IF;
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS validar_status_dia_trabalho_trigger ON public.dias_trabalho;

CREATE TRIGGER validar_status_dia_trabalho_trigger
BEFORE INSERT OR UPDATE ON public.dias_trabalho
FOR EACH ROW
EXECUTE FUNCTION public.validar_status_dia_trabalho();

-- Ajustar timezone padrão das tabelas principais para usar horário do Brasil
-- Atualizar defaults das colunas created_at e updated_at para usar timezone brasileiro

-- postos_servico
ALTER TABLE public.postos_servico 
  ALTER COLUMN created_at SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo');
ALTER TABLE public.postos_servico 
  ALTER COLUMN updated_at SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo');

-- dias_trabalho
ALTER TABLE public.dias_trabalho 
  ALTER COLUMN created_at SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo');
ALTER TABLE public.dias_trabalho 
  ALTER COLUMN updated_at SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo');

-- colaboradores
ALTER TABLE public.colaboradores 
  ALTER COLUMN created_at SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo');
ALTER TABLE public.colaboradores 
  ALTER COLUMN updated_at SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo');

-- diarias
ALTER TABLE public.diarias 
  ALTER COLUMN created_at SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo');
ALTER TABLE public.diarias 
  ALTER COLUMN updated_at SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo');

-- posto_dias_vagos
ALTER TABLE public.posto_dias_vagos 
  ALTER COLUMN created_at SET DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo');