-- Tornar todos os atributos opcionais exceto nome_completo, telefone e pix
ALTER TABLE public.diaristas
  ALTER COLUMN endereco DROP NOT NULL,
  ALTER COLUMN email DROP NOT NULL,
  ALTER COLUMN possui_antecedente DROP NOT NULL,
  ALTER COLUMN cidade DROP NOT NULL,
  ALTER COLUMN agencia DROP NOT NULL,
  ALTER COLUMN banco DROP NOT NULL,
  ALTER COLUMN tipo_conta DROP NOT NULL,
  ALTER COLUMN numero_conta DROP NOT NULL,
  ALTER COLUMN anexo_dados_bancarios DROP NOT NULL,
  ALTER COLUMN anexo_cpf DROP NOT NULL,
  ALTER COLUMN anexo_comprovante_endereco DROP NOT NULL,
  ALTER COLUMN anexo_possui_antecedente DROP NOT NULL,
  ALTER COLUMN status DROP NOT NULL,
  ALTER COLUMN cep DROP NOT NULL;

-- Garantir que nome_completo, telefone e pix permanecem obrigatórios
ALTER TABLE public.diaristas
  ALTER COLUMN nome_completo SET NOT NULL,
  ALTER COLUMN telefone SET NOT NULL,
  ALTER COLUMN pix SET NOT NULL;