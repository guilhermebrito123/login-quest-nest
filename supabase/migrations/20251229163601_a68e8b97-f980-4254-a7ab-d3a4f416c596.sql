-- Criar enum para observacao_pagamento
CREATE TYPE public.observacao_pagamento_type AS ENUM (
  'Valores divergentes',
  'Beneficiário do pix não identificado'
);

-- Adicionar campos à tabela diarias_temporarias
ALTER TABLE public.diarias_temporarias 
ADD COLUMN IF NOT EXISTS ok_pagamento boolean DEFAULT NULL,
ADD COLUMN IF NOT EXISTS ok_pagamento_em timestamp with time zone,
ADD COLUMN IF NOT EXISTS ok_pagamento_por uuid REFERENCES public.usuarios(id),
ADD COLUMN IF NOT EXISTS observacao_pagamento observacao_pagamento_type,
ADD COLUMN IF NOT EXISTS outros_motivos_reprovacao_pagamento text;

-- Criar função trigger para quando ok_pagamento for marcado como true
CREATE OR REPLACE FUNCTION public.handle_ok_pagamento_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Quando ok_pagamento mudar para true
  IF NEW.ok_pagamento = true AND (OLD.ok_pagamento IS NULL OR OLD.ok_pagamento = false) THEN
    NEW.status := 'Paga'::status_diaria;
    NEW.ok_pagamento_em := now();
    NEW.ok_pagamento_por := auth.uid();
    NEW.observacao_pagamento := NULL;
    NEW.outros_motivos_reprovacao_pagamento := NULL;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Criar trigger
DROP TRIGGER IF EXISTS on_ok_pagamento_change ON public.diarias_temporarias;
CREATE TRIGGER on_ok_pagamento_change
  BEFORE UPDATE ON public.diarias_temporarias
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_ok_pagamento_change();