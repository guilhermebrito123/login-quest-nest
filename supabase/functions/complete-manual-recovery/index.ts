import { supabaseAdmin, json, corsHeaders, sha256, getClientIp } from "../_shared/recovery.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  try {
    const { token, newPassword } = await req.json();

    if (!token || typeof token !== "string") {
      return json({ error: "invalid_request" }, 400);
    }

    if (!newPassword || typeof newPassword !== "string" || newPassword.length < 6) {
      return json({ error: "weak_password", message: "A senha deve ter no mínimo 6 caracteres." }, 400);
    }

    if (newPassword.length > 72) {
      return json({ error: "password_too_long", message: "A senha deve ter no máximo 72 caracteres." }, 400);
    }

    const tokenHash = await sha256(token);

    // Localiza a sessão
    const { data: session, error: sessionError } = await supabaseAdmin
      .from("account_recovery_sessions")
      .select("id, request_id, user_id, expires_at, consumed_at")
      .eq("token_hash", tokenHash)
      .maybeSingle();

    if (sessionError || !session) {
      return json({ error: "invalid_token", message: "Link inválido ou expirado." }, 400);
    }

    if (session.consumed_at) {
      return json({ error: "token_consumed", message: "Este link já foi utilizado." }, 400);
    }

    if (new Date(session.expires_at) < new Date()) {
      // Marca pedido como expirado
      await supabaseAdmin
        .from("account_recovery_requests")
        .update({ status: "expired" })
        .eq("id", session.request_id)
        .eq("status", "approved");

      return json({ error: "token_expired", message: "O link expirou. Solicite um novo." }, 400);
    }

    // Troca senha via admin API
    const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(session.user_id, {
      password: newPassword,
    });

    if (updateError) {
      console.error("Erro ao atualizar senha:", updateError);
      return json({ error: "failed_to_update_password", message: updateError.message }, 500);
    }

    const now = new Date().toISOString();

    // Marca sessão como consumida
    await supabaseAdmin
      .from("account_recovery_sessions")
      .update({ consumed_at: now })
      .eq("id", session.id)
      .is("consumed_at", null);

    // Marca pedido como consumido
    await supabaseAdmin
      .from("account_recovery_requests")
      .update({ status: "consumed" })
      .eq("id", session.request_id);

    // Auditoria
    await supabaseAdmin.from("account_recovery_audit").insert({
      request_id: session.request_id,
      user_id: session.user_id,
      action: "password_reset_completed",
      metadata: { ip: getClientIp(req), method: "manual_support" },
    });

    // Notifica usuário
    await supabaseAdmin.from("notificacoes").insert({
      user_id: session.user_id,
      titulo: "Senha redefinida com sucesso",
      mensagem: "Sua senha foi alterada. Caso não tenha sido você, contate o suporte imediatamente.",
      tipo: "seguranca",
    });

    return json({ ok: true, message: "Senha redefinida com sucesso." });
  } catch (error) {
    console.error("Erro em complete-manual-recovery:", error);
    return json({ error: "internal_error" }, 500);
  }
});
