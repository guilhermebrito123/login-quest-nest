
-- Tabela para armazenar colaboradores desligados do Convenia
CREATE TABLE public.colaboradores_demitidos_convenia (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  convenia_employee_id text NOT NULL,
  corporate_email text,
  dismissal_id text,
  dismissal_date date,
  dismissal_type_id integer,
  dismissal_type_title text,
  termination_notice_id text,
  termination_notice_date date,
  termination_notice_type_id integer,
  termination_notice_type_name text,
  dismissal_step_id integer,
  dismissal_step_name text,
  breaking_contract text,
  remove_access_date date,
  accountancy_date date,
  remove_benefit boolean,
  motive text,
  comments text,
  finished_at date,
  new_supervisor_id text,
  supervisor_id text,
  supervisor_name text,
  raw_data jsonb,
  synced_at timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT colaboradores_demitidos_convenia_convenia_employee_id_key UNIQUE (convenia_employee_id)
);

-- Enable RLS
ALTER TABLE public.colaboradores_demitidos_convenia ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Usuarios autenticados podem ler colaboradores_demitidos" 
ON public.colaboradores_demitidos_convenia 
FOR SELECT USING (true);

CREATE POLICY "Usuarios autorizados podem gerenciar colaboradores_demitidos" 
ON public.colaboradores_demitidos_convenia 
FOR ALL USING (
  has_role(auth.uid(), 'admin'::internal_access_level) 
  OR has_role(auth.uid(), 'gestor_operacoes'::internal_access_level)
);
