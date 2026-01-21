import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ConveniaEmployee {
  id: string;
  name: string;
  last_name: string;
  email?: string;
  hiring_date?: string;
  documents?: {
    cpf?: string;
  };
  job?: {
    id?: string;
    name?: string;
  };
  cost_center?: {
    id?: string;
    name?: string;
  };
  cellphone?: string;
}

interface ConveniaCostCenter {
  id: string;
  name: string;
}

interface ConveniaListResponse {
  data: ConveniaEmployee[];
  meta?: {
    current_page: number;
    last_page: number;
    total: number;
  };
}

function cleanCpf(cpf: string | undefined): string | null {
  if (!cpf) return null;
  return cpf.replace(/\D/g, '');
}

function formatPhone(phone: string | undefined): string | null {
  if (!phone) return null;
  const cleaned = phone.replace(/\D/g, '');
  return cleaned || null;
}

async function delay(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Buscar todos os cost centers do Convenia
async function fetchConveniaCostCenters(token: string): Promise<ConveniaCostCenter[]> {
  const response = await fetch(
    "https://public-api.convenia.com.br/api/v3/companies/cost-centers",
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
    console.error("Erro ao buscar cost centers:", response.status, errorText);
    throw new Error(`Erro ao buscar cost centers do Convenia: ${response.status}`);
  }

  const result = await response.json();
  return result.data as ConveniaCostCenter[];
}

// Buscar detalhes de um colaborador com retry e backoff
async function fetchEmployeeDetails(
  employeeId: string, 
  token: string,
  maxRetries: number = 3
): Promise<ConveniaEmployee | null> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const response = await fetch(
        `https://public-api.convenia.com.br/api/v3/employees/${employeeId}`,
        {
          method: "GET",
          headers: {
            "token": token,
            "Content-Type": "application/json",
          },
        }
      );

      if (response.status === 429) {
        const waitTime = Math.pow(2, attempt) * 1000;
        console.log(`Rate limited, aguardando ${waitTime}ms...`);
        await delay(waitTime);
        continue;
      }

      if (!response.ok) {
        return null;
      }

      const data = await response.json();
      return data.data || data;
    } catch (error) {
      if (attempt < maxRetries - 1) {
        await delay(1000);
      }
    }
  }
  return null;
}

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

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // PASSO 1: Sincronizar cost centers do Convenia
    console.log("Sincronizando cost centers do Convenia...");
    
    const conveniaCostCenters = await fetchConveniaCostCenters(convenia_token);
    console.log(`Cost centers encontrados no Convenia: ${conveniaCostCenters.length}`);

    for (const cc of conveniaCostCenters) {
      await supabaseAdmin
        .from("cost_centers_convenia")
        .upsert(
          {
            convenia_cost_center_id: cc.id,
            convenia_cost_center_name: cc.name,
          },
          { onConflict: "convenia_cost_center_id" }
        );
    }

    console.log("Cost centers sincronizados com sucesso!");

    // PASSO 2: Criar mapa cost_center.id -> cliente_id
    const { data: mappedCostCenters } = await supabaseAdmin
      .from("cost_centers_convenia")
      .select("convenia_cost_center_id, cliente_id");

    const costCenterIdToClienteMap = new Map<string, number>();
    mappedCostCenters?.forEach(cc => {
      if (cc.cliente_id) {
        costCenterIdToClienteMap.set(cc.convenia_cost_center_id, cc.cliente_id);
      }
    });

    console.log(`Cost centers mapeados para clientes: ${costCenterIdToClienteMap.size}`);

    // PASSO 3: Buscar colaboradores do Convenia com paginação
    console.log("Buscando lista de colaboradores do Convenia...");

    let allEmployeesBasic: ConveniaEmployee[] = [];
    let currentPage = 1;
    let lastPage = 1;

    do {
      const response = await fetch(
        `https://public-api.convenia.com.br/api/v3/employees?paginate=200&page=${currentPage}`,
        {
          method: "GET",
          headers: {
            "token": convenia_token,
            "Content-Type": "application/json",
          },
        }
      );

      if (!response.ok) {
        const errorText = await response.text();
        console.error("Erro ao buscar do Convenia:", response.status, errorText);
        return new Response(
          JSON.stringify({ error: `Erro ao buscar do Convenia: ${response.status}` }),
          { status: response.status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const data: ConveniaListResponse = await response.json();
      allEmployeesBasic = [...allEmployeesBasic, ...data.data];
      
      if (data.meta) {
        lastPage = data.meta.last_page;
        console.log(`Página ${currentPage}/${lastPage} - Total: ${data.meta.total}`);
      }
      
      currentPage++;
    } while (currentPage <= lastPage);

    console.log(`Total de colaboradores encontrados: ${allEmployeesBasic.length}`);
    
    // PASSO 4: Buscar detalhes de cada colaborador para obter cost_center
    console.log("Buscando detalhes de cada colaborador...");
    const allEmployees: ConveniaEmployee[] = [];
    
    for (let i = 0; i < allEmployeesBasic.length; i++) {
      const basicEmployee = allEmployeesBasic[i];
      const details = await fetchEmployeeDetails(basicEmployee.id, convenia_token);
      
      if (details) {
        allEmployees.push(details);
      } else {
        allEmployees.push(basicEmployee);
      }
      
      if ((i + 1) % 50 === 0) {
        console.log(`Progresso: ${i + 1}/${allEmployeesBasic.length}`);
      }
      
      await delay(100);
    }

    console.log(`Detalhes obtidos para ${allEmployees.length} colaboradores`);

    // Contar colaboradores com cost_center
    const withCostCenter = allEmployees.filter(e => e.cost_center?.id);
    console.log(`Colaboradores com cost_center: ${withCostCenter.length}`);

    // Buscar colaboradores existentes no banco
    const { data: existingColaboradores, error: fetchError } = await supabaseAdmin
      .from("colaboradores")
      .select("id, cpf, nome_completo, email, telefone, cargo, data_admissao, cliente_id");

    if (fetchError) {
      console.error("Erro ao buscar colaboradores existentes:", fetchError);
      return new Response(
        JSON.stringify({ error: "Erro ao buscar colaboradores existentes" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Criar mapa de nomes normalizados
    const normalizeString = (str: string): string => {
      return str.toLowerCase()
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "")
        .replace(/\s+/g, " ")
        .trim();
    };

    const nomeMap = new Map<string, any>();
    existingColaboradores?.forEach((colab) => {
      if (colab.nome_completo) {
        nomeMap.set(normalizeString(colab.nome_completo), colab);
      }
    });

    let updated = 0;
    let inserted = 0;
    const errors: string[] = [];
    const unmappedCostCenters: { id: string; name: string }[] = [];

    for (const employee of allEmployees) {
      const nomeCompleto = `${employee.name} ${employee.last_name}`.trim();
      const normalizedNome = normalizeString(nomeCompleto);
      const cpf = cleanCpf(employee.documents?.cpf);

      // PASSO 5: Buscar cliente_id usando cost_center.id
      let clienteId: number | null = null;
      
      if (employee.cost_center?.id) {
        clienteId = costCenterIdToClienteMap.get(employee.cost_center.id) || null;
        
        // PASSO 6: Logar cost centers não mapeados
        if (!clienteId) {
          console.warn(
            `Cost center sem cliente associado: ${employee.cost_center.id} - ${employee.cost_center.name}`
          );
          
          // Registrar para retorno
          if (!unmappedCostCenters.find(cc => cc.id === employee.cost_center!.id)) {
            unmappedCostCenters.push({
              id: employee.cost_center.id,
              name: employee.cost_center.name || "Nome não disponível",
            });
          }
        }
      }
      
      const colaboradorData = {
        nome_completo: nomeCompleto,
        email: employee.email || null,
        telefone: formatPhone(employee.cellphone),
        cargo: employee.job?.name || null,
        data_admissao: employee.hiring_date || null,
        status_colaborador: "ativo" as const,
        cliente_id: clienteId,
      };

      const existing = nomeMap.get(normalizedNome);

      if (existing) {
        const updateData: any = {
          email: colaboradorData.email || existing.email,
          telefone: colaboradorData.telefone || existing.telefone,
          cargo: colaboradorData.cargo || existing.cargo,
          data_admissao: colaboradorData.data_admissao || existing.data_admissao,
        };

        // PASSO 7: Só atualiza cliente_id se encontrou mapeamento
        if (clienteId !== null) {
          updateData.cliente_id = clienteId;
        }

        const { error: updateError } = await supabaseAdmin
          .from("colaboradores")
          .update(updateData)
          .eq("id", existing.id);

        if (updateError) {
          errors.push(`Erro ao atualizar ${nomeCompleto}: ${updateError.message}`);
        } else {
          updated++;
        }
      } else {
        const { error: insertError } = await supabaseAdmin
          .from("colaboradores")
          .insert({ ...colaboradorData, cpf });

        if (insertError) {
          errors.push(`Erro ao inserir ${nomeCompleto}: ${insertError.message}`);
        } else {
          inserted++;
        }
      }
    }

    const result = {
      success: true,
      message: "Sincronização concluída",
      summary: {
        total_convenia: allEmployees.length,
        total_banco: existingColaboradores?.length || 0,
        inserted,
        updated,
        errors: errors.length,
        cost_centers_convenia: conveniaCostCenters.length,
        cost_centers_mapped: costCenterIdToClienteMap.size,
        cost_centers_unmapped: unmappedCostCenters.length,
      },
      unmapped_cost_centers: unmappedCostCenters.length > 0 ? unmappedCostCenters : undefined,
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
