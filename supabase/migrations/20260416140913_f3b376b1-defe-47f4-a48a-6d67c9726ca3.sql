
-- 1. Enums
CREATE TYPE public.chamado_status AS ENUM (
  'aberto', 'em_andamento', 'pendente', 'resolvido', 'fechado', 'cancelado'
);

CREATE TYPE public.chamado_prioridade AS ENUM (
  'baixa', 'media', 'alta', 'critica'
);

-- 2. Tabela cost_center_locais
CREATE TABLE public.cost_center_locais (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cost_center_id uuid NOT NULL REFERENCES public.cost_center(id) ON DELETE CASCADE,
  nome text NOT NULL,
  descricao text NULL,
  ativo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.cost_center_locais ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios autenticados podem ler locais"
  ON public.cost_center_locais FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Admins e supervisores podem gerenciar locais"
  ON public.cost_center_locais FOR ALL TO authenticated
  USING (has_role(auth.uid(), 'admin'::internal_access_level) OR has_role(auth.uid(), 'supervisor'::internal_access_level))
  WITH CHECK (has_role(auth.uid(), 'admin'::internal_access_level) OR has_role(auth.uid(), 'supervisor'::internal_access_level));

-- 3. Tabela chamado_categorias
CREATE TABLE public.chamado_categorias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL UNIQUE,
  descricao text NULL,
  ativo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.chamado_categorias ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios autenticados podem ler categorias"
  ON public.chamado_categorias FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Admins podem gerenciar categorias"
  ON public.chamado_categorias FOR ALL TO authenticated
  USING (has_role(auth.uid(), 'admin'::internal_access_level))
  WITH CHECK (has_role(auth.uid(), 'admin'::internal_access_level));

-- 4. Tabela chamados
CREATE TABLE public.chamados (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  numero bigint GENERATED ALWAYS AS IDENTITY UNIQUE,
  titulo text NOT NULL,
  descricao text NOT NULL,
  solicitante_id uuid NOT NULL REFERENCES public.usuarios(id),
  responsavel_id uuid NULL REFERENCES public.usuarios(id),
  categoria_id uuid NULL REFERENCES public.chamado_categorias(id),
  local_id uuid NOT NULL REFERENCES public.cost_center_locais(id),
  status public.chamado_status NOT NULL DEFAULT 'aberto',
  prioridade public.chamado_prioridade NOT NULL DEFAULT 'media',
  data_fechamento timestamptz NULL,
  resolvido_em timestamptz NULL,
  resolvido_por uuid NULL REFERENCES public.usuarios(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_chamados_status ON public.chamados(status);
CREATE INDEX idx_chamados_solicitante ON public.chamados(solicitante_id);
CREATE INDEX idx_chamados_responsavel ON public.chamados(responsavel_id);
CREATE INDEX idx_chamados_local ON public.chamados(local_id);
CREATE INDEX idx_chamados_created_at ON public.chamados(created_at);

ALTER TABLE public.chamados ENABLE ROW LEVEL SECURITY;

CREATE POLICY "chamados_select"
  ON public.chamados FOR SELECT TO authenticated
  USING (is_internal_user());

CREATE POLICY "chamados_insert"
  ON public.chamados FOR INSERT TO authenticated
  WITH CHECK (
    current_internal_access_level() IS NOT NULL
    OR EXISTS (SELECT 1 FROM public.usuarios u WHERE u.id = auth.uid() AND u.role = 'colaborador'::user_type)
  );

CREATE POLICY "chamados_update"
  ON public.chamados FOR UPDATE TO authenticated
  USING (
    current_internal_access_level() IS NOT NULL
    AND current_internal_access_level() <> 'cliente_view'::internal_access_level
  )
  WITH CHECK (
    current_internal_access_level() IS NOT NULL
    AND current_internal_access_level() <> 'cliente_view'::internal_access_level
  );

CREATE POLICY "chamados_delete"
  ON public.chamados FOR DELETE TO authenticated
  USING (is_admin_user());

-- 5. Tabela chamado_interacoes
CREATE TABLE public.chamado_interacoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chamado_id uuid NOT NULL REFERENCES public.chamados(id) ON DELETE CASCADE,
  autor_id uuid NOT NULL REFERENCES public.usuarios(id),
  mensagem text NOT NULL,
  interno boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_chamado_interacoes_chamado ON public.chamado_interacoes(chamado_id);

ALTER TABLE public.chamado_interacoes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "interacoes_select"
  ON public.chamado_interacoes FOR SELECT TO authenticated
  USING (is_internal_user());

CREATE POLICY "interacoes_insert"
  ON public.chamado_interacoes FOR INSERT TO authenticated
  WITH CHECK (autor_id = auth.uid());

CREATE POLICY "interacoes_delete"
  ON public.chamado_interacoes FOR DELETE TO authenticated
  USING (is_admin_user());

-- 6. Tabela chamado_anexos
CREATE TABLE public.chamado_anexos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chamado_id uuid NOT NULL REFERENCES public.chamados(id) ON DELETE CASCADE,
  uploaded_by uuid NOT NULL REFERENCES public.usuarios(id),
  nome_arquivo text NOT NULL,
  caminho_storage text NOT NULL,
  tipo_arquivo text NULL,
  tamanho_bytes bigint NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_chamado_anexos_chamado ON public.chamado_anexos(chamado_id);

ALTER TABLE public.chamado_anexos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anexos_select"
  ON public.chamado_anexos FOR SELECT TO authenticated
  USING (is_internal_user());

CREATE POLICY "anexos_insert"
  ON public.chamado_anexos FOR INSERT TO authenticated
  WITH CHECK (uploaded_by = auth.uid());

CREATE POLICY "anexos_delete"
  ON public.chamado_anexos FOR DELETE TO authenticated
  USING (is_admin_user());

-- 7. Tabela chamado_historico (auditoria completa)
CREATE TABLE public.chamado_historico (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chamado_id uuid NOT NULL REFERENCES public.chamados(id) ON DELETE CASCADE,
  usuario_id uuid NULL REFERENCES public.usuarios(id),
  operacao text NOT NULL,
  campo_alterado text NULL,
  valor_anterior text NULL,
  valor_novo text NULL,
  alteracoes jsonb NULL,
  registro_completo jsonb NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_chamado_historico_chamado ON public.chamado_historico(chamado_id);
CREATE INDEX idx_chamado_historico_created_at ON public.chamado_historico(created_at);

ALTER TABLE public.chamado_historico ENABLE ROW LEVEL SECURITY;

CREATE POLICY "historico_select"
  ON public.chamado_historico FOR SELECT TO authenticated
  USING (is_internal_user());

CREATE POLICY "historico_insert"
  ON public.chamado_historico FOR INSERT TO authenticated
  WITH CHECK (true);

-- 8. Trigger updated_at para chamados
CREATE TRIGGER update_chamados_updated_at
  BEFORE UPDATE ON public.chamados
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_cost_center_locais_updated_at
  BEFORE UPDATE ON public.cost_center_locais
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_chamado_categorias_updated_at
  BEFORE UPDATE ON public.chamado_categorias
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_chamado_interacoes_updated_at
  BEFORE UPDATE ON public.chamado_interacoes
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- 9. Trigger de validação de responsável
CREATE OR REPLACE FUNCTION public.validar_responsavel_chamado()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_role public.user_type;
  v_nivel public.internal_access_level;
BEGIN
  IF NEW.responsavel_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT u.role, ip.nivel_acesso
    INTO v_role, v_nivel
  FROM public.usuarios u
  LEFT JOIN public.internal_profiles ip ON ip.user_id = u.id
  WHERE u.id = NEW.responsavel_id;

  IF v_role IS DISTINCT FROM 'perfil_interno' THEN
    RAISE EXCEPTION 'O responsável deve ser um usuário do tipo perfil_interno';
  END IF;

  IF v_nivel IS NULL THEN
    RAISE EXCEPTION 'O responsável precisa possuir internal_profile válido';
  END IF;

  IF v_nivel = 'cliente_view' THEN
    RAISE EXCEPTION 'Usuário com nível cliente_view não pode ser responsável por chamado';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validar_responsavel_chamado
  BEFORE INSERT OR UPDATE OF responsavel_id
  ON public.chamados
  FOR EACH ROW
  EXECUTE FUNCTION public.validar_responsavel_chamado();

-- 10. Trigger de auditoria completa em chamados
CREATE OR REPLACE FUNCTION public.trg_chamados_auditoria()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_old jsonb;
  v_new jsonb;
  v_key text;
  v_usuario_id uuid;
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.chamado_historico (
      chamado_id, usuario_id, operacao, registro_completo
    ) VALUES (
      NEW.id, NEW.solicitante_id, 'insert', to_jsonb(NEW)
    );
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    v_old := to_jsonb(OLD);
    v_new := to_jsonb(NEW);
    v_usuario_id := coalesce(
      nullif(current_setting('app.user_id', true), '')::uuid,
      NEW.responsavel_id, OLD.responsavel_id,
      NEW.solicitante_id, OLD.solicitante_id
    );

    FOR v_key IN SELECT key FROM jsonb_object_keys(v_new) AS key
    LOOP
      IF (v_old ->> v_key) IS DISTINCT FROM (v_new ->> v_key) THEN
        INSERT INTO public.chamado_historico (
          chamado_id, usuario_id, operacao, campo_alterado,
          valor_anterior, valor_novo, registro_completo
        ) VALUES (
          NEW.id, v_usuario_id, 'update', v_key,
          v_old ->> v_key, v_new ->> v_key, v_new
        );
      END IF;
    END LOOP;

    RETURN NEW;
  END IF;

  IF TG_OP = 'DELETE' THEN
    INSERT INTO public.chamado_historico (
      chamado_id, usuario_id, operacao, registro_completo
    ) VALUES (
      OLD.id, coalesce(OLD.responsavel_id, OLD.solicitante_id), 'delete', to_jsonb(OLD)
    );
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

CREATE TRIGGER trg_chamados_auditoria
  AFTER INSERT OR UPDATE OR DELETE
  ON public.chamados
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_chamados_auditoria();

-- 11. Trigger de auditoria de interações
CREATE OR REPLACE FUNCTION public.trg_chamado_interacoes_auditoria()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.chamado_historico (
    chamado_id, usuario_id, operacao, alteracoes, registro_completo
  ) VALUES (
    NEW.chamado_id, NEW.autor_id, 'comentario',
    jsonb_build_object(
      'interacao_id', NEW.id,
      'interno', NEW.interno,
      'mensagem', NEW.mensagem
    ),
    to_jsonb(NEW)
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_chamado_interacoes_auditoria
  AFTER INSERT ON public.chamado_interacoes
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_chamado_interacoes_auditoria();

-- 12. Trigger de auditoria de anexos
CREATE OR REPLACE FUNCTION public.trg_chamado_anexos_auditoria()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.chamado_historico (
    chamado_id, usuario_id, operacao, alteracoes, registro_completo
  ) VALUES (
    NEW.chamado_id, NEW.uploaded_by, 'anexo',
    jsonb_build_object(
      'anexo_id', NEW.id,
      'nome_arquivo', NEW.nome_arquivo,
      'tipo_arquivo', NEW.tipo_arquivo,
      'tamanho_bytes', NEW.tamanho_bytes
    ),
    to_jsonb(NEW)
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_chamado_anexos_auditoria
  AFTER INSERT ON public.chamado_anexos
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_chamado_anexos_auditoria();

-- 13. Categorias iniciais
INSERT INTO public.chamado_categorias (nome, descricao) VALUES
  ('Manutenção', 'Chamados relacionados a manutenção predial e equipamentos'),
  ('Limpeza', 'Chamados relacionados a limpeza e conservação'),
  ('Segurança', 'Chamados relacionados a segurança patrimonial'),
  ('TI/Tecnologia', 'Chamados relacionados a tecnologia e sistemas'),
  ('Administrativo', 'Chamados administrativos gerais'),
  ('Outros', 'Chamados que não se enquadram nas categorias acima');
