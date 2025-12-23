-- Adicionar política de DELETE para diarias_temporarias
-- Só permite deletar quando status for 'Cancelada' ou 'Reprovada'
CREATE POLICY "Deletar apenas diarias canceladas ou reprovadas"
ON public.diarias_temporarias
FOR DELETE
USING (status IN ('Cancelada', 'Reprovada'));