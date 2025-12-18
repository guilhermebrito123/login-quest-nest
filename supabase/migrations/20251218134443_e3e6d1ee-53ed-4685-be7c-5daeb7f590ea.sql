-- Ensure role transition trigger is installed on usuarios
DO $$
BEGIN
  -- Drop if already exists (idempotent)
  IF EXISTS (
    SELECT 1 FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'usuarios'
      AND t.tgname = 'handle_usuario_role_transition_trigger'
  ) THEN
    EXECUTE 'DROP TRIGGER handle_usuario_role_transition_trigger ON public.usuarios';
  END IF;
END $$;

CREATE TRIGGER handle_usuario_role_transition_trigger
AFTER UPDATE OF role ON public.usuarios
FOR EACH ROW
EXECUTE FUNCTION public.handle_usuario_role_transition();
