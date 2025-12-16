-- Create user_type enum
CREATE TYPE public.user_type AS ENUM (
  'candidato',
  'colaborador',
  'perfil_interno'
);