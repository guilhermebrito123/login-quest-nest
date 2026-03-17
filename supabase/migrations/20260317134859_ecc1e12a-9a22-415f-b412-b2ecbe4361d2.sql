ALTER TABLE public.faltas_colaboradores_convenia
ADD COLUMN local_falta uuid REFERENCES public.cost_center(id) ON DELETE SET NULL DEFAULT NULL;