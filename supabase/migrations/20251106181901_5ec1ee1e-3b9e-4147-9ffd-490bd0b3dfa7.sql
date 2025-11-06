-- Corrigir foreign key de atribuido_para_id para referenciar profiles
ALTER TABLE chamados 
DROP CONSTRAINT IF EXISTS chamados_atribuido_para_id_fkey;

ALTER TABLE chamados
ADD CONSTRAINT chamados_atribuido_para_id_fkey 
FOREIGN KEY (atribuido_para_id) 
REFERENCES profiles(id);

-- Adicionar foreign key entre chamados_comentarios e profiles se não existir
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'chamados_comentarios_usuario_id_fkey'
  ) THEN
    ALTER TABLE chamados_comentarios
    ADD CONSTRAINT chamados_comentarios_usuario_id_fkey 
    FOREIGN KEY (usuario_id) 
    REFERENCES profiles(id);
  END IF;
END $$;