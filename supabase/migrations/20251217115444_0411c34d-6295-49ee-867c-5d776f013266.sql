
-- Make candidatos columns optional except nome_completo and email
ALTER TABLE public.candidatos 
  ALTER COLUMN cidade DROP NOT NULL,
  ALTER COLUMN estado DROP NOT NULL,
  ALTER COLUMN telefone DROP NOT NULL,
  ALTER COLUMN celular DROP NOT NULL,
  ALTER COLUMN curriculo_path DROP NOT NULL,
  ALTER COLUMN experiencia_relevante DROP NOT NULL;
