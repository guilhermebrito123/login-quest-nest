-- Remove a constraint UNIQUE simples do CPF
ALTER TABLE public.colaboradores DROP CONSTRAINT IF EXISTS colaboradores_cpf_key;

-- Cria índice único parcial que ignora CPFs vazios
CREATE UNIQUE INDEX IF NOT EXISTS colaboradores_cpf_unique_nonempty 
  ON public.colaboradores(cpf) 
  WHERE cpf IS NOT NULL AND cpf <> '';