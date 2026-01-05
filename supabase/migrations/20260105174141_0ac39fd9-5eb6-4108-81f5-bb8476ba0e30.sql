-- Criar função de validação
CREATE OR REPLACE FUNCTION public.validar_diarista_blacklist()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.blacklist WHERE diarista_id = NEW.diarista_id) THEN
    RAISE EXCEPTION 'Diarista está na blacklist e não pode ser vinculado a uma diária temporária';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Criar trigger para INSERT
CREATE TRIGGER trigger_validar_blacklist_insert
BEFORE INSERT ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.validar_diarista_blacklist();

-- Criar trigger para UPDATE (caso o diarista_id seja alterado)
CREATE TRIGGER trigger_validar_blacklist_update
BEFORE UPDATE OF diarista_id ON public.diarias_temporarias
FOR EACH ROW
WHEN (OLD.diarista_id IS DISTINCT FROM NEW.diarista_id)
EXECUTE FUNCTION public.validar_diarista_blacklist();