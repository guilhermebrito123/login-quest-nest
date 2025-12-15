-- Add 'cliente_view' to app_role enum if not exists
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'cliente_view';

-- Add role column to profiles with default 'cliente_view'
ALTER TABLE public.profiles 
ADD COLUMN role public.app_role NOT NULL DEFAULT 'cliente_view';

-- Set existing profiles to 'admin'
UPDATE public.profiles SET role = 'admin' WHERE role = 'cliente_view';