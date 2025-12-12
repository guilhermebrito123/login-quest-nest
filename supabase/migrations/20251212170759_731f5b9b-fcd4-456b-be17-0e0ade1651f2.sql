-- Criar enum turno_opcoes
CREATE TYPE public.turno_opcoes AS ENUM (
  'Diurno',
  'Noturno',
  'Vespertino',
  'Revezamento',
  'Ininterrupto'
);

-- Adicionar coluna turno na tabela postos_servico
ALTER TABLE public.postos_servico
ADD COLUMN turno turno_opcoes;