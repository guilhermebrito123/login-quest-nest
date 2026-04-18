-- Trocar FK de chamado_historico -> chamados para ON DELETE CASCADE
ALTER TABLE public.chamado_historico
  DROP CONSTRAINT IF EXISTS chamado_historico_chamado_id_fkey;

ALTER TABLE public.chamado_historico
  ADD CONSTRAINT chamado_historico_chamado_id_fkey
  FOREIGN KEY (chamado_id) REFERENCES public.chamados(id) ON DELETE CASCADE;

-- Mesmo tratamento para anexos e interações para evitar erros similares
ALTER TABLE public.chamado_anexos
  DROP CONSTRAINT IF EXISTS chamado_anexos_chamado_id_fkey;
ALTER TABLE public.chamado_anexos
  ADD CONSTRAINT chamado_anexos_chamado_id_fkey
  FOREIGN KEY (chamado_id) REFERENCES public.chamados(id) ON DELETE CASCADE;

ALTER TABLE public.chamado_interacoes
  DROP CONSTRAINT IF EXISTS chamado_interacoes_chamado_id_fkey;
ALTER TABLE public.chamado_interacoes
  ADD CONSTRAINT chamado_interacoes_chamado_id_fkey
  FOREIGN KEY (chamado_id) REFERENCES public.chamados(id) ON DELETE CASCADE;