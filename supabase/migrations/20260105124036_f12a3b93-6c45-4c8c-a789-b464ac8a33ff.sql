-- Criar enum motivo_reprovacao
CREATE TYPE public.motivo_reprovacao AS ENUM ('Diarista ausente', 'Dados incorretos');

-- Alterar coluna motivo_reprovacao para usar o novo enum
ALTER TABLE public.diarias_temporarias 
ALTER COLUMN motivo_reprovacao TYPE public.motivo_reprovacao 
USING motivo_reprovacao::public.motivo_reprovacao;

-- Adicionar coluna motivo_reprovacao_observacao
ALTER TABLE public.diarias_temporarias 
ADD COLUMN motivo_reprovacao_observacao text DEFAULT NULL;