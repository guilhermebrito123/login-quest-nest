import { supabaseAdmin, json, corsHeaders, randomToken, sha256, getClientIp } from "../_shared/recovery.ts";

const TOKEN_DURATION_MINUTES = 60;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  try {
    // Valida JWT do operador
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json({ error: "unauthorized" }, 401);

    const jwt = authHeader.replace("Bearer ", "");
    const { data: { user: operator }, error: authError } = await supabaseAdmin.auth.getUser(jwt);

    if (authError || !operator) return json({ error: "unauthorized" }, 401);

    // Valida que o operador é admin
    const { data: profile } = await supabaseAdmin
      .from("internal_profiles")
      .select("nivel_acesso")
      .eq("user_id", operator.id)
      .maybeSingle();

    if (!profile || profile.nivel_acesso !== "admin") {
      return json({ error: "forbidden" }, 403);
    }

    const { requestId, approve, rejectionReason } = await req.json();

    if (!requestId || typeof approve !== "boolean") {
      return json({ error: "invalid_request" }, 400);
    }

    // Carrega pedido
    const { data: requestRow, error: reqError } = await supabaseAdmin
      .from("account_recovery_requests")
      .select("id, user_id, requested_identifier, status")
      .eq("id", requestId)
      .maybeSingle();

    if (reqError || !requestRow) return json({ error: "not_found" }, 404);
    if (requestRow.status !== "pending") {
      return json({ error: "invalid_request_state" }, 400);
    }

    const now = new Date().toISOString();

    // REJEIÇÃO
    if (!approve) {
      await supabaseAdmin
        .from("account_recovery_requests")
        .update({
          status: "rejected",
          reviewed_at: now,
          reviewed_by: operator.id,
          rejection_reason: rejectionReason ?? null,
        })
        .eq("id", requestId);

      await supabaseAdmin.from("account_recovery_audit").insert({
        request_id: requestId,
        user_id: requestRow.user_id,
        actor_user_id: operator.id,
        action: "manual_recovery_rejected",
        metadata: { rejection_reason: rejectionReason ?? null },
      });

      // Notifica usuário se conhecido
      if (requestRow.user_id) {
        await supabaseAdmin.from("notificacoes").insert({
          user_id: requestRow.user_id,
          titulo: "Pedido de redefinição de senha rejeitado",
          mensagem: rejectionReason
            ? `Seu pedido foi rejeitado. Motivo: ${rejectionReason}`
            : "Seu pedido de redefinição de senha foi rejeitado pelo suporte.",
          tipo: "seguranca",
        });
      }

      return json({ ok: true, status: "rejected" });
    }

    // APROVAÇÃO
    if (!requestRow.user_id) {
      return json({ error: "request_has_no_known_user" }, 400);
    }

    // Gera token e sessão de 60min
    const token = randomToken(32);
    const tokenHash = await sha256(token);
    const expiresAt = new Date(Date.now() + TOKEN_DURATION_MINUTES * 60 * 1000).toISOString();

    const { error: sessionError } = await supabaseAdmin
      .from("account_recovery_sessions")
      .insert({
        request_id: requestRow.id,
        user_id: requestRow.user_id,
        token_hash: tokenHash,
        expires_at: expiresAt,
        ip: getClientIp(req),
        user_agent: req.headers.get("user-agent"),
      });

    if (sessionError) {
      console.error("Erro criando sessão:", sessionError);
      return json({ error: "failed_to_create_session" }, 500);
    }

    // Atualiza pedido
    await supabaseAdmin
      .from("account_recovery_requests")
      .update({
        status: "approved",
        reviewed_at: now,
        reviewed_by: operator.id,
      })
      .eq("id", requestId);

    // Auditoria
    await supabaseAdmin.from("account_recovery_audit").insert({
      request_id: requestId,
      user_id: requestRow.user_id,
      actor_user_id: operator.id,
      action: "manual_recovery_approved",
      metadata: { expires_at: expiresAt },
    });

    // Notifica o usuário com o link contendo o token
    await supabaseAdmin.from("notificacoes").insert({
      user_id: requestRow.user_id,
      titulo: "Pedido de redefinição aprovado",
      mensagem: `Seu pedido foi aprovado. Acesse o link para definir sua nova senha. Válido por ${TOKEN_DURATION_MINUTES} minutos.`,
      tipo: "seguranca",
      link: `/recuperar-acesso/${token}`,
    });

    // Retorna o token para o admin (para entregar ao usuário por canal seguro também)
    return json({
      ok: true,
      status: "approved",
      recovery_token: token,
      recovery_link: `/recuperar-acesso/${token}`,
      expires_in_minutes: TOKEN_DURATION_MINUTES,
    });
  } catch (error) {
    console.error("Erro em approve-manual-recovery:", error);
    return json({ error: "internal_error" }, 500);
  }
});
