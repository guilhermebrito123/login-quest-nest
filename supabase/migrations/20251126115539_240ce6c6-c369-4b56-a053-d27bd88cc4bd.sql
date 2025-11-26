-- Criar enum status_diarista
CREATE TYPE status_diarista AS ENUM ('ativo', 'inativo', 'desligado');

-- Criar enum tipo_conta_bancaria
CREATE TYPE tipo_conta_bancaria AS ENUM ('conta corrente', 'conta poupança', 'conta salário');

-- Remover colunas rg e cnh
ALTER TABLE public.diaristas
DROP COLUMN IF EXISTS rg,
DROP COLUMN IF EXISTS cnh;

-- Alterar cidade para NOT NULL
ALTER TABLE public.diaristas
ALTER COLUMN cidade SET NOT NULL;

-- Adicionar novos campos obrigatórios
ALTER TABLE public.diaristas
ADD COLUMN agencia TEXT NOT NULL DEFAULT '',
ADD COLUMN banco TEXT NOT NULL DEFAULT '',
ADD COLUMN tipo_conta tipo_conta_bancaria NOT NULL DEFAULT 'conta corrente'::tipo_conta_bancaria,
ADD COLUMN numero_conta TEXT NOT NULL DEFAULT '',
ADD COLUMN pix TEXT NOT NULL DEFAULT '',
ADD COLUMN anexo_dados_bancarios TEXT,
ADD COLUMN anexo_cpf TEXT,
ADD COLUMN anexo_comprovante_endereco TEXT,
ADD COLUMN anexo_possui_antecedente TEXT;

-- Alterar coluna status para usar novo enum
-- Primeiro criar coluna temporária
ALTER TABLE public.diaristas
ADD COLUMN status_new status_diarista;

-- Migrar dados (mapear 'ativo' para 'ativo', outros valores para 'inativo')
UPDATE public.diaristas
SET status_new = CASE 
  WHEN status = 'ativo' THEN 'ativo'::status_diarista
  ELSE 'inativo'::status_diarista
END;

-- Remover coluna antiga e renomear nova
ALTER TABLE public.diaristas
DROP COLUMN status,
ALTER COLUMN status_new SET NOT NULL,
ALTER COLUMN status_new SET DEFAULT 'ativo'::status_diarista;

ALTER TABLE public.diaristas
RENAME COLUMN status_new TO status;

-- Atualizar RLS policies para usar novo enum (se necessário)
-- As policies existentes devem continuar funcionando