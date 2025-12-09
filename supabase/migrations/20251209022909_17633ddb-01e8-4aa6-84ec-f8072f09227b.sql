-- Add status tracking columns to diarias_temporarias
ALTER TABLE public.diarias_temporarias
ADD COLUMN confirmada_por uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
ADD COLUMN aprovada_por uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
ADD COLUMN lancada_por uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
ADD COLUMN aprovado_para_pgto_por uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
ADD COLUMN paga_por uuid REFERENCES public.profiles(id) ON DELETE SET NULL;

-- Add comments for documentation
COMMENT ON COLUMN public.diarias_temporarias.confirmada_por IS 'ID do usuário que confirmou a diária';
COMMENT ON COLUMN public.diarias_temporarias.aprovada_por IS 'ID do usuário que aprovou a diária';
COMMENT ON COLUMN public.diarias_temporarias.lancada_por IS 'ID do usuário que lançou para pagamento';
COMMENT ON COLUMN public.diarias_temporarias.aprovado_para_pgto_por IS 'ID do usuário que aprovou para pagamento';
COMMENT ON COLUMN public.diarias_temporarias.paga_por IS 'ID do usuário que registrou o pagamento';

-- Create trigger function to track status changes
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
      ELSE
        -- For other statuses (Cancelada, Reprovada, Aguardando confirmacao), no tracking needed
        NULL;
    END CASE;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger
CREATE TRIGGER registrar_responsavel_status_diaria_temporaria_trigger
BEFORE UPDATE ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.registrar_responsavel_status_diaria_temporaria();