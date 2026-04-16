-- =====================================================
-- AUDITORIA DE CHAMADOS COM TIMESTAMP PRECISO
-- =====================================================

-- Recria função de auditoria da tabela chamados com timestamp explícito
CREATE OR REPLACE FUNCTION public.trg_chamados_auditoria()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_old jsonb;
  v_new jsonb;
  v_key text;
  v_usuario_id uuid;
  v_timestamp timestamptz;
BEGIN
  -- Captura timestamp exato no timezone de Brasília
  v_timestamp := now() AT TIME ZONE 'America/Sao_Paulo';

  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.chamado_historico (
      chamado_id,
      usuario_id,
      operacao,
      alteracoes,
      registro_completo,
      created_at
    ) VALUES (
      NEW.id,
      NEW.solicitante_id,
      'insert',
      NULL,
      to_jsonb(NEW),
      v_timestamp
    );
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    v_old := to_jsonb(OLD);
    v_new := to_jsonb(NEW);
    v_usuario_id := COALESCE(NEW.responsavel_id, OLD.responsavel_id, NEW.solicitante_id, OLD.solicitante_id);

    -- Registra cada campo alterado com timestamp preciso
    FOR v_key IN
      SELECT key FROM jsonb_object_keys(v_new) AS key
    LOOP
      IF (v_old ->> v_key) IS DISTINCT FROM (v_new ->> v_key) THEN
        INSERT INTO public.chamado_historico (
          chamado_id,
          usuario_id,
          operacao,
          campo_alterado,
          valor_anterior,
          valor_novo,
          registro_completo,
          created_at
        ) VALUES (
          NEW.id,
          v_usuario_id,
          'update',
          v_key,
          v_old ->> v_key,
          v_new ->> v_key,
          v_new,
          v_timestamp
        );
      END IF;
    END LOOP;
    RETURN NEW;
  END IF;

  IF TG_OP = 'DELETE' THEN
    INSERT INTO public.chamado_historico (
      chamado_id,
      usuario_id,
      operacao,
      alteracoes,
      registro_completo,
      created_at
    ) VALUES (
      OLD.id,
      COALESCE(OLD.responsavel_id, OLD.solicitante_id),
      'delete',
      NULL,
      to_jsonb(OLD),
      v_timestamp
    );
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

-- Recria função de auditoria de interações com timestamp explícito
CREATE OR REPLACE FUNCTION public.trg_chamado_interacoes_auditoria()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_timestamp timestamptz;
BEGIN
  v_timestamp := now() AT TIME ZONE 'America/Sao_Paulo';

  INSERT INTO public.chamado_historico (
    chamado_id,
    usuario_id,
    operacao,
    alteracoes,
    registro_completo,
    created_at
  ) VALUES (
    NEW.chamado_id,
    NEW.autor_id,
    'comentario',
    jsonb_build_object(
      'interacao_id', NEW.id,
      'interno', NEW.interno,
      'mensagem', NEW.mensagem
    ),
    to_jsonb(NEW),
    v_timestamp
  );
  RETURN NEW;
END;
$$;

-- Recria função de auditoria de anexos com timestamp explícito
CREATE OR REPLACE FUNCTION public.trg_chamado_anexos_auditoria()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_timestamp timestamptz;
BEGIN
  v_timestamp := now() AT TIME ZONE 'America/Sao_Paulo';

  INSERT INTO public.chamado_historico (
    chamado_id,
    usuario_id,
    operacao,
    alteracoes,
    registro_completo,
    created_at
  ) VALUES (
    NEW.chamado_id,
    NEW.uploaded_by,
    'anexo',
    jsonb_build_object(
      'anexo_id', NEW.id,
      'nome_arquivo', NEW.nome_arquivo,
      'tipo_arquivo', NEW.tipo_arquivo,
      'tamanho_bytes', NEW.tamanho_bytes
    ),
    to_jsonb(NEW),
    v_timestamp
  );
  RETURN NEW;
END;
$$;

-- Adiciona índice composto para consultas por período e tipo de operação
CREATE INDEX IF NOT EXISTS idx_chamado_historico_created_operacao
  ON public.chamado_historico(created_at DESC, operacao);

-- Comentário explicativo
COMMENT ON COLUMN public.chamado_historico.created_at IS 
  'Data e hora exata da operação CRUD no timezone America/Sao_Paulo. Registrado automaticamente pelos triggers de auditoria.';