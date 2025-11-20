-- Criar ENUM para status de posto
CREATE TYPE status_posto AS ENUM ('vago', 'ocupado', 'vago_temporariamente', 'ocupado_temporariamente');

-- Remover CHECK constraint antigo (ENUM já faz a validação)
ALTER TABLE public.postos_servico
DROP CONSTRAINT IF EXISTS postos_servico_status_check;

-- Remover default temporariamente
ALTER TABLE public.postos_servico
ALTER COLUMN status DROP DEFAULT;

-- Converter coluna status para usar o ENUM
ALTER TABLE public.postos_servico
ALTER COLUMN status TYPE status_posto USING status::status_posto;

-- Recriar default com o tipo correto
ALTER TABLE public.postos_servico
ALTER COLUMN status SET DEFAULT 'vago'::status_posto;