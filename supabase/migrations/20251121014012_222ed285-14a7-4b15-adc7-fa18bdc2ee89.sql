-- Criar ENUM para motivo_vago
CREATE TYPE motivo_vago_type AS ENUM (
  'falta justificada',
  'falta injustificada',
  'afastamento INSS',
  'férias',
  'suspensão',
  'Posto vago'
);

-- Adicionar coluna motivo_vago à tabela dias_trabalho
ALTER TABLE public.dias_trabalho
ADD COLUMN motivo_vago motivo_vago_type;