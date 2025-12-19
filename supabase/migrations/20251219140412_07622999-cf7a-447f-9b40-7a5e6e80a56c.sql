-- Add intervalo_refeicao column to vagas_temp table
ALTER TABLE public.vagas_temp 
ADD COLUMN intervalo_refeicao INTEGER NOT NULL DEFAULT 60;