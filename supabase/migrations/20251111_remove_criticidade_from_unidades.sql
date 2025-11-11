/*
  # Remove criticidade column from unidades table

  1. Changes
    - Drop `criticidade` column from `unidades` table
    - This column is no longer needed in the unit/location management
*/

ALTER TABLE public.unidades DROP COLUMN IF EXISTS criticidade;