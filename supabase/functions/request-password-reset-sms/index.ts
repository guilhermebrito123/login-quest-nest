import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface RequestPasswordResetSMSBody {
  phone: string;
}

// Generate 6-digit verification code
function generateVerificationCode(): string {
  const code = Math.floor(100000 + Math.random() * 900000);
  return code.toString();
}

// Hash code using SHA-256
async function hashCode(code: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(code);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(byte => byte.toString(16).padStart(2, '0')).join('');
}

// Normalize phone number to E.164 format (Brazilian)
function normalizePhoneNumber(phone: string): string {
  // Remove all non-digit characters
  let digits = phone.replace(/\D/g, '');
  
  // If starts with 0, remove it
  if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  
  // If doesn't start with 55 (Brazil), add it
  if (!digits.startsWith('55')) {
    digits = '55' + digits;
  }
  
  return '+' + digits;
}

// Validate Brazilian phone number
function isValidBrazilianPhone(phone: string): boolean {
  const digits = phone.replace(/\D/g, '');
  // Brazilian phones: 10-11 digits (without country code) or 12-13 with 55
  return digits.length >= 10 && digits.length <= 13;
}

serve(async (req: Request): Promise<Response> => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { phone }: RequestPasswordResetSMSBody = await req.json();

    // Validate phone format
    if (!phone || !isValidBrazilianPhone(phone)) {
      console.log("Invalid phone format provided");
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: "Se este telefone existir em nossa base, enviaremos um código de verificação." 
        }),
        { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    const normalizedPhone = normalizePhoneNumber(phone);
    console.log(`Processing SMS reset request for phone ending in: ...${normalizedPhone.slice(-4)}`);

    // Create Supabase client with service role for database access
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Search for profile by phone (try multiple formats)
    const phoneVariants = [
      phone,
      normalizedPhone,
      phone.replace(/\D/g, ''),
      normalizedPhone.replace('+', ''),
    ];

    let profile = null;
    
    for (const variant of phoneVariants) {
      const { data, error } = await supabase
        .from("profiles")
        .select("id, full_name, phone")
        .ilike("phone", `%${variant.slice(-9)}%`) // Match last 9 digits
        .single();
      
      if (data && !error) {
        profile = data;
        break;
      }
    }

    if (!profile) {
      console.log("Phone not found in profiles - returning generic message");
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: "Se este telefone existir em nossa base, enviaremos um código de verificação." 
        }),
        { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    // Invalidate any existing tokens for this user
    await supabase
      .from("password_reset_tokens")
      .delete()
      .eq("profile_id", profile.id);

    // Generate 6-digit code
    const code = generateVerificationCode();
    const codeHash = await hashCode(code);

    // Set expiration to 15 minutes from now (shorter for SMS)
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();

    // Store hashed code in database
    const { error: insertError } = await supabase
      .from("password_reset_tokens")
      .insert({
        profile_id: profile.id,
        token_hash: codeHash,
        expires_at: expiresAt,
      });

    if (insertError) {
      console.error("Error storing reset code:", insertError);
      throw new Error("Failed to create reset code");
    }

    // Send SMS via Textbelt (free tier - 1 SMS/day, US numbers only in free tier)
    // For production, consider upgrading or using another provider
    const smsMessage = `Facilities Hub: Seu codigo de recuperacao de senha e ${code}. Expira em 15 min.`;
    
    const textbeltResponse = await fetch("https://textbelt.com/text", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        phone: normalizedPhone,
        message: smsMessage,
        key: "textbelt", // Free tier key (1 SMS/day, includes "Sent via Textbelt")
      }),
    });

    const textbeltResult = await textbeltResponse.json();
    console.log("Textbelt response:", JSON.stringify(textbeltResult));

    if (!textbeltResult.success) {
      console.error("Error sending SMS via Textbelt:", textbeltResult.error);
      
      // For development/testing: log the code (REMOVE IN PRODUCTION)
      console.log(`[DEV ONLY] Verification code for ${normalizedPhone}: ${code}`);
      
      // Don't delete token - allow testing via logs
      // In production, you'd want to delete the token and throw error
      
      // Return success anyway to not expose issues
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: "Se este telefone existir em nossa base, enviaremos um código de verificação.",
          // For dev testing only - remove in production:
          _dev_note: "SMS gratuito do Textbelt tem limitações. Verifique os logs para o código.",
        }),
        { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    console.log(`Password reset SMS sent to phone ending in: ...${normalizedPhone.slice(-4)}`);

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: "Se este telefone existir em nossa base, enviaremos um código de verificação." 
      }),
      { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );

  } catch (error: any) {
    console.error("Error in request-password-reset-sms:", error);
    
    return new Response(
      JSON.stringify({ 
        success: true, 
        message: "Se este telefone existir em nossa base, enviaremos um código de verificação." 
      }),
      { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  }
});
