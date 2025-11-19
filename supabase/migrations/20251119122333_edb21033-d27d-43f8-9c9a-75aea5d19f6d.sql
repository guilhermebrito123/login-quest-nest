-- Remover coluna turno
ALTER TABLE public.postos_servico DROP COLUMN turno;

-- Limpar dados existentes da coluna jornada antes de alterar o tipo
UPDATE public.postos_servico SET jornada = NULL;

-- Alterar jornada para tipo numérico
ALTER TABLE public.postos_servico ALTER COLUMN jornada TYPE integer USING jornada::integer;

-- Remover valor padrão de efetivo_planejado
ALTER TABLE public.postos_servico ALTER COLUMN efetivo_planejado DROP DEFAULT;

-- Alterar efetivo_planejado para UUID
ALTER TABLE public.postos_servico ALTER COLUMN efetivo_planejado TYPE uuid USING NULL;

-- Adicionar foreign key
ALTER TABLE public.postos_servico ADD CONSTRAINT postos_servico_efetivo_planejado_fkey 
  FOREIGN KEY (efetivo_planejado) REFERENCES public.colaboradores(id) ON DELETE SET NULL;