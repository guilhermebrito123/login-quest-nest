-- Adicionar atributos licenca_nojo e novo_posto na tabela diarias_temporarias
ALTER TABLE public.diarias_temporarias
ADD COLUMN licenca_nojo boolean,
ADD COLUMN novo_posto boolean;