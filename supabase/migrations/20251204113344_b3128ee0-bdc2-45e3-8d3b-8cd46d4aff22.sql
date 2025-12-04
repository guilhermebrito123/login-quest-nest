-- Remover constraint existente (se apontar para auth.users) e recriar para profiles
ALTER TABLE public.chamados_comentarios
DROP CONSTRAINT IF EXISTS chamados_comentarios_usuario_id_fkey;

ALTER TABLE public.chamados_comentarios
ADD CONSTRAINT chamados_comentarios_usuario_id_fkey
FOREIGN KEY (usuario_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- Fazer o mesmo para chamados_anexos
ALTER TABLE public.chamados_anexos
DROP CONSTRAINT IF EXISTS chamados_anexos_usuario_id_fkey;

ALTER TABLE public.chamados_anexos
ADD CONSTRAINT chamados_anexos_usuario_id_fkey
FOREIGN KEY (usuario_id) REFERENCES public.profiles(id) ON DELETE CASCADE;