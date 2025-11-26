-- Atualizar registros existentes com valores vazios nos campos de anexo
UPDATE public.diaristas 
SET 
  anexo_comprovante_endereco = COALESCE(anexo_comprovante_endereco, ''),
  anexo_cpf = COALESCE(anexo_cpf, ''),
  anexo_dados_bancarios = COALESCE(anexo_dados_bancarios, ''),
  anexo_possui_antecedente = COALESCE(anexo_possui_antecedente, '')
WHERE anexo_comprovante_endereco IS NULL 
   OR anexo_cpf IS NULL 
   OR anexo_dados_bancarios IS NULL 
   OR anexo_possui_antecedente IS NULL;

-- Tornar campos de anexo obrigatórios
ALTER TABLE public.diaristas 
  ALTER COLUMN anexo_comprovante_endereco SET NOT NULL,
  ALTER COLUMN anexo_cpf SET NOT NULL,
  ALTER COLUMN anexo_dados_bancarios SET NOT NULL,
  ALTER COLUMN anexo_possui_antecedente SET NOT NULL;