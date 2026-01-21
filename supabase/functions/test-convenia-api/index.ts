import "https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const convenia_token = Deno.env.get("CONVENIA_API_TOKEN");
    
    if (!convenia_token) {
      return new Response(
        JSON.stringify({ error: "Token da API do Convenia não configurado" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const results: any = {
      listagem: {},
      detalhes: {},
      costCentersEndpoint: {},
    };

    // 1. Buscar listagem básica
    console.log("1. Buscando listagem básica de colaboradores...");
    const listResponse = await fetch(
      `https://public-api.convenia.com.br/api/v3/employees?paginate=5`,
      {
        method: "GET",
        headers: {
          "token": convenia_token,
          "Content-Type": "application/json",
        },
      }
    );

    if (listResponse.ok) {
      const listData = await listResponse.json();
      const firstEmployee = listData.data?.[0];
      results.listagem = {
        status: "ok",
        total: listData.meta?.total,
        keys_primeiro_colaborador: firstEmployee ? Object.keys(firstEmployee) : [],
        primeiro_colaborador: firstEmployee,
      };
      console.log("Listagem OK:", JSON.stringify(results.listagem, null, 2));

      // 2. Buscar detalhes do primeiro colaborador
      if (firstEmployee?.id) {
        console.log(`2. Buscando detalhes do colaborador ${firstEmployee.id}...`);
        const detailResponse = await fetch(
          `https://public-api.convenia.com.br/api/v3/employees/${firstEmployee.id}`,
          {
            method: "GET",
            headers: {
              "token": convenia_token,
              "Content-Type": "application/json",
            },
          }
        );

        if (detailResponse.ok) {
          const detailData = await detailResponse.json();
          const employee = detailData.data || detailData;
          results.detalhes = {
            status: "ok",
            keys: Object.keys(employee),
            cost_center: employee.cost_center,
            department: employee.department,
            area: employee.area,
            sector: employee.sector,
            company: employee.company,
            business_unit: employee.business_unit,
            full_data: employee,
          };
          console.log("Detalhes OK:", JSON.stringify(results.detalhes, null, 2));
        } else {
          results.detalhes = { status: "error", code: detailResponse.status };
        }
      }
    } else {
      results.listagem = { status: "error", code: listResponse.status };
    }

    // 3. Tentar endpoint de cost centers
    console.log("3. Tentando endpoint de cost centers...");
    const ccResponse = await fetch(
      `https://public-api.convenia.com.br/api/v3/cost-centers`,
      {
        method: "GET",
        headers: {
          "token": convenia_token,
          "Content-Type": "application/json",
        },
      }
    );

    if (ccResponse.ok) {
      const ccData = await ccResponse.json();
      results.costCentersEndpoint = {
        status: "ok",
        total: ccData.meta?.total || ccData.data?.length || 0,
        data: ccData.data?.slice(0, 5), // Primeiros 5
      };
      console.log("Cost Centers OK:", JSON.stringify(results.costCentersEndpoint, null, 2));
    } else {
      const errorText = await ccResponse.text();
      results.costCentersEndpoint = { 
        status: "error", 
        code: ccResponse.status,
        message: errorText 
      };
      console.log("Cost Centers Error:", ccResponse.status);
    }

    return new Response(
      JSON.stringify(results, null, 2),
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
