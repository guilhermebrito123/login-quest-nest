-- Drop the enum if it exists (from previous failed attempt)
DROP TYPE IF EXISTS acumulo_funcao_options;

-- Create the enum type for acumulo_funcao
CREATE TYPE acumulo_funcao_options AS ENUM ('Sim', 'Não', 'Especial');

-- Alter the column to use the new enum type (converting from boolean)
ALTER TABLE public.postos_servico 
ALTER COLUMN acumulo_funcao TYPE acumulo_funcao_options 
USING CASE 
  WHEN acumulo_funcao IS NULL THEN NULL
  WHEN acumulo_funcao = true THEN 'Sim'::acumulo_funcao_options
  WHEN acumulo_funcao = false THEN 'Não'::acumulo_funcao_options
  ELSE NULL
END;