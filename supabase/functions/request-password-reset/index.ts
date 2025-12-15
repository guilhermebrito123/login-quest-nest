import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Resend } from "https://esm.sh/resend@2.0.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface RequestPasswordResetBody {
  email: string;
}

// Generate cryptographically secure token
function generateSecureToken(): string {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
}

// Hash token using SHA-256
async function hashToken(token: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(token);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(byte => byte.toString(16).padStart(2, '0')).join('');
}

serve(async (req: Request): Promise<Response> => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { email }: RequestPasswordResetBody = await req.json();

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email || !emailRegex.test(email)) {
      console.log("Invalid email format provided");
      // Return generic message even for invalid format
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: "Se este e-mail existir em nossa base, enviaremos instruções para redefinição de senha." 
        }),
        { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    // Create Supabase client with service role for database access
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Check if email exists in profiles (don't expose result to client)
    const { data: profile, error: profileError } = await supabase
      .from("usuarios")
      .select("id, full_name")
      .eq("email", email.toLowerCase().trim())
      .single();

    if (profileError || !profile) {
      console.log("Email not found in profiles - returning generic message");
      // Return same response to not expose email existence
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: "Se este e-mail existir em nossa base, enviaremos instruções para redefinição de senha." 
        }),
        { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    // Invalidate any existing tokens for this user
    await supabase
      .from("password_reset_tokens")
      .delete()
      .eq("profile_id", profile.id);

    // Generate secure token
    const token = generateSecureToken();
    const tokenHash = await hashToken(token);

    // Set expiration to 1 hour from now
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString();

    // Store hashed token in database
    const { error: insertError } = await supabase
      .from("password_reset_tokens")
      .insert({
        profile_id: profile.id,
        token_hash: tokenHash,
        expires_at: expiresAt,
      });

    if (insertError) {
      console.error("Error storing reset token:", insertError);
      throw new Error("Failed to create reset token");
    }

    // Build reset link using origin header or fallback
    const origin = req.headers.get("origin") || "https://jcsmwkkytigomvibwsnb.lovableproject.com";
    const resetLink = `${origin}/redefinir-senha?token=${token}`;

    // Send email via Resend
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    if (!resendApiKey) {
      console.error("RESEND_API_KEY not configured");
      throw new Error("Email service not configured");
    }

    const resend = new Resend(resendApiKey);

    const emailHtml = `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #dc2626; color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px; }
            .button { display: inline-block; background: #dc2626; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 20px; color: #6b7280; font-size: 14px; }
            .warning { background: #fef3c7; padding: 15px; border-left: 4px solid #f59e0b; margin: 20px 0; }
            .code { background: #e5e7eb; padding: 10px; font-family: monospace; font-size: 14px; word-break: break-all; border-radius: 4px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Redefinição de Senha 🔐</h1>
            </div>
            <div class="content">
              <h2>Olá${profile.full_name ? `, ${profile.full_name}` : ''}!</h2>
              <p>Recebemos uma solicitação para redefinir a senha da sua conta no Facilities Hub.</p>
              
              <p>Clique no botão abaixo para criar uma nova senha:</p>
              
              <a href="${resetLink}" class="button">Redefinir Senha</a>
              
              <p>Ou copie e cole o link abaixo no seu navegador:</p>
              <div class="code">${resetLink}</div>
              
              <div class="warning">
                <strong>⚠️ Importante:</strong> Este link expira em 1 hora e só pode ser usado uma vez.
              </div>
              
              <p>Se você não solicitou a redefinição de senha, ignore este e-mail. Sua conta permanecerá segura.</p>
              
              <p>Atenciosamente,<br><strong>Equipe Facilities Hub</strong></p>
            </div>
            <div class="footer">
              <p>Este é um e-mail automático, por favor não responda.</p>
            </div>
          </div>
        </body>
      </html>
    `;

    const { error: emailError } = await resend.emails.send({
      from: "Facilities Hub <onboarding@resend.dev>",
      to: [email],
      subject: "Redefinição de Senha - Facilities Hub",
      html: emailHtml,
    });

    if (emailError) {
      console.error("Error sending email:", emailError);
      // Delete the token since email failed
      await supabase
        .from("password_reset_tokens")
        .delete()
        .eq("profile_id", profile.id);
      throw new Error("Failed to send reset email");
    }

    console.log(`Password reset email sent to ${email}`);

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: "Se este e-mail existir em nossa base, enviaremos instruções para redefinição de senha." 
      }),
      { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );

  } catch (error: any) {
    console.error("Error in request-password-reset:", error);
    
    // Always return generic message to not expose internal errors
    return new Response(
      JSON.stringify({ 
        success: true, 
        message: "Se este e-mail existir em nossa base, enviaremos instruções para redefinição de senha." 
      }),
      { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  }
});
