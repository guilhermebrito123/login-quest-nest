-- Adicionar constraints UNIQUE para convenia_id (necessário para upsert funcionar corretamente)

-- Constraint para colaboradores_convenia
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'colaboradores_convenia_convenia_id_key'
  ) THEN
    ALTER TABLE colaboradores_convenia
    ADD CONSTRAINT colaboradores_convenia_convenia_id_key UNIQUE (convenia_id);
  END IF;
END $$;

-- Constraint para cost_center
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'cost_center_convenia_id_key'
  ) THEN
    ALTER TABLE cost_center
    ADD CONSTRAINT cost_center_convenia_id_key UNIQUE (convenia_id);
  END IF;
END $$;