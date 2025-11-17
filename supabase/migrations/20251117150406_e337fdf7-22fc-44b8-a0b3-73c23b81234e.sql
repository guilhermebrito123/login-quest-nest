-- Create enum with the correct periodicidade values
DO $$ BEGIN
  CREATE TYPE periodicidade_type AS ENUM ('pontual', 'diaria', 'semanal', 'mensal', 'anual');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Add periodicidade column to checklist if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'checklist' 
    AND column_name = 'periodicidade'
  ) THEN
    ALTER TABLE public.checklist 
      ADD COLUMN periodicidade periodicidade_type NOT NULL DEFAULT 'pontual';
  ELSE
    ALTER TABLE public.checklist 
      ALTER COLUMN periodicidade TYPE periodicidade_type 
      USING periodicidade::text::periodicidade_type;
  END IF;
END $$;

-- Add periodicidade column to checklist_item if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'checklist_item' 
    AND column_name = 'periodicidade'
  ) THEN
    ALTER TABLE public.checklist_item 
      ADD COLUMN periodicidade periodicidade_type NOT NULL DEFAULT 'pontual';
  ELSE
    ALTER TABLE public.checklist_item 
      ALTER COLUMN periodicidade TYPE periodicidade_type 
      USING periodicidade::text::periodicidade_type;
  END IF;
END $$;