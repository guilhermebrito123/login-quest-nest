-- Rename all motivo_vago_type enum values to uppercase
ALTER TYPE public.motivo_vago_type RENAME VALUE 'falta justificada' TO 'FALTA JUSTIFICADA';
ALTER TYPE public.motivo_vago_type RENAME VALUE 'falta injustificada' TO 'FALTA INJUSTIFICADA';
ALTER TYPE public.motivo_vago_type RENAME VALUE 'afastamento INSS' TO 'AFASTAMENTO INSS';
ALTER TYPE public.motivo_vago_type RENAME VALUE 'férias' TO 'FÉRIAS';
ALTER TYPE public.motivo_vago_type RENAME VALUE 'suspensão' TO 'SUSPENSÃO';
ALTER TYPE public.motivo_vago_type RENAME VALUE 'Vaga em aberto (Cobertura salário)' TO 'VAGA EM ABERTO (COBERTURA SALÁRIO)';
ALTER TYPE public.motivo_vago_type RENAME VALUE 'licença maternidade' TO 'LICENÇA MATERNIDADE';
ALTER TYPE public.motivo_vago_type RENAME VALUE 'licença paternidade' TO 'LICENÇA PATERNIDADE';
ALTER TYPE public.motivo_vago_type RENAME VALUE 'licença casamento' TO 'LICENÇA CASAMENTO';
ALTER TYPE public.motivo_vago_type RENAME VALUE 'licença nojo (falecimento)' TO 'LICENÇA NOJO (FALECIMENTO)';