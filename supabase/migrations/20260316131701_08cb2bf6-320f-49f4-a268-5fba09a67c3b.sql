
ALTER TABLE public.faltas_colaboradores_convenia
  DROP CONSTRAINT faltas_colaboradores_convenia_diaria_temporaria_id_fkey,
  ADD CONSTRAINT faltas_colaboradores_convenia_diaria_temporaria_id_fkey
    FOREIGN KEY (diaria_temporaria_id)
    REFERENCES public.diarias_temporarias(id)
    ON DELETE SET NULL;
