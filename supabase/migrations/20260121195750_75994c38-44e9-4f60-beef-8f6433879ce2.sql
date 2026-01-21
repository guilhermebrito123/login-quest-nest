-- Criar tabela colaboradores_convenia para armazenar dados do Convenia
CREATE TABLE public.colaboradores_convenia (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  convenia_id text NOT NULL UNIQUE,
  
  -- Dados básicos
  name text,
  last_name text,
  email text,
  status text,
  hiring_date date,
  salary numeric(12,2),
  birth_date date,
  social_name text,
  registration text,
  
  -- Documento
  cpf text,
  pis text,
  
  -- Endereço (flattened)
  address_zip_code text,
  address_street text,
  address_number text,
  address_complement text,
  address_district text,
  address_state text,
  address_city text,
  
  -- Departamento
  department_id text,
  department_name text,
  
  -- Equipe
  team_id text,
  team_name text,
  
  -- Centro de custo
  cost_center_id text,
  cost_center_name text,
  
  -- Supervisor
  supervisor_id text,
  supervisor_name text,
  supervisor_last_name text,
  
  -- Cargo
  job_id text,
  job_name text,
  
  -- Dados de contato
  residential_phone text,
  personal_phone text,
  personal_email text,
  
  -- Dados bancários (JSONB para array)
  bank_accounts jsonb,
  
  -- Documentos
  rg_number text,
  rg_emission_date date,
  rg_issuing_agency text,
  ctps_number text,
  ctps_serial_number text,
  ctps_emission_date date,
  driver_license_number text,
  driver_license_category text,
  driver_license_validate_date date,
  
  -- Dados adicionais (JSONB para estruturas complexas)
  intern_data jsonb,
  annotations jsonb,
  aso jsonb,
  disability jsonb,
  foreign_data jsonb,
  educations jsonb,
  nationalities jsonb,
  experience_period jsonb,
  emergency_contacts jsonb,
  electoral_card jsonb,
  reservist jsonb,
  payroll jsonb,
  
  -- Metadados
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  synced_at timestamp with time zone DEFAULT now()
);

-- Índices
CREATE INDEX idx_colaboradores_convenia_status ON public.colaboradores_convenia(status);
CREATE INDEX idx_colaboradores_convenia_cpf ON public.colaboradores_convenia(cpf);
CREATE INDEX idx_colaboradores_convenia_cost_center_id ON public.colaboradores_convenia(cost_center_id);
CREATE INDEX idx_colaboradores_convenia_department_id ON public.colaboradores_convenia(department_id);

-- Habilitar RLS
ALTER TABLE public.colaboradores_convenia ENABLE ROW LEVEL SECURITY;

-- Políticas de acesso
CREATE POLICY "Usuarios autenticados podem ler colaboradores_convenia" 
ON public.colaboradores_convenia 
FOR SELECT 
USING (true);

CREATE POLICY "Usuarios autorizados podem gerenciar colaboradores_convenia" 
ON public.colaboradores_convenia 
FOR ALL 
USING (has_role(auth.uid(), 'admin'::internal_access_level) OR has_role(auth.uid(), 'gestor_operacoes'::internal_access_level));

-- Trigger para atualizar updated_at
CREATE TRIGGER update_colaboradores_convenia_updated_at
BEFORE UPDATE ON public.colaboradores_convenia
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Comentário na tabela
COMMENT ON TABLE public.colaboradores_convenia IS 'Tabela espelho dos colaboradores do Convenia, sincronizada via API';