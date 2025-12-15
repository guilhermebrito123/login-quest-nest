import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ResetPasswordBody {
  token: string;
  newPassword: string;
}

// Hash token using SHA-256 (same as in request-password-reset)
async function hashToken(token: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(token);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(byte => byte.toString(16).padStart(2, '0')).join('');
}

// Validate password strength
function validatePassword(password: string): { valid: boolean; error?: string } {
  if (!password || password.length < 8) {
    return { valid: false, error: "A senha deve ter pelo menos 8 caracteres." };
  }
  if (password.length > 72) {
    return { valid: false, error: "A senha deve ter no máximo 72 caracteres." };
  }
  // Check for at least one letter and one number
  if (!/[a-zA-Z]/.test(password) || !/[0-9]/.test(password)) {
    return { valid: false, error: "A senha deve conter pelo menos uma letra e um número." };
  }
  return { valid: true };
}

serve(async (req: Request): Promise<Response> => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { token, newPassword }: ResetPasswordBody = await req.json();

    // Validate inputs
    if (!token || typeof token !== 'string') {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: "Token inválido ou não fornecido." 
        }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const passwordValidation = validatePassword(newPassword);
    if (!passwordValidation.valid) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: passwordValidation.error 
        }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    // Create Supabase client with service role for database access
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Hash the provided token
    const tokenHash = await hashToken(token);

    // Find the token in database
    const { data: resetToken, error: tokenError } = await supabase
      .from("password_reset_tokens")
      .select("id, profile_id, expires_at, used_at")
      .eq("token_hash", tokenHash)
      .single();

    if (tokenError || !resetToken) {
      console.log("Token not found in database");
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: "Token inválido ou expirado. Solicite um novo link de redefinição." 
        }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    // Check if token was already used
    if (resetToken.used_at) {
      console.log("Token already used");
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: "Este link já foi utilizado. Solicite um novo link de redefinição." 
        }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    // Check if token has expired
    const expiresAt = new Date(resetToken.expires_at);
    if (expiresAt < new Date()) {
      console.log("Token expired");
      // Mark as used to prevent future attempts
      await supabase
        .from("password_reset_tokens")
        .update({ used_at: new Date().toISOString() })
        .eq("id", resetToken.id);
        
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: "Este link expirou. Solicite um novo link de redefinição." 
        }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    // Get the profile to find the user
    const { data: profile, error: profileError } = await supabase
      .from("usuarios")
      .select("id, email")
      .eq("id", resetToken.profile_id)
      .single();

    if (profileError || !profile) {
      console.error("Profile not found:", profileError);
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: "Usuário não encontrado." 
        }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    // Get the auth user by email
    const { data: authUsers, error: authListError } = await supabase.auth.admin.listUsers();
    
    if (authListError) {
      console.error("Error listing users:", authListError);
      throw new Error("Failed to find user");
    }

    const authUser = authUsers.users.find(u => u.email?.toLowerCase() === profile.email.toLowerCase());
    
    if (!authUser) {
      console.error("Auth user not found for email:", profile.email);
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: "Usuário não encontrado no sistema de autenticação." 
        }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    // Update password using Supabase Auth Admin API
    // Supabase handles password hashing internally with bcrypt
    const { error: updateError } = await supabase.auth.admin.updateUserById(
      authUser.id,
      { password: newPassword }
    );

    if (updateError) {
      console.error("Error updating password:", updateError);
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: "Erro ao atualizar a senha. Tente novamente." 
        }),
        { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    // Mark token as used
    const { error: markUsedError } = await supabase
      .from("password_reset_tokens")
      .update({ used_at: new Date().toISOString() })
      .eq("id", resetToken.id);

    if (markUsedError) {
      console.error("Error marking token as used:", markUsedError);
      // Don't fail the request, password was already updated
    }

    console.log(`Password successfully reset for user ${profile.email}`);

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: "Senha redefinida com sucesso! Você já pode fazer login com sua nova senha." 
      }),
      { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );

  } catch (error: any) {
    console.error("Error in reset-password:", error);
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: "Erro interno. Tente novamente mais tarde." 
      }),
      { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  }
});
