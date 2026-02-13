
-- Migração 1: Adicionar novos valores ao enum internal_access_level
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
    WHERE t.typname = 'internal_access_level' AND e.enumlabel = 'assistente_operacoes'
  ) THEN
    ALTER TYPE public.internal_access_level ADD VALUE 'assistente_operacoes';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
    WHERE t.typname = 'internal_access_level' AND e.enumlabel = 'assistente_financeiro'
  ) THEN
    ALTER TYPE public.internal_access_level ADD VALUE 'assistente_financeiro';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
    WHERE t.typname = 'internal_access_level' AND e.enumlabel = 'gestor_financeiro'
  ) THEN
    ALTER TYPE public.internal_access_level ADD VALUE 'gestor_financeiro';
  END IF;
END $$;
