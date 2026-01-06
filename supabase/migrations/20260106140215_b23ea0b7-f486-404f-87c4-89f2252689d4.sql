
-- Recriar a função de log de alterações por campo
CREATE OR REPLACE FUNCTION public.log_diaria_temporaria_changes()
RETURNS TRIGGER AS $$
BEGIN
  -- Registrar alterações campo a campo
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
    VALUES (NEW.id, 'registro_criado', NULL, 'Novo registro criado', auth.uid());
    
  ELSIF TG_OP = 'UPDATE' THEN
    -- Comparar cada campo e registrar mudanças
    IF OLD.colaborador_id IS DISTINCT FROM NEW.colaborador_id THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'colaborador_id', OLD.colaborador_id::text, NEW.colaborador_id::text, auth.uid());
    END IF;
    
    IF OLD.unidade_id IS DISTINCT FROM NEW.unidade_id THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'unidade_id', OLD.unidade_id::text, NEW.unidade_id::text, auth.uid());
    END IF;
    
    IF OLD.posto_id IS DISTINCT FROM NEW.posto_id THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'posto_id', OLD.posto_id::text, NEW.posto_id::text, auth.uid());
    END IF;
    
    IF OLD.data_inicio IS DISTINCT FROM NEW.data_inicio THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'data_inicio', OLD.data_inicio::text, NEW.data_inicio::text, auth.uid());
    END IF;
    
    IF OLD.data_fim IS DISTINCT FROM NEW.data_fim THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'data_fim', OLD.data_fim::text, NEW.data_fim::text, auth.uid());
    END IF;
    
    IF OLD.motivo IS DISTINCT FROM NEW.motivo THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'motivo', OLD.motivo, NEW.motivo, auth.uid());
    END IF;
    
    IF OLD.status IS DISTINCT FROM NEW.status THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'status', OLD.status::text, NEW.status::text, auth.uid());
    END IF;
    
    IF OLD.observacoes IS DISTINCT FROM NEW.observacoes THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'observacoes', OLD.observacoes, NEW.observacoes, auth.uid());
    END IF;
    
    IF OLD.aprovado_por IS DISTINCT FROM NEW.aprovado_por THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'aprovado_por', OLD.aprovado_por::text, NEW.aprovado_por::text, auth.uid());
    END IF;
    
    IF OLD.data_aprovacao IS DISTINCT FROM NEW.data_aprovacao THEN
      INSERT INTO public.diarias_temporarias_logs (diaria_temporaria_id, campo_alterado, valor_anterior, valor_novo, usuario_id)
      VALUES (NEW.id, 'data_aprovacao', OLD.data_aprovacao::text, NEW.data_aprovacao::text, auth.uid());
    END IF;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Recriar o trigger SEM disparar em DELETE (DELETE é tratado pelo trg_diarias_temporarias_audit)
CREATE TRIGGER trigger_log_diaria_temporaria_changes
  AFTER INSERT OR UPDATE ON public.diarias_temporarias
  FOR EACH ROW
  EXECUTE FUNCTION public.log_diaria_temporaria_changes();
