
-- Update the trigger function to also track attachment field changes
CREATE OR REPLACE FUNCTION public.log_diarista_changes()
RETURNS TRIGGER AS $$
DECLARE
  campo TEXT;
  valor_antigo TEXT;
  valor_novo TEXT;
  campos_monitorados TEXT[] := ARRAY[
    'nome_completo', 'cpf', 'cep', 'endereco', 'cidade', 'telefone', 'email',
    'possui_antecedente', 'status', 'banco', 'agencia', 'tipo_conta', 
    'numero_conta', 'pix', 'pix_pertence_beneficiario', 'motivo_restricao',
    'anexo_cpf', 'anexo_comprovante_endereco', 'anexo_dados_bancarios', 'anexo_possui_antecedente'
  ];
BEGIN
  -- Validate motivo_alteracao is provided
  IF NEW.motivo_alteracao IS NULL OR TRIM(NEW.motivo_alteracao) = '' THEN
    RAISE EXCEPTION 'Atualização bloqueada: informe o motivo da alteração.';
  END IF;

  -- Log changes for each monitored field
  FOREACH campo IN ARRAY campos_monitorados LOOP
    EXECUTE format('SELECT ($1).%I::TEXT, ($2).%I::TEXT', campo, campo)
      INTO valor_antigo, valor_novo
      USING OLD, NEW;
    
    -- Only log if value actually changed
    IF valor_antigo IS DISTINCT FROM valor_novo THEN
      INSERT INTO public.diaristas_historico (
        diarista_id,
        campo_alterado,
        valor_anterior,
        valor_novo,
        motivo
      ) VALUES (
        NEW.id,
        campo,
        valor_antigo,
        valor_novo,
        NEW.motivo_alteracao
      );
    END IF;
  END LOOP;

  -- Reset motivo_alteracao after logging
  NEW.motivo_alteracao := NULL;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
