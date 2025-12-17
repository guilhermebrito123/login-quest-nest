-- Add optional fields to internal_profiles table
ALTER TABLE public.internal_profiles
ADD COLUMN IF NOT EXISTS nome_completo TEXT,
ADD COLUMN IF NOT EXISTS email TEXT,
ADD COLUMN IF NOT EXISTS phone TEXT;