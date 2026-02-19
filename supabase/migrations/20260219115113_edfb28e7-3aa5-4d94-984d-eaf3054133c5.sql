
-- Remover políticas existentes
DROP POLICY IF EXISTS "Usuarios autorizados podem inserir faltas_convenia" ON public.faltas_colaboradores_convenia;
DROP POLICY IF EXISTS "Usuarios autorizados podem atualizar faltas_convenia" ON public.faltas_colaboradores_convenia;
DROP POLICY IF EXISTS "Admins podem deletar faltas_convenia" ON public.faltas_colaboradores_convenia;

-- Recriar com assistente_operacoes incluído
CREATE POLICY "Usuarios autorizados podem inserir faltas_convenia"
  ON public.faltas_colaboradores_convenia
  FOR INSERT
  WITH CHECK (
    has_role(auth.uid(), 'admin'::internal_access_level) OR
    has_role(auth.uid(), 'gestor_operacoes'::internal_access_level) OR
    has_role(auth.uid(), 'supervisor'::internal_access_level) OR
    has_role(auth.uid(), 'assistente_operacoes'::internal_access_level)
  );

CREATE POLICY "Usuarios autorizados podem atualizar faltas_convenia"
  ON public.faltas_colaboradores_convenia
  FOR UPDATE
  USING (
    has_role(auth.uid(), 'admin'::internal_access_level) OR
    has_role(auth.uid(), 'gestor_operacoes'::internal_access_level) OR
    has_role(auth.uid(), 'supervisor'::internal_access_level) OR
    has_role(auth.uid(), 'assistente_operacoes'::internal_access_level)
  );

CREATE POLICY "Usuarios autorizados podem deletar faltas_convenia"
  ON public.faltas_colaboradores_convenia
  FOR DELETE
  USING (
    has_role(auth.uid(), 'admin'::internal_access_level) OR
    has_role(auth.uid(), 'assistente_operacoes'::internal_access_level)
  );
