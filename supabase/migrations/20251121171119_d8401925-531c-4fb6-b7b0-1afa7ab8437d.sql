-- Criar função para validar diárias pendentes
CREATE OR REPLACE FUNCTION public.validar_diarias_pendentes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Verificar se o diarista tem diárias com status "Aguardando confirmacao"
  IF EXISTS (
    SELECT 1 
    FROM public.diarias 
    WHERE diarista_id = NEW.diarista_id 
    AND status = 'Aguardando confirmacao'::status_diaria
    AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
  ) THEN
    RAISE EXCEPTION 'O diarista possui diárias com status "Aguardando confirmacao". Confirme ou cancele essas diárias antes de criar uma nova.';
  END IF;
  
  RETURN NEW;
END;
$$;

-- Criar trigger para validar antes de inserir ou atualizar
CREATE TRIGGER validar_diarias_pendentes_trigger
  BEFORE INSERT OR UPDATE ON public.diarias
  FOR EACH ROW
  EXECUTE FUNCTION public.validar_diarias_pendentes();