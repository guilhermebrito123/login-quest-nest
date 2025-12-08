-- Add criado_por column to diarias_temporarias (nullable first for existing records)
ALTER TABLE public.diarias_temporarias
ADD COLUMN criado_por uuid REFERENCES public.profiles(id) ON DELETE RESTRICT;

-- Make it NOT NULL after adding (will require updating existing records first if any exist)
-- For new records, this will be required
COMMENT ON COLUMN public.diarias_temporarias.criado_por IS 'ID do usuário que criou a diária temporária';