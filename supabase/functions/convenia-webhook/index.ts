export const config = {
  auth: {
    verifyJwt: false,
  },
};

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-convenia-signature",
};

// Funções de limpeza com validação de tipo
function cleanCpf(cpf: unknown): string | null {
  if (typeof cpf !== 'string') return null;
  const cleaned = cpf.replace(/\D/g, '');
  return cleaned || null;
}

function formatPhone(phone: unknown): string | null {
  if (typeof phone !== 'string') return null;
  const cleaned = phone.replace(/\D/g, '');
  return cleaned || null;
}

function safeStringReplace(value: unknown, pattern: RegExp, replacement: string): string | null {
  if (typeof value !== 'string') return null;
  return value.replace(pattern, replacement) || null;
}

// Mapear colaborador para tabela colaboradores_convenia
function mapToColaboradoresConvenia(employee: Record<string, unknown>) {
  const document = employee.document as Record<string, unknown> | undefined;
  const cpfObj = employee.cpf as Record<string, unknown> | undefined;
  const address = employee.address as Record<string, unknown> | undefined;
  const department = employee.department as Record<string, unknown> | undefined;
  const team = employee.team as Record<string, unknown> | undefined;
  const costCenter = employee.cost_center as Record<string, unknown> | undefined;
  const supervisor = employee.supervisor as Record<string, unknown> | undefined;
  const job = employee.job as Record<string, unknown> | undefined;
  const contactInfo = employee.contact_information as Record<string, unknown> | undefined;
  const rg = employee.rg as Record<string, unknown> | undefined;
  const ctps = employee.ctps as Record<string, unknown> | undefined;
  const driverLicense = employee.driver_license as Record<string, unknown> | undefined;

  const cpfFromDocument = cleanCpf(document?.cpf);
  const cpfFromCpfObject = cleanCpf(cpfObj?.cpf);
  const pisFromDocument = safeStringReplace(document?.pis, /\D/g, '');
  const pisFromCtps = safeStringReplace(ctps?.pis, /\D/g, '');
  
  return {
    convenia_id: employee.id,
    name: employee.name || null,
    last_name: employee.last_name || null,
    email: employee.email || null,
    status: employee.status || null,
    hiring_date: employee.hiring_date || null,
    salary: employee.salary || null,
    birth_date: employee.birth_date || null,
    social_name: employee.social_name || null,
    registration: employee.registration || null,
    cpf: cpfFromDocument || cpfFromCpfObject || null,
    pis: pisFromDocument || pisFromCtps || null,
    address_zip_code: address?.zip_code || null,
    address_street: address?.address || null,
    address_number: address?.number || null,
    address_complement: address?.complement || null,
    address_district: address?.district || null,
    address_state: address?.state || null,
    address_city: address?.city || null,
    department_id: department?.id || null,
    department_name: department?.name || null,
    team_id: team?.id || null,
    team_name: team?.name || null,
    cost_center_id: costCenter?.id || null,
    cost_center_name: costCenter?.name || null,
    cost_center: costCenter || null,
    supervisor_id: supervisor?.id || null,
    supervisor_name: supervisor?.name || null,
    supervisor_last_name: supervisor?.last_name || null,
    job_id: job?.id || null,
    job_name: job?.name || null,
    residential_phone: formatPhone(contactInfo?.residential_phone),
    personal_phone: formatPhone(contactInfo?.personal_phone),
    personal_email: contactInfo?.personal_email || null,
    bank_accounts: employee.bank_accounts || null,
    rg_number: rg?.number || null,
    rg_emission_date: rg?.emission_date || null,
    rg_issuing_agency: rg?.issuing_agency || null,
    ctps_number: ctps?.number || null,
    ctps_serial_number: ctps?.serial_number || null,
    ctps_emission_date: ctps?.emission_date || null,
    driver_license_number: driverLicense?.number || null,
    driver_license_category: driverLicense?.category || null,
    driver_license_emission_date: driverLicense?.emission_date || null,
    driver_license_validate_date: driverLicense?.validate_date || null,
    intern_data: employee.intern || null,
    annotations: employee.annotations || null,
    aso: employee.aso || null,
    disability: employee.disability || null,
    foreign_data: employee.foreign || null,
    educations: employee.educations || null,
    nationalities: employee.nationalities || null,
    experience_period: employee.experience_period || null,
    emergency_contacts: employee.emergency_contacts || null,
    electoral_card: employee.electoral_card || null,
    reservist: employee.reservist || null,
    payroll: employee.payroll || null,
    raw_data: employee,
    synced_at: new Date().toISOString(),
  };
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  // Aceita apenas POST
  if (req.method !== "POST") {
    console.log(`Método não permitido: ${req.method}`);
    return new Response(
      JSON.stringify({ error: "Method not allowed" }), 
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // Inicializar Supabase para logs mesmo em caso de erro
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  let payload: Record<string, unknown> | null = null;
  let eventType: string | null = null;

  try {
    console.log("Webhook recebido");

    // Ler o payload do webhook
    payload = await req.json();
    console.log("Webhook payload:", JSON.stringify(payload, null, 2));

    /**
     * Payload esperado do Convenia:
     * {
     *   "type": "employee.created" | "employee.edited" | "employee.deleted",
     *   "employee": { "id": "UUID_DO_COLABORADOR" }
     * }
     */
    eventType = (payload?.type || payload?.event) as string | null;
    const employeePayload = payload?.employee as Record<string, unknown> | undefined;
    const dataPayload = payload?.data as Record<string, unknown> | undefined;
    const employeeId = employeePayload?.id || dataPayload?.id;

    if (!employeeId) {
      console.error("Employee ID não encontrado no payload");
      
      // Log de erro
      await logWebhook(supabase, "convenia", eventType, payload, "error", "Employee ID not found");
      
      return new Response(
        JSON.stringify({ error: "Employee ID not found in payload" }), 
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`Evento: ${eventType}, Employee ID: ${employeeId}`);

    // Buscar colaborador completo na API do Convenia
    const conveniaToken = Deno.env.get("CONVENIA_API_TOKEN");

    if (!conveniaToken) {
      console.error("CONVENIA_API_TOKEN não configurado");
      
      await logWebhook(supabase, "convenia", eventType, payload, "error", "API token not configured");
      
      return new Response(
        JSON.stringify({ error: "API token not configured" }), 
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const conveniaResponse = await fetch(
      `https://public-api.convenia.com.br/api/v3/employees/${employeeId}`,
      {
        method: "GET",
        headers: {
          "token": conveniaToken,
          "Authorization": `Bearer ${conveniaToken}`,
          "Content-Type": "application/json",
        },
      }
    );

    // ✅ Ajuste 1: Logar e retornar o erro real do Convenia
    const responseText = await conveniaResponse.text();

    if (!conveniaResponse.ok) {
      console.error("Convenia erro:", conveniaResponse.status, responseText);
      
      await logWebhook(supabase, "convenia", eventType, payload, "error", `Convenia API error: ${conveniaResponse.status}`);
      
      return new Response(
        JSON.stringify({ 
          error: "Convenia API error", 
          status: conveniaResponse.status, 
          body: responseText 
        }), 
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse JSON com tratamento de erro
    let employeeData: Record<string, unknown>;
    try {
      employeeData = JSON.parse(responseText);
    } catch {
      console.error("Convenia retornou não-JSON:", responseText);
      
      await logWebhook(supabase, "convenia", eventType, payload, "error", "Convenia returned non-JSON");
      
      return new Response(
        JSON.stringify({ error: "Convenia returned non-JSON", body: responseText }), 
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ✅ Ajuste 2: Validação defensiva segura para diferentes formatos de resposta
    const employee = 
      (employeeData?.data && typeof employeeData.data === "object" && (employeeData.data as Record<string, unknown>).id) 
        ? employeeData.data as Record<string, unknown>
        : (employeeData?.id ? employeeData : null);

    if (!employee) {
      console.error("Resposta inesperada do Convenia:", employeeData);
      
      await logWebhook(supabase, "convenia", eventType, payload, "error", "Unexpected Convenia response structure");
      
      return new Response(
        JSON.stringify({ 
          error: "Unexpected Convenia response", 
          received: employeeData 
        }), 
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    console.log(`Colaborador obtido: ${employee.name} ${employee.last_name}`);

    // Salvar / atualizar centro de custo se existir
    const costCenter = employee.cost_center as Record<string, unknown> | undefined;
    if (costCenter?.id) {
      const { error: ccError } = await supabase.from("cost_center").upsert(
        {
          convenia_id: costCenter.id,
          name: costCenter.name,
        },
        { onConflict: "convenia_id" }
      );

      if (ccError) {
        console.error("Erro ao upsert cost_center:", ccError.message);
      } else {
        console.log(`Centro de custo atualizado: ${costCenter.name}`);
      }
    }

    // Salvar / atualizar colaboradores_convenia com mapeamento completo
    const mappedData = mapToColaboradoresConvenia(employee);
    
    const { error: conveniaError } = await supabase
      .from("colaboradores_convenia")
      .upsert(mappedData, { onConflict: "convenia_id" });

    if (conveniaError) {
      console.error("Erro ao upsert colaboradores_convenia:", conveniaError.message);
      
      await logWebhook(supabase, "convenia", eventType, payload, "error", `DB error: ${conveniaError.message}`);
      
      return new Response(
        JSON.stringify({ error: "Failed to save to colaboradores_convenia", details: conveniaError.message }), 
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`colaboradores_convenia atualizado: ${employee.name} ${employee.last_name}`);

    // Sincronizar também com tabela colaboradores principal
    const nomeCompleto = `${employee.name || ''} ${employee.last_name || ''}`.trim();
    const cpfFromDocument = cleanCpf((employee.document as Record<string, unknown>)?.cpf);
    const cpfFromCpfObject = cleanCpf((employee.cpf as Record<string, unknown>)?.cpf);
    const cpf = cpfFromDocument || cpfFromCpfObject;
    const contactInfo = employee.contact_information as Record<string, unknown> | undefined;
    const telefone = formatPhone(contactInfo?.personal_phone) || 
                     formatPhone(contactInfo?.residential_phone);
    const email = employee.email || contactInfo?.personal_email || null;
    const job = employee.job as Record<string, unknown> | undefined;

    const colaboradorData = {
      nome_completo: nomeCompleto,
      email: email,
      telefone: telefone,
      cargo: job?.name || null,
      data_admissao: employee.hiring_date || null,
      status_colaborador: employee.status === "Ativo" ? "ativo" as const : "inativo" as const,
    };

    // Verificar se já existe pelo nome
    const { data: existingColab } = await supabase
      .from("colaboradores")
      .select("id, cpf, nome_completo")
      .ilike("nome_completo", `%${employee.name}%${employee.last_name}%`)
      .limit(1)
      .maybeSingle();

    if (existingColab) {
      // Atualizar colaborador existente
      const { error: updateError } = await supabase
        .from("colaboradores")
        .update({
          email: colaboradorData.email || undefined,
          telefone: colaboradorData.telefone || undefined,
          cargo: colaboradorData.cargo || undefined,
          data_admissao: colaboradorData.data_admissao || undefined,
          status_colaborador: colaboradorData.status_colaborador,
        })
        .eq("id", existingColab.id);

      if (updateError) {
        console.error("Erro ao atualizar colaboradores:", updateError.message);
      } else {
        console.log(`colaboradores atualizado: ${nomeCompleto}`);
      }
    } else {
      // Inserir novo colaborador
      const { error: insertError } = await supabase
        .from("colaboradores")
        .insert({ ...colaboradorData, cpf });

      if (insertError) {
        console.error("Erro ao inserir colaboradores:", insertError.message);
      } else {
        console.log(`colaboradores inserido: ${nomeCompleto}`);
      }
    }

    // Registrar log do webhook com sucesso
    await logWebhook(supabase, "convenia", eventType, payload, "success", null);

    // Responder OK para o Convenia
    console.log("Webhook processado com sucesso!");
    return new Response(
      JSON.stringify({ success: true, message: "Webhook processed successfully" }), 
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    console.error("Erro no processamento do webhook:", error);
    
    // Tentar registrar log de erro
    await logWebhook(supabase, "convenia", eventType, payload, "error", errorMessage);
    
    return new Response(
      JSON.stringify({ error: "Internal server error", details: errorMessage }), 
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

// Função auxiliar para registrar logs de webhook de forma resiliente
// deno-lint-ignore no-explicit-any
async function logWebhook(
  supabase: any,
  source: string,
  eventType: string | null,
  payload: Record<string, unknown> | null,
  status: string,
  errorMessage: string | null
) {
  try {
    await supabase.from("webhook_logs").insert({
      source,
      event_type: eventType,
      payload,
      processed_at: new Date().toISOString(),
      status,
      error_message: errorMessage,
    });
  } catch (logError) {
    console.warn("Falha ao registrar log do webhook:", logError);
    // Não falhar o webhook por causa de log
  }
}
