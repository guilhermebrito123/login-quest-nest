
-- Drop the partial unique indexes
DROP INDEX IF EXISTS colaboradores_user_id_unique;
DROP INDEX IF EXISTS candidatos_user_id_unique;

-- Add proper unique constraints on user_id columns
ALTER TABLE public.colaboradores
ADD CONSTRAINT colaboradores_user_id_key UNIQUE (user_id);

ALTER TABLE public.candidatos
ADD CONSTRAINT candidatos_user_id_key UNIQUE (user_id);
