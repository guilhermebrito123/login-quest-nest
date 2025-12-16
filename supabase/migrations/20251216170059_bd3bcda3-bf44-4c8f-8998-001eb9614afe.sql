-- Change role column to user_type enum
ALTER TABLE public.usuarios 
  ALTER COLUMN role DROP DEFAULT;

ALTER TABLE public.usuarios 
  ALTER COLUMN role TYPE public.user_type 
  USING 'perfil_interno'::public.user_type;

-- Set default for new registrations to 'candidato'
ALTER TABLE public.usuarios 
  ALTER COLUMN role SET DEFAULT 'candidato'::public.user_type;