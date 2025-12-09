-- Create password_reset_tokens table
CREATE TABLE public.password_reset_tokens (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token_hash text NOT NULL,
  expires_at timestamp with time zone NOT NULL,
  used_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo')
);

-- Add index for faster lookups
CREATE INDEX idx_password_reset_tokens_profile_id ON public.password_reset_tokens(profile_id);
CREATE INDEX idx_password_reset_tokens_expires_at ON public.password_reset_tokens(expires_at);

-- Enable RLS
ALTER TABLE public.password_reset_tokens ENABLE ROW LEVEL SECURITY;

-- No RLS policies - this table should only be accessed by edge functions using service role
-- RLS is enabled but no policies means no access from client-side, only service role can access

-- Add comment for documentation
COMMENT ON TABLE public.password_reset_tokens IS 'Stores hashed password reset tokens with expiration';
COMMENT ON COLUMN public.password_reset_tokens.token_hash IS 'SHA-256 hash of the reset token - never store plain token';
COMMENT ON COLUMN public.password_reset_tokens.expires_at IS 'Token expiration time (1 hour after creation)';
COMMENT ON COLUMN public.password_reset_tokens.used_at IS 'Timestamp when token was used - null if unused';

-- Function to clean up expired tokens (run periodically)
CREATE OR REPLACE FUNCTION public.limpar_tokens_expirados()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.password_reset_tokens
  WHERE expires_at < now() OR used_at IS NOT NULL;
END;
$$;

-- Schedule cleanup daily at 05:00 Brazilian time (08:00 UTC)
SELECT cron.schedule(
  'limpar-tokens-expirados',
  '0 8 * * *',
  'SELECT public.limpar_tokens_expirados();'
);