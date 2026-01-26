-- Drop existing foreign key constraint first
ALTER TABLE public.colaboradores_convenia
DROP CONSTRAINT IF EXISTS colaboradores_convenia_cost_center_fk;

-- Add new UUID column for cost_center reference
ALTER TABLE public.colaboradores_convenia
ADD COLUMN cost_center_uuid uuid;

-- Update new column with matching UUIDs from cost_center table based on convenia_id
UPDATE public.colaboradores_convenia cc
SET cost_center_uuid = c.id
FROM public.cost_center c
WHERE cc.cost_center_id = c.convenia_id;

-- Drop old text column
ALTER TABLE public.colaboradores_convenia
DROP COLUMN cost_center_id;

-- Rename new column to cost_center_id
ALTER TABLE public.colaboradores_convenia
RENAME COLUMN cost_center_uuid TO cost_center_id;

-- Create new foreign key constraint referencing cost_center.id
ALTER TABLE public.colaboradores_convenia
ADD CONSTRAINT colaboradores_convenia_cost_center_fk
FOREIGN KEY (cost_center_id) REFERENCES public.cost_center(id)
ON UPDATE CASCADE
ON DELETE SET NULL;