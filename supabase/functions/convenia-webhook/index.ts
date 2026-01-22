import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-convenia-signature",
};

// Reutiliza as funções de limpeza do sync
function cleanCpf(cpf: string | undefined): string | null {
  if (!cpf) return null;
  return cpf.replace(/\D/g, '');
}

function formatPhone(phone: string | undefined): string | null {
  if (!phone) return null;
  const cleaned = phone.replace(/\D/g, '');
  return cleaned || null;
}

// Mapear colaborador para tabela colaboradores_convenia
function mapToColaboradoresConvenia(employee: any) {
  const cpfFromDocument = cleanCpf(employee.document?.cpf);
  const cpfFromCpfObject = cleanCpf(employee.cpf?.cpf);
  const pisFromDocument = employee.document?.pis?.replace(/\D/g, '') || null;
  
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
    pis: pisFromDocument || employee.ctps?.pis?.replace(/\D/g, '') || null,
    address_zip_code: employee.address?.zip_code || null,
    address_street: employee.address?.address || null,
    address_number: employee.address?.number || null,
    address_complement: employee.address?.complement || null,
    address_district: employee.address?.district || null,
    address_state: employee.address?.state || null,
    address_city: employee.address?.city || null,
    department_id: employee.department?.id || null,
    department_name: employee.department?.name || null,
    team_id: employee.team?.id || null,
    team_name: employee.team?.name || null,
    cost_center_id: employee.cost_center?.id || null,
    cost_center_name: employee.cost_center?.name || null,
    cost_center: employee.cost_center || null,
    supervisor_id: employee.supervisor?.id || null,
    supervisor_name: employee.supervisor?.name || null,
    supervisor_last_name: employee.supervisor?.last_name || null,
    job_id: employee.job?.id || null,
    job_name: employee.job?.name || null,
    residential_phone: formatPhone(employee.contact_information?.residential_phone),
    personal_phone: formatPhone(employee.contact_information?.personal_phone),
    personal_email: employee.contact_information?.personal_email || null,
    bank_accounts: employee.bank_accounts || null,
    rg_number: employee.rg?.number || null,
    rg_emission_date: employee.rg?.emission_date || null,
    rg_issuing_agency: employee.rg?.issuing_agency || null,
    ctps_number: employee.ctps?.number || null,
    ctps_serial_number: employee.ctps?.serial_number || null,
    ctps_emission_date: employee.ctps?.emission_date || null,
    driver_license_number: employee.driver_license?.number || null,
    driver_license_category: employee.driver_license?.category || null,
    driver_license_emission_date: employee.driver_license?.emission_date || null,
    driver_license_validate_date: employee.driver_license?.validate_date || null,
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

  try {
    console.log("Webhook recebido (sem validação de secret)");

    // Ler o payload do webhook
    const payload = await req.json();
    console.log("Webhook recebido:", JSON.stringify(payload, null, 2));

    /**
     * Payload esperado do Convenia:
     * {
     *   "type": "employee.created" | "employee.edited" | "employee.deleted",
     *   "employee": { "id": "UUID_DO_COLABORADOR" }
     * }
     */
    const eventType = payload?.type || payload?.event;
    const employeeId = payload?.employee?.id || payload?.data?.id;

    if (!employeeId) {
      console.error("Employee ID não encontrado no payload");
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
          "Content-Type": "application/json",
        },
      }
    );

    if (!conveniaResponse.ok) {
      const errorText = await conveniaResponse.text();
      console.error(`Erro ao buscar colaborador: ${conveniaResponse.status} - ${errorText}`);
      return new Response(
        JSON.stringify({ error: "Failed to fetch employee from Convenia", status: conveniaResponse.status }), 
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const employeeData = await conveniaResponse.json();
    const employee = employeeData.data || employeeData;
    console.log(`Colaborador obtido: ${employee.name} ${employee.last_name}`);

    // Conectar no banco Supabase
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // Salvar / atualizar centro de custo se existir
    const costCenter = employee.cost_center;
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
      return new Response(
        JSON.stringify({ error: "Failed to save to colaboradores_convenia", details: conveniaError.message }), 
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`colaboradores_convenia atualizado: ${employee.name} ${employee.last_name}`);

    // Sincronizar também com tabela colaboradores principal
    const nomeCompleto = `${employee.name} ${employee.last_name}`.trim();
    const cpfFromDocument = cleanCpf(employee.document?.cpf);
    const cpfFromCpfObject = cleanCpf(employee.cpf?.cpf);
    const cpf = cpfFromDocument || cpfFromCpfObject;
    const telefone = formatPhone(employee.contact_information?.personal_phone) || 
                     formatPhone(employee.contact_information?.residential_phone);
    const email = employee.email || employee.contact_information?.personal_email || null;

    const colaboradorData = {
      nome_completo: nomeCompleto,
      email: email,
      telefone: telefone,
      cargo: employee.job?.name || null,
      data_admissao: employee.hiring_date || null,
      status_colaborador: employee.status === "Ativo" ? "ativo" as const : "inativo" as const,
    };

    // Verificar se já existe pelo nome normalizado
    const normalizeString = (str: string): string => {
      return str.toLowerCase()
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "")
        .replace(/\s+/g, " ")
        .trim();
    };

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

    // Registrar log do webhook
    const { error: logError } = await supabase.from("webhook_logs").insert({
      source: "convenia",
      event_type: eventType,
      payload: payload,
      processed_at: new Date().toISOString(),
      status: "success",
    });

    if (logError) {
      console.warn("Erro ao registrar log do webhook:", logError.message);
    }

    // Responder OK para o Convenia
    console.log("Webhook processado com sucesso!");
    return new Response(
      JSON.stringify({ success: true, message: "Webhook processed successfully" }), 
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    console.error("Erro no processamento do webhook:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error", details: errorMessage }), 
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
