-- Add missing driver_license_emission_date column
ALTER TABLE public.colaboradores_convenia 
ADD COLUMN IF NOT EXISTS driver_license_emission_date DATE;