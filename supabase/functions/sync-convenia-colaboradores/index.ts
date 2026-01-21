import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Interface completa conforme nova resposta da API Convenia
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
  intern?: {
    id?: string;
    initial_at?: string;
    finish_at?: string;
    internship_category?: string;
    is_mandatory?: string;
    occupation_area?: string;
    college?: string;
    cnpj?: string;
    zip_code?: string;
    address?: string;
    number?: string;
    complement?: string;
    district?: string;
    state?: string;
    city?: string;
    internship_supervisor?: {
      id?: string;
      name?: string;
      last_name?: string;
    };
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
  annotations?: Array<{
    id?: number;
    title?: string;
    notes?: string;
    date?: string;
  }>;
  aso?: Array<{
    id?: string;
    status?: boolean;
    exam_date?: string;
    observation?: string;
    aso_motive?: string;
  }>;
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
  disability?: {
    id?: number;
    observations?: string;
    disability_type?: string;
  };
  foreign?: {
    id?: number;
    arrival_date?: string;
    naturalization_date?: string;
    married_to_brazilian?: boolean;
    has_brazilian_offspring?: boolean;
    visa?: string;
    country?: string;
  };
  educations?: Array<{
    id?: string;
    course?: string;
    institution?: string;
    graduation_year?: number;
    education_type?: string;
  }>;
  nationalities?: Array<{
    id?: number;
    nationality?: string;
  }>;
  experience_period?: {
    id?: number;
    first_end?: string;
    second_end?: string;
    total_days?: string;
    experience_period_type?: string;
  };
  emergency_contacts?: Array<{
    id?: string;
    name?: string;
    phone?: string;
    email?: string;
    cellphone?: string;
    work_phone?: string;
    emergency_contact_relation?: string;
  }>;
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
  reservist?: {
    id?: string;
    reservist?: string;
    ra_number?: string;
    series?: string;
  };
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
  electoral_card?: {
    id?: string;
    number?: string;
    section?: string;
    electoral_ward?: string;
    state_id?: number;
    city_id?: number;
  };
  payroll?: {
    registration?: string;
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

// Mapear colaborador para tabela colaboradores_convenia
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
    bank_accounts: employee.bank_accounts ? JSON.stringify(employee.bank_accounts) : null,
    rg_number: employee.rg?.number || null,
    rg_emission_date: employee.rg?.emission_date || null,
    rg_issuing_agency: employee.rg?.issuing_agency || null,
    ctps_number: employee.ctps?.number || null,
    ctps_serial_number: employee.ctps?.serial_number || null,
    ctps_emission_date: employee.ctps?.emission_date || null,
    driver_license_number: employee.driver_license?.number || null,
    driver_license_category: employee.driver_license?.category || null,
    driver_license_validate_date: employee.driver_license?.validate_date || null,
    intern_data: employee.intern ? JSON.stringify(employee.intern) : null,
    annotations: employee.annotations ? JSON.stringify(employee.annotations) : null,
    aso: employee.aso ? JSON.stringify(employee.aso) : null,
    disability: employee.disability ? JSON.stringify(employee.disability) : null,
    foreign_data: employee.foreign ? JSON.stringify(employee.foreign) : null,
    educations: employee.educations ? JSON.stringify(employee.educations) : null,
    nationalities: employee.nationalities ? JSON.stringify(employee.nationalities) : null,
    experience_period: employee.experience_period ? JSON.stringify(employee.experience_period) : null,
    emergency_contacts: employee.emergency_contacts ? JSON.stringify(employee.emergency_contacts) : null,
    electoral_card: employee.electoral_card ? JSON.stringify(employee.electoral_card) : null,
    reservist: employee.reservist ? JSON.stringify(employee.reservist) : null,
    payroll: employee.payroll ? JSON.stringify(employee.payroll) : null,
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

    // PASSO 1: Sincronizar cost centers do Convenia
    console.log("Sincronizando cost centers do Convenia...");
    
    const conveniaCostCenters = await fetchConveniaCostCenters(convenia_token);
    console.log(`Cost centers encontrados no Convenia: ${conveniaCostCenters.length}`);

    // Sincronizar com tabela cost_center
    for (const cc of conveniaCostCenters) {
      await supabaseAdmin
        .from("cost_center")
        .upsert(
          { convenia_id: cc.id, name: cc.name },
          { onConflict: "convenia_id" }
        );
    }

    // Criar/atualizar clientes e mapear cost_center.id -> cliente.id
    const costCenterIdToClienteMap = new Map<string, number>();
    let clientesCreated = 0;
    
    for (const cc of conveniaCostCenters) {
      const { data: existingCliente } = await supabaseAdmin
        .from("clientes")
        .select("id")
        .eq("convenia_cost_center_id", cc.id)
        .maybeSingle();

      let clienteId: number;

      if (existingCliente) {
        clienteId = existingCliente.id;
      } else {
        const { data: newCliente, error: insertError } = await supabaseAdmin
          .from("clientes")
          .insert({
            razao_social: cc.name,
            nome_fantasia: cc.name,
            cnpj: `00000000000${cc.id}`.slice(-14),
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

    console.log(`Clientes mapeados: ${costCenterIdToClienteMap.size}, novos: ${clientesCreated}`);

    // PASSO 2: Buscar colaboradores do Convenia com paginação
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
      
      if (data.last_page) {
        lastPage = data.last_page;
        console.log(`Página ${currentPage}/${lastPage} - Total: ${data.total || 'N/A'}`);
      }
      
      currentPage++;
    } while (currentPage <= lastPage);

    console.log(`Total de colaboradores encontrados: ${allEmployeesBasic.length}`);
    
    // PASSO 3: Buscar detalhes de cada colaborador
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

    // PASSO 4: Sincronizar com tabela colaboradores_convenia
    console.log("Sincronizando com tabela colaboradores_convenia...");
    let colaboradoresConveniaInserted = 0;
    let colaboradoresConveniaUpdated = 0;
    const colaboradoresConveniaErrors: string[] = [];

    for (const employee of allEmployees) {
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

    console.log(`Colaboradores sincronizados em colaboradores_convenia: ${colaboradoresConveniaUpdated}`);

    // PASSO 5: Sincronizar com tabela colaboradores (existente)
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

      let clienteId: number | null = null;
      
      if (employee.cost_center?.id) {
        clienteId = costCenterIdToClienteMap.get(employee.cost_center.id) || null;
      }
      
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
        cost_centers: {
          total: conveniaCostCenters.length,
          clientes_created: clientesCreated,
          clientes_mapped: costCenterIdToClienteMap.size,
        },
      },
      errors: errors.length > 0 || colaboradoresConveniaErrors.length > 0 
        ? { colaboradores: errors, colaboradores_convenia: colaboradoresConveniaErrors } 
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
