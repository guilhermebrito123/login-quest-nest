import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Não autenticado" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

    // Cliente vinculado ao caller (para validar quem está chamando)
    const supabaseCaller = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: callerData, error: callerErr } = await supabaseCaller.auth.getUser();
    if (callerErr || !callerData.user) {
      return new Response(JSON.stringify({ error: "Sessão inválida" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const callerId = callerData.user.id;

    const body = await req.json();
    const { user_id, reason } = body ?? {};
    if (!user_id) {
      return new Response(JSON.stringify({ error: "user_id é obrigatório" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (user_id === callerId) {
      return new Response(
        JSON.stringify({ error: "Você não pode desativar a si mesmo" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Cliente admin (service role) — bypassa RLS
    const supabaseAdmin = createClient(supabaseUrl, serviceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // Verifica se quem chama é admin
    const { data: callerRole } = await supabaseAdmin
      .from("user_roles")
      .select("role")
      .eq("user_id", callerId)
      .maybeSingle();

    if (callerRole?.role !== "admin") {
      return new Response(
        JSON.stringify({ error: "Apenas administradores podem desativar usuários" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Marca como inativo no banco
    const { error: updateErr } = await supabaseAdmin
      .from("usuarios")
      .update({
        ativo: false,
        deactivated_at: new Date().toISOString(),
        deactivated_by: callerId,
        deactivation_reason: reason ?? null,
      })
      .eq("id", user_id);

    if (updateErr) {
      console.error("Erro ao marcar usuário inativo:", updateErr);
      return new Response(JSON.stringify({ error: updateErr.message }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Bane o login no Auth (~100 anos)
    const { error: banErr } = await supabaseAdmin.auth.admin.updateUserById(user_id, {
      ban_duration: "876000h",
    });
    if (banErr) {
      console.error("Erro ao banir usuário no Auth:", banErr);
    }

    // 3. Revoga sessões ativas
    const { error: signOutErr } = await supabaseAdmin.auth.admin.signOut(user_id);
    if (signOutErr) {
      console.error("Erro ao revogar sessões:", signOutErr);
    }

    return new Response(
      JSON.stringify({ success: true, message: "Usuário desativado com sucesso" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    console.error("Erro:", error);
    return new Response(JSON.stringify({ error: error?.message ?? "Erro interno" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
