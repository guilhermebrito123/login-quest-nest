-- Remover a constraint valid_movimentacao que está impedindo a exclusão
-- Com CASCADE DELETE nas foreign keys, não precisamos dessa constraint
-- pois as rows serão deletadas automaticamente quando um posto for deletado

ALTER TABLE public.colaborador_movimentacoes_posto
DROP CONSTRAINT IF EXISTS valid_movimentacao;