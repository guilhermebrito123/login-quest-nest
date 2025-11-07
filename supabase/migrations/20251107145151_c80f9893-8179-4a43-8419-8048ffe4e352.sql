-- Remove as foreign keys antigas que apontam para auth.users
ALTER TABLE public.ordens_servico 
DROP CONSTRAINT IF EXISTS ordens_servico_responsavel_id_fkey;

ALTER TABLE public.ordens_servico 
DROP CONSTRAINT IF EXISTS ordens_servico_solicitante_id_fkey;

-- Cria novas foreign keys apontando para a tabela profiles
ALTER TABLE public.ordens_servico
ADD CONSTRAINT ordens_servico_responsavel_id_fkey 
FOREIGN KEY (responsavel_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.ordens_servico
ADD CONSTRAINT ordens_servico_solicitante_id_fkey 
FOREIGN KEY (solicitante_id) REFERENCES public.profiles(id) ON DELETE SET NULL;