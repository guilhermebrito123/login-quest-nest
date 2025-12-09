-- Add cancelada_por and reprovada_por columns to diarias_temporarias
ALTER TABLE public.diarias_temporarias
ADD COLUMN cancelada_por uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
ADD COLUMN reprovada_por uuid REFERENCES public.profiles(id) ON DELETE SET NULL;

-- Add comments for documentation
COMMENT ON COLUMN public.diarias_temporarias.cancelada_por IS 'ID do usuário que cancelou a diária';
COMMENT ON COLUMN public.diarias_temporarias.reprovada_por IS 'ID do usuário que reprovou a diária';

-- Update trigger function to include cancellation and rejection tracking
CREATE OR REPLACE FUNCTION public.registrar_responsavel_status_diaria_temporaria()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Track who changed the status based on status transition
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    CASE NEW.status
      WHEN 'Confirmada'::status_diaria THEN
        NEW.confirmada_por := auth.uid();
      WHEN 'Aprovada'::status_diaria THEN
        NEW.aprovada_por := auth.uid();
      WHEN 'Lançada para pagamento'::status_diaria THEN
        NEW.lancada_por := auth.uid();
      WHEN 'Aprovada para pagamento'::status_diaria THEN
        NEW.aprovado_para_pgto_por := auth.uid();
      WHEN 'Paga'::status_diaria THEN
        NEW.paga_por := auth.uid();
      WHEN 'Cancelada'::status_diaria THEN
        NEW.cancelada_por := auth.uid();
      WHEN 'Reprovada'::status_diaria THEN
        NEW.reprovada_por := auth.uid();
      ELSE
        NULL;
    END CASE;
  END IF;
  
  RETURN NEW;
END;
$$;