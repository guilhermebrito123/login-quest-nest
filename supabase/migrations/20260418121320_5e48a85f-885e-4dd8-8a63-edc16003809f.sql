-- Remover policy antiga "ALL" que dava acesso amplo a admin/supervisor sem checar vínculo
DROP POLICY IF EXISTS "Admins e supervisores podem gerenciar locais" ON public.cost_center_locais;

-- SELECT: mantém leitura para qualquer autenticado (já existia "Usuarios autenticados podem ler locais")
-- Não recriamos essa policy pois ela já existe.

-- INSERT: admin OU operacional com vínculo no cost_center do local
CREATE POLICY "insert_cost_center_locais_internal_scope"
ON public.cost_center_locais
FOR INSERT
TO authenticated
WITH CHECK (
  public.internal_user_is_admin(auth.uid())
  OR public.internal_user_has_cost_center_access(auth.uid(), cost_center_id)
);

-- UPDATE: admin OU operacional com vínculo (tanto na linha atual quanto na nova)
CREATE POLICY "update_cost_center_locais_internal_scope"
ON public.cost_center_locais
FOR UPDATE
TO authenticated
USING (
  public.internal_user_is_admin(auth.uid())
  OR public.internal_user_has_cost_center_access(auth.uid(), cost_center_id)
)
WITH CHECK (
  public.internal_user_is_admin(auth.uid())
  OR public.internal_user_has_cost_center_access(auth.uid(), cost_center_id)
);

-- DELETE: admin OU operacional com vínculo
CREATE POLICY "delete_cost_center_locais_internal_scope"
ON public.cost_center_locais
FOR DELETE
TO authenticated
USING (
  public.internal_user_is_admin(auth.uid())
  OR public.internal_user_has_cost_center_access(auth.uid(), cost_center_id)
);