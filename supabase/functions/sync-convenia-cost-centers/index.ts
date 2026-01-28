import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface CostCenter {
  id: string;
  name: string;
}

interface CostCenterResponse {
  data: CostCenter[];
}

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  console.log("=== Iniciando sincronização de centros de custo ===");

  try {
    // Get API token - prefer specific token, fallback to general
    const costCenterToken = Deno.env.get("CONVENIA_COST_CENTER_TOKEN");
    const apiToken = Deno.env.get("CONVENIA_API_TOKEN");
    const token = costCenterToken || apiToken;

    if (!token) {
      console.error("Token de API não configurado");
      return new Response(
        JSON.stringify({
          success: false,
          error: "Token de API não configurado (CONVENIA_COST_CENTER_TOKEN ou CONVENIA_API_TOKEN)",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`Usando token: ${costCenterToken ? "CONVENIA_COST_CENTER_TOKEN" : "CONVENIA_API_TOKEN"}`);

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Fetch cost centers from Convenia API
    console.log("Buscando centros de custo da API Convenia...");
    
    const response = await fetch("https://public-api.convenia.com.br/api/v3/companies/cost-centers", {
      method: "GET",
      headers: {
        "token": token,
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`Erro na API Convenia: ${response.status} - ${errorText}`);
      return new Response(
        JSON.stringify({
          success: false,
          error: `Erro na API Convenia: ${response.status}`,
          details: errorText,
        }),
        {
          status: response.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const costCentersData: CostCenterResponse = await response.json();
    const costCenters = costCentersData.data || [];
    
    console.log(`Encontrados ${costCenters.length} centros de custo`);

    // Sync to database
    const errors: string[] = [];
    let synced = 0;

    for (const center of costCenters) {
      try {
        const { error: upsertError } = await supabase
          .from("cost_center")
          .upsert(
            {
              convenia_id: center.id,
              name: center.name,
            },
            { onConflict: "convenia_id" }
          );

        if (upsertError) {
          console.error(`Erro ao sincronizar centro ${center.id}: ${upsertError.message}`);
          errors.push(`Centro ${center.id} (${center.name}): ${upsertError.message}`);
        } else {
          synced++;
          console.log(`✓ Centro sincronizado: ${center.name} (${center.id})`);
        }
      } catch (err) {
        const errorMsg = err instanceof Error ? err.message : String(err);
        console.error(`Exceção ao sincronizar centro ${center.id}: ${errorMsg}`);
        errors.push(`Centro ${center.id}: ${errorMsg}`);
      }
    }

    console.log(`=== Sincronização concluída: ${synced}/${costCenters.length} ===`);

    return new Response(
      JSON.stringify({
        success: errors.length === 0,
        message: "Sincronização de centros de custo concluída",
        summary: {
          total_found: costCenters.length,
          synced: synced,
          errors: errors.length,
        },
        errors: errors.length > 0 ? errors : undefined,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(`Erro fatal: ${errorMessage}`);
    
    return new Response(
      JSON.stringify({
        success: false,
        error: "Erro interno na sincronização",
        details: errorMessage,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
