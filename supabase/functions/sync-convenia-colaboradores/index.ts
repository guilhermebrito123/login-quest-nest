import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Interface atualizada conforme nova resposta da API Convenia
interface ConveniaEmployee {
  id: string;
  name: string;
  last_name: string;
  email?: string;
  status?: string;
  hiring_date?: string;
  salary?: number;
  birth_date?: string;
  social_name?: string;
  registration?: string;
  document?: {
    pis?: string;
    cpf?: string;
  };
  address?: {
    id?: string;
    zip_code?: string;
    address?: string;
    number?: string;
    complement?: string;
    district?: string;
    state?: string;
    city?: string;
  };
  department?: {
    id?: string;
    name?: string;
  };
  team?: {
    id?: string;
    name?: string;
  };
  cost_center?: {
    id?: string;
    name?: string;
  };
  supervisor?: {
    id?: string;
    name?: string;
    last_name?: string;
  };
  job?: {
    id?: string;
    name?: string;
  };
  bank_accounts?: Array<{
    id?: string;
    bank?: string;
    account_type?: string;
    account?: string;
    agency?: string;
    digit?: string;
    pix?: string;
    modality?: string;
  }>;
  contact_information?: {
    id?: number;
    residential_phone?: string;
    personal_phone?: string;
    personal_email?: string;
  };
  cpf?: {
    id?: string;
    cpf?: string;
  };
}

interface ConveniaCostCenter {
  id: string;
  name: string;
}

interface ConveniaListResponse {
  message?: string;
  current_page?: number;
  data: ConveniaEmployee[];
  first_page_url?: string;
  from?: number;
  last_page?: number;
  total?: number;
  success?: boolean;
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

    // PASSO 1: Sincronizar cost centers do Convenia e criar clientes automaticamente
    console.log("Sincronizando cost centers do Convenia...");
    
    const conveniaCostCenters = await fetchConveniaCostCenters(convenia_token);
    console.log(`Cost centers encontrados no Convenia: ${conveniaCostCenters.length}`);

    // Criar/atualizar clientes e mapear cost_center.id -> cliente.id
    const costCenterIdToClienteMap = new Map<string, number>();
    let clientesCreated = 0;
    
    for (const cc of conveniaCostCenters) {
      // Verificar se já existe cliente com esse convenia_cost_center_id
      const { data: existingCliente } = await supabaseAdmin
        .from("clientes")
        .select("id")
        .eq("convenia_cost_center_id", cc.id)
        .maybeSingle();

      let clienteId: number;

      if (existingCliente) {
        clienteId = existingCliente.id;
        console.log(`Cliente existente: ${cc.name} -> id ${clienteId}`);
      } else {
        // Criar novo cliente com dados do cost center
        const { data: newCliente, error: insertError } = await supabaseAdmin
          .from("clientes")
          .insert({
            razao_social: cc.name,
            nome_fantasia: cc.name,
            cnpj: `00000000000${cc.id}`.slice(-14), // CNPJ placeholder único
            convenia_cost_center_id: cc.id,
          })
          .select("id")
          .single();

        if (insertError) {
          console.error(`Erro ao criar cliente ${cc.name}:`, insertError.message);
          continue;
        }
        
        clienteId = newCliente.id;
        clientesCreated++;
        console.log(`Novo cliente criado: ${cc.name} -> id ${clienteId}`);
      }

      costCenterIdToClienteMap.set(cc.id, clienteId);

      // Atualizar também a tabela cost_centers_convenia para referência
      await supabaseAdmin
        .from("cost_centers_convenia")
        .upsert(
          {
            convenia_cost_center_id: cc.id,
            convenia_cost_center_name: cc.name,
            cliente_id: clienteId,
          },
          { onConflict: "convenia_cost_center_id" }
        );
    }

    console.log(`Clientes mapeados: ${costCenterIdToClienteMap.size}, novos criados: ${clientesCreated}`);

    // PASSO 2: Buscar colaboradores do Convenia com paginação (usando novo formato)
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
      
      // Usar campos do novo formato de resposta
      if (data.last_page) {
        lastPage = data.last_page;
        console.log(`Página ${currentPage}/${lastPage} - Total: ${data.total || 'N/A'}`);
      }
      
      currentPage++;
    } while (currentPage <= lastPage);

    console.log(`Total de colaboradores encontrados: ${allEmployeesBasic.length}`);
    
    // PASSO 3: Buscar detalhes de cada colaborador para obter cost_center completo
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

    for (const employee of allEmployees) {
      // Montar nome completo usando name + last_name
      const nomeCompleto = `${employee.name} ${employee.last_name}`.trim();
      const normalizedNome = normalizeString(nomeCompleto);
      
      // CPF pode vir em document.cpf ou cpf.cpf (novo formato)
      const cpfFromDocument = cleanCpf(employee.document?.cpf);
      const cpfFromCpfObject = cleanCpf(employee.cpf?.cpf);
      const cpf = cpfFromDocument || cpfFromCpfObject;

      // Telefone pode vir de contact_information.personal_phone
      const telefone = formatPhone(employee.contact_information?.personal_phone) || 
                       formatPhone(employee.contact_information?.residential_phone);

      // Email pode ser o principal ou personal_email
      const email = employee.email || employee.contact_information?.personal_email || null;

      // Buscar cliente_id usando cost_center.id (já mapeado automaticamente)
      let clienteId: number | null = null;
      
      if (employee.cost_center?.id) {
        clienteId = costCenterIdToClienteMap.get(employee.cost_center.id) || null;
        
        if (!clienteId) {
          console.warn(
            `Cost center sem mapeamento: ${employee.cost_center.id} - ${employee.cost_center.name}`
          );
        }
      }
      
      // Mapear campos do Convenia para colaboradores
      const colaboradorData = {
        nome_completo: nomeCompleto,
        email: email,
        telefone: telefone,
        cargo: employee.job?.name || null,
        data_admissao: employee.hiring_date || null,
        status_colaborador: employee.status === "Ativo" ? "ativo" as const : "inativo" as const,
        cliente_id: clienteId,
      };

      const existing = nomeMap.get(normalizedNome);

      if (existing) {
        const updateData: any = {
          email: colaboradorData.email || existing.email,
          telefone: colaboradorData.telefone || existing.telefone,
          cargo: colaboradorData.cargo || existing.cargo,
          data_admissao: colaboradorData.data_admissao || existing.data_admissao,
          status_colaborador: colaboradorData.status_colaborador,
        };

        // Só atualiza cliente_id se encontrou mapeamento
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
        clientes_created: clientesCreated,
        clientes_mapped: costCenterIdToClienteMap.size,
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
