-- Adicionar novas colunas para referências ao Convenia
ALTER TABLE public.diarias_temporarias
ADD COLUMN colaborador_ausente_convenia uuid NULL,
ADD COLUMN colaborador_demitido_convenia uuid NULL,
ADD COLUMN centro_custo_id uuid NULL;

-- Criar constraint para colaborador ausente (referência a colaboradores_convenia)
ALTER TABLE public.diarias_temporarias
ADD CONSTRAINT fk_colab_ausente_convenia
FOREIGN KEY (colaborador_ausente_convenia)
REFERENCES public.colaboradores_convenia (id)
ON DELETE SET NULL;

-- Criar constraint para colaborador demitido (referência a colaboradores_convenia)
ALTER TABLE public.diarias_temporarias
ADD CONSTRAINT fk_colab_demitido_convenia
FOREIGN KEY (colaborador_demitido_convenia)
REFERENCES public.colaboradores_convenia (id)
ON DELETE SET NULL;

-- Criar constraint para centro de custo (referência a cost_center)
ALTER TABLE public.diarias_temporarias
ADD CONSTRAINT fk_centro_custo
FOREIGN KEY (centro_custo_id)
REFERENCES public.cost_center (id)
ON DELETE SET NULL;