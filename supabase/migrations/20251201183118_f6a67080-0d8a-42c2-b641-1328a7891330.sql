-- Criar tabela diarias_temporarias
CREATE TABLE public.diarias_temporarias (
  id BIGSERIAL PRIMARY KEY,
  valor_diaria numeric NOT NULL,
  diarista_id uuid NOT NULL REFERENCES public.diaristas(id) ON DELETE RESTRICT,
  status status_diaria NOT NULL DEFAULT 'Aguardando confirmacao'::status_diaria,
  data_diaria date NOT NULL,
  posto_servico_id uuid NOT NULL REFERENCES public.postos_servico(id) ON DELETE RESTRICT,
  colaborador_ausente uuid REFERENCES public.colaboradores(id) ON DELETE SET NULL,
  motivo_cancelamento text,
  motivo_reprovacao text,
  created_at timestamptz NOT NULL DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo'),
  updated_at timestamptz NOT NULL DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo')
);

-- Habilitar RLS
ALTER TABLE public.diarias_temporarias ENABLE ROW LEVEL SECURITY;

-- Política de leitura para usuários autenticados
CREATE POLICY diarias_temporarias_select_policy
ON public.diarias_temporarias
FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Política de inserção para perfis autorizados
CREATE POLICY diarias_temporarias_insert_policy
ON public.diarias_temporarias
FOR INSERT
WITH CHECK (
  has_role(auth.uid(), 'admin'::app_role)
  OR has_role(auth.uid(), 'gestor_operacoes'::app_role)
  OR has_role(auth.uid(), 'supervisor'::app_role)
);

-- Política de atualização para perfis autorizados
CREATE POLICY diarias_temporarias_update_policy
ON public.diarias_temporarias
FOR UPDATE
USING (
  has_role(auth.uid(), 'admin'::app_role)
  OR has_role(auth.uid(), 'gestor_operacoes'::app_role)
  OR has_role(auth.uid(), 'supervisor'::app_role)
);

-- Política de deleção apenas para admins/gestores quando status for Cancelada
CREATE POLICY diarias_temporarias_delete_policy
ON public.diarias_temporarias
FOR DELETE
USING (
  (has_role(auth.uid(), 'admin'::app_role)
   OR has_role(auth.uid(), 'gestor_operacoes'::app_role))
  AND status = 'Cancelada'::status_diaria
);

-- Função para validar obrigatoriedade dos motivos conforme status
CREATE OR REPLACE FUNCTION public.validar_motivos_diaria_temporaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- Validar motivo_reprovacao quando status é Reprovada
  IF NEW.status = 'Reprovada'::status_diaria AND (NEW.motivo_reprovacao IS NULL OR TRIM(NEW.motivo_reprovacao) = '') THEN
    RAISE EXCEPTION 'O campo motivo_reprovacao é obrigatório quando o status é Reprovada';
  END IF;
  
  -- Validar motivo_cancelamento quando status é Cancelada
  IF NEW.status = 'Cancelada'::status_diaria AND (NEW.motivo_cancelamento IS NULL OR TRIM(NEW.motivo_cancelamento) = '') THEN
    RAISE EXCEPTION 'O campo motivo_cancelamento é obrigatório quando o status é Cancelada';
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Trigger para validar motivos na inserção/atualização
CREATE TRIGGER validar_motivos_diaria_temporaria_trg
BEFORE INSERT OR UPDATE ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.validar_motivos_diaria_temporaria();

-- Função para limpar motivos ao mudar de status
CREATE OR REPLACE FUNCTION public.limpar_motivos_diaria_temporaria()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- Se o status mudou de Cancelada para outro limpar motivo_cancelamento
  IF OLD.status = 'Cancelada'::status_diaria AND NEW.status != 'Cancelada'::status_diaria THEN
    NEW.motivo_cancelamento := NULL;
  END IF;
  
  -- Se o status mudou de Reprovada para outro limpar motivo_reprovacao
  IF OLD.status = 'Reprovada'::status_diaria AND NEW.status != 'Reprovada'::status_diaria THEN
    NEW.motivo_reprovacao := NULL;
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Trigger para limpar motivos nas atualizações de status
CREATE TRIGGER limpar_motivos_diaria_temporaria_trg
BEFORE UPDATE ON public.diarias_temporarias
FOR EACH ROW
EXECUTE FUNCTION public.limpar_motivos_diaria_temporaria();