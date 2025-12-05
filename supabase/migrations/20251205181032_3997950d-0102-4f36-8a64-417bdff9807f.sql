-- Rename existing enum value and add new ones
ALTER TYPE public.motivo_vago_type RENAME VALUE 'Posto vago' TO 'Vaga em aberto (Cobertura salário)';

ALTER TYPE public.motivo_vago_type ADD VALUE IF NOT EXISTS 'licença maternidade';
ALTER TYPE public.motivo_vago_type ADD VALUE IF NOT EXISTS 'licença paternidade';
ALTER TYPE public.motivo_vago_type ADD VALUE IF NOT EXISTS 'licença casamento';
ALTER TYPE public.motivo_vago_type ADD VALUE IF NOT EXISTS 'licença nojo (falecimento)';