-- Ajustar comportamento ao excluir colaboradores para não apagar dias_trabalho
-- 1) Remover constraint atual (provavelmente ON DELETE CASCADE)
ALTER TABLE public.dias_trabalho
  DROP CONSTRAINT IF EXISTS dias_trabalho_colaborador_id_fkey;

-- 2) Recriar constraint com ON DELETE SET NULL para preservar dias_trabalho
ALTER TABLE public.dias_trabalho
  ADD CONSTRAINT dias_trabalho_colaborador_id_fkey
  FOREIGN KEY (colaborador_id)
  REFERENCES public.colaboradores(id)
  ON DELETE SET NULL;