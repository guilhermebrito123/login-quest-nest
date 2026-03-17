
ALTER TABLE public.horas_extras
  DROP CONSTRAINT horas_extras_falta_id_fkey;

ALTER TABLE public.horas_extras
  ADD CONSTRAINT horas_extras_falta_id_fkey
  FOREIGN KEY (falta_id) REFERENCES public.faltas_colaboradores_convenia(id)
  ON DELETE CASCADE;
