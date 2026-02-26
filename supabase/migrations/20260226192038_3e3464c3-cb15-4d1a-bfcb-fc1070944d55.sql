-- Drop the old UUID overload that's causing ambiguity
DROP FUNCTION IF EXISTS public.justificar_falta_convenia_por_falta_id(uuid, text, uuid);
