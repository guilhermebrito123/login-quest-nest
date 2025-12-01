-- Tornar campos obrigatórios na tabela unidades (exceto cep)
ALTER TABLE public.unidades 
  ALTER COLUMN cidade SET NOT NULL,
  ALTER COLUMN contrato_id SET NOT NULL,
  ALTER COLUMN endereco SET NOT NULL,
  ALTER COLUMN latitude SET NOT NULL,
  ALTER COLUMN longitude SET NOT NULL,
  ALTER COLUMN uf SET NOT NULL,
  ALTER COLUMN created_at SET NOT NULL,
  ALTER COLUMN updated_at SET NOT NULL;