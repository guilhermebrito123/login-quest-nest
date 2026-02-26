
-- Drop the old overload with bigint parameter that uses old enum values
DROP FUNCTION IF EXISTS public.reverter_justificativa_falta_convenia(bigint, uuid, text);
