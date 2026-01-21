import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Interface completa conforme resposta da API Convenia
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
  intern?: Record<string, unknown>;
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
  annotations?: Array<Record<string, unknown>>;
  aso?: Array<Record<string, unknown>>;
  bank_accounts?: Array<Record<string, unknown>>;
  contact_information?: {
    id?: number;
    residential_phone?: string;
    personal_phone?: string;
    personal_email?: string;
  };
  disability?: Record<string, unknown>;
  foreign?: Record<string, unknown>;
  educations?: Array<Record<string, unknown>>;
  nationalities?: Array<Record<string, unknown>>;
  experience_period?: Record<string, unknown>;
  emergency_contacts?: Array<Record<string, unknown>>;
  cpf?: {
    id?: string;
    cpf?: string;
  };
  ctps?: {
    id?: string;
    serial_number?: string;
    number?: string;
    emission_date?: string;
    pis?: string;
    issuing_state_id?: number;
  };
  reservist?: Record<string, unknown>;
  rg?: {
    id?: string;
    number?: string;
    emission_date?: string;
    issuing_agency?: string;
    issuing_state_id?: number;
  };
  driver_license?: {
    id?: string;
    number?: string;
    emission_date?: string;
    validate_date?: string;
    category?: string;
  };
  electoral_card?: Record<string, unknown>;
  payroll?: Record<string, unknown>;
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

// Mapear colaborador para tabela colaboradores_convenia (incluindo raw_data)
function mapToColaboradoresConvenia(employee: ConveniaEmployee) {
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
    supervisor_id: employee.supervisor?.id || null,
    supervisor_name: employee.supervisor?.name || null,
    supervisor_last_name: employee.supervisor?.last_name || null,
    job_id: employee.job?.id || null,
    job_name: employee.job?.name || null,
    residential_phone: formatPhone(employee.contact_information?.residential_phone),
    personal_phone: formatPhone(employee.contact_information?.personal_phone),
    personal_email: employee.contact_information?.personal_email || null,
    // JSONB columns - passar objetos diretamente, não strings
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
    // JSONB columns - passar objetos diretamente
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
    raw_data: employee, // Armazena payload completo como JSONB
    synced_at: new Date().toISOString(),
  };
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

    // PASSO 0: Sincronizar centros de custo
    console.log("Sincronizando centros de custo do Convenia...");
    
    const costCentersResponse = await fetch(
      "https://public-api.convenia.com.br/api/v3/companies/cost-centers",
      {
        method: "GET",
        headers: {
          "token": convenia_token,
          "Content-Type": "application/json",
        },
      }
    );

    let costCentersSynced = 0;
    const costCentersErrors: string[] = [];

    if (costCentersResponse.ok) {
      const costCentersData = await costCentersResponse.json();
      const costCenters = costCentersData.data || [];
      
      console.log(`Encontrados ${costCenters.length} centros de custo`);
      
      for (const cc of costCenters) {
        const { error: upsertError } = await supabaseAdmin
          .from("cost_center")
          .upsert(
            { 
              convenia_id: cc.id, 
              name: cc.name 
            }, 
            { onConflict: "convenia_id" }
          );

        if (upsertError) {
          costCentersErrors.push(`Erro ${cc.name}: ${upsertError.message}`);
        } else {
          costCentersSynced++;
        }
      }
      console.log(`Centros de custo sincronizados: ${costCentersSynced}`);
    } else {
      console.error("Erro ao buscar centros de custo:", costCentersResponse.status);
    }

    // PASSO 1: Buscar colaboradores do Convenia com paginação
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
          JSON.stringify({ error: `Erro ao buscar do Convenia: ${response.status}`, details: errorText }),
          { status: response.status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const data: ConveniaListResponse = await response.json();
      allEmployeesBasic = [...allEmployeesBasic, ...data.data];
      
      if (data.last_page) {
        lastPage = data.last_page;
        console.log(`Página ${currentPage}/${lastPage} - Total: ${data.total || 'N/A'}`);
      }
      
      currentPage++;
    } while (currentPage <= lastPage);

    console.log(`Total de colaboradores encontrados: ${allEmployeesBasic.length}`);
    
    // PASSO 2: Buscar detalhes e salvar em lotes de 10 para evitar timeout
    console.log("Buscando detalhes e salvando em lotes...");
    const allEmployees: ConveniaEmployee[] = [];
    let colaboradoresConveniaUpdated = 0;
    const colaboradoresConveniaErrors: string[] = [];
    const BATCH_SIZE = 10;
    
    for (let i = 0; i < allEmployeesBasic.length; i++) {
      const basicEmployee = allEmployeesBasic[i];
      const details = await fetchEmployeeDetails(basicEmployee.id, convenia_token);
      
      if (details) {
        allEmployees.push(details);
      } else {
        allEmployees.push(basicEmployee);
      }
      
      // Salvar em lotes de BATCH_SIZE ou quando for o último
      if (allEmployees.length % BATCH_SIZE === 0 || i === allEmployeesBasic.length - 1) {
        const startIdx = Math.floor((allEmployees.length - 1) / BATCH_SIZE) * BATCH_SIZE;
        const batch = allEmployees.slice(startIdx);
        
        for (const employee of batch) {
          const mappedData = mapToColaboradoresConvenia(employee);
          
          const { error: upsertError } = await supabaseAdmin
            .from("colaboradores_convenia")
            .upsert(mappedData, { onConflict: "convenia_id" });

          if (upsertError) {
            colaboradoresConveniaErrors.push(`Erro ${employee.name}: ${upsertError.message}`);
          } else {
            colaboradoresConveniaUpdated++;
          }
        }
        console.log(`Lote salvo: ${colaboradoresConveniaUpdated}/${allEmployeesBasic.length}`);
      }
      
      if ((i + 1) % 50 === 0) {
        console.log(`Progresso: ${i + 1}/${allEmployeesBasic.length}`);
      }
      
      await delay(100);
    }

    console.log(`Total sincronizado em colaboradores_convenia: ${colaboradoresConveniaUpdated}`);

    // PASSO 3: Sincronizar com tabela colaboradores (existente)
    console.log("Sincronizando com tabela colaboradores...");

    const { data: existingColaboradores, error: fetchError } = await supabaseAdmin
      .from("colaboradores")
      .select("id, cpf, nome_completo, email, telefone, cargo, data_admissao, cliente_id");

    if (fetchError) {
      console.error("Erro ao buscar colaboradores existentes:", fetchError);
    }

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
      const nomeCompleto = `${employee.name} ${employee.last_name}`.trim();
      const normalizedNome = normalizeString(nomeCompleto);
      
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

      const existing = nomeMap.get(normalizedNome);

      if (existing) {
        const updateData: any = {
          email: colaboradorData.email || existing.email,
          telefone: colaboradorData.telefone || existing.telefone,
          cargo: colaboradorData.cargo || existing.cargo,
          data_admissao: colaboradorData.data_admissao || existing.data_admissao,
          status_colaborador: colaboradorData.status_colaborador,
        };

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
        cost_centers: {
          synced: costCentersSynced,
          errors: costCentersErrors.length,
        },
        total_convenia: allEmployees.length,
        colaboradores_convenia: {
          synced: colaboradoresConveniaUpdated,
          errors: colaboradoresConveniaErrors.length,
        },
        colaboradores: {
          total_banco: existingColaboradores?.length || 0,
          inserted,
          updated,
          errors: errors.length,
        },
      },
      errors: errors.length > 0 || colaboradoresConveniaErrors.length > 0 || costCentersErrors.length > 0
        ? { colaboradores: errors, colaboradores_convenia: colaboradoresConveniaErrors, cost_centers: costCentersErrors } 
        : undefined,
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
