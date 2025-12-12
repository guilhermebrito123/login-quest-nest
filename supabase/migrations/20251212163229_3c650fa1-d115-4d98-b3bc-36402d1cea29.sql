-- Adicionar novos atributos à tabela postos_servico
ALTER TABLE public.postos_servico
ADD COLUMN valor_unitario numeric NULL,
ADD COLUMN adicional_noturno boolean NULL,
ADD COLUMN salario numeric NULL,
ADD COLUMN intrajornada boolean NULL,
ADD COLUMN insalubridade boolean NULL,
ADD COLUMN periculosidade boolean NULL,
ADD COLUMN acumulo_funcao boolean NULL,
ADD COLUMN gratificacao boolean NULL,
ADD COLUMN vt_dia numeric NULL,
ADD COLUMN vr_dia numeric NULL,
ADD COLUMN assistencia_medica boolean NULL,
ADD COLUMN cesta boolean NULL,
ADD COLUMN premio_assiduidade boolean NULL;