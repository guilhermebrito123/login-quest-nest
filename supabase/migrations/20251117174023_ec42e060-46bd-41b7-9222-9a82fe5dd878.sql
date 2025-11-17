-- Remove contrato_id and unidade_id from checklist table
ALTER TABLE public.checklist
  DROP COLUMN IF EXISTS contrato_id,
  DROP COLUMN IF EXISTS unidade_id;

-- Add contrato_id and unidade_id to execucao_checklist
ALTER TABLE public.execucao_checklist
  ADD COLUMN IF NOT EXISTS contrato_id UUID REFERENCES public.contratos(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS unidade_id UUID REFERENCES public.unidades(id) ON DELETE SET NULL;

-- Add contrato_id and unidade_id to execucao_checklist_item
ALTER TABLE public.execucao_checklist_item
  ADD COLUMN IF NOT EXISTS contrato_id UUID REFERENCES public.contratos(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS unidade_id UUID REFERENCES public.unidades(id) ON DELETE SET NULL;