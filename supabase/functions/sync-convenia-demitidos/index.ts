import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface DismissedEmployee {
  id: string;
  corporate_email?: string;
  dismissal?: {
    id?: string;
    date?: string;
    type?: { id?: number; title?: string };
    termination_notice?: {
      id?: string;
      date?: string;
      termination_notice_type_id?: number;
      termination_notice_type?: { id?: number; name?: string };
    };
    dismissal_step_id?: number;
    dismissal_step?: { id?: number; name?: string };
    breaking_contract?: string;
    remove_acess_date?: string;
    accountancy_date?: string;
    remove_benefit?: boolean;
    motive?: string | null;
    comments?: string | null;
    finished_at?: string;
    newSupervisorId?: string;
    supervisor?: { id?: string; name?: string };
  };
}

interface DismissedListResponse {
  current_page?: number;
  data: DismissedEmployee[];
  last_page?: number;
  total?: number;
  success?: boolean;
}

function mapToTable(emp: DismissedEmployee) {
  const d = emp.dismissal;
  return {
    convenia_employee_id: emp.id,
    corporate_email: emp.corporate_email || null,
    dismissal_id: d?.id || null,
    dismissal_date: d?.date || null,
    dismissal_type_id: d?.type?.id || null,
    dismissal_type_title: d?.type?.title || null,
    termination_notice_id: d?.termination_notice?.id || null,
    termination_notice_date: d?.termination_notice?.date || null,
    termination_notice_type_id: d?.termination_notice?.termination_notice_type_id || null,
    termination_notice_type_name: d?.termination_notice?.termination_notice_type?.name || null,
    dismissal_step_id: d?.dismissal_step_id || null,
    dismissal_step_name: d?.dismissal_step?.name || null,
    breaking_contract: d?.breaking_contract || null,
    remove_access_date: d?.remove_acess_date || null,
    accountancy_date: d?.accountancy_date || null,
    remove_benefit: d?.remove_benefit ?? null,
    motive: d?.motive || null,
    comments: d?.comments || null,
    finished_at: d?.finished_at || null,
    new_supervisor_id: d?.newSupervisorId || null,
    supervisor_id: d?.supervisor?.id || null,
    supervisor_name: d?.supervisor?.name || null,
    raw_data: emp,
    synced_at: new Date().toISOString(),
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const token = Deno.env.get("CONVENIA_DISMISSED_TOKEN");
    if (!token) {
      return new Response(
        JSON.stringify({ error: "Token CONVENIA_DISMISSED_TOKEN não configurado" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    console.log("Buscando colaboradores desligados do Convenia...");

    let allEmployees: DismissedEmployee[] = [];
    let currentPage = 1;
    let lastPage = 1;

    do {
      const response = await fetch(
        `https://public-api.convenia.com.br/api/v3/employees/dismissed?paginate=200&page=${currentPage}`,
        {
          method: "GET",
          headers: {
            "token": token,
            "Content-Type": "application/json",
          },
        }
      );

      if (!response.ok) {
        const errorText = await response.text();
        console.error("Erro ao buscar desligados:", response.status, errorText);
        return new Response(
          JSON.stringify({ error: `Erro API Convenia: ${response.status}`, details: errorText }),
          { status: response.status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const data: DismissedListResponse = await response.json();
      allEmployees = [...allEmployees, ...data.data];

      if (data.last_page) {
        lastPage = data.last_page;
        console.log(`Página ${currentPage}/${lastPage} - Total: ${data.total || "N/A"}`);
      }
      currentPage++;
    } while (currentPage <= lastPage);

    console.log(`Total de desligados encontrados: ${allEmployees.length}`);

    let synced = 0;
    const errors: string[] = [];

    for (const emp of allEmployees) {
      const mapped = mapToTable(emp);
      const { error: upsertError } = await supabaseAdmin
        .from("colaboradores_demitidos_convenia")
        .upsert(mapped, { onConflict: "convenia_employee_id" });

      if (upsertError) {
        errors.push(`Erro ${emp.id}: ${upsertError.message}`);
      } else {
        synced++;
      }
    }

    const result = {
      success: true,
      message: "Sincronização de desligados concluída",
      summary: {
        total_api: allEmployees.length,
        synced,
        errors: errors.length,
      },
      errors: errors.length > 0 ? errors : undefined,
    };

    console.log("Resultado:", JSON.stringify(result, null, 2));

    return new Response(
      JSON.stringify(result),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Erro:", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : "Erro desconhecido" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
