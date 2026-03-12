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
  documents?: {
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

function cleanCpf(cpf: string | number | undefined | null): string | null {
  if (cpf === null || cpf === undefined || cpf === '') return null;
  const str = String(cpf);
  const cleaned = str.replace(/\D/g, '');
  return cleaned || null;
}

function formatPhone(phone: string | number | undefined | null): string | null {
  if (phone === null || phone === undefined || phone === '') return null;
  const str = String(phone);
  const cleaned = str.replace(/\D/g, '');
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

// Extrair bank_accounts de forma segura
function extractBankAccounts(employee: ConveniaEmployee): Record<string, unknown>[] | null {
  const raw = employee.bank_accounts ?? (employee as any).bank_account ?? null;
  if (!raw) return null;
  const arr = Array.isArray(raw) ? raw : [raw];
  const filtered = arr.filter(Boolean);
  return filtered.length > 0 ? filtered : null;
}

// Extrair telefones sem sobrescrever com o mesmo valor
function extractPhones(employee: ConveniaEmployee): { personalPhone: string | null; residentialPhone: string | null } {
  const contactPersonal = formatPhone(employee.contact_information?.personal_phone);
  const contactResidential = formatPhone(employee.contact_information?.residential_phone);
  const cellphone = formatPhone((employee as any).cellphone);
  const phone = formatPhone((employee as any).phone);

  // Prioridade para personal: contact_information.personal_phone > cellphone > phone (somente se phone != residential)
  let personalPhone = contactPersonal || cellphone || null;
  let residentialPhone = contactResidential || null;

  // Se personal ainda null, usar phone somente se não já usado como residential
  if (!personalPhone && phone && phone !== residentialPhone) {
    personalPhone = phone;
  }
  // Se residential ainda null e phone disponível e diferente de personal
  if (!residentialPhone && phone && phone !== personalPhone) {
    residentialPhone = phone;
  }

  return { personalPhone, residentialPhone };
}

// Mapear colaborador para tabela colaboradores_convenia
function mapToColaboradoresConvenia(employee: ConveniaEmployee, costCenterMap: Map<string, string>) {
  const cpfFromDocument = cleanCpf(employee.document?.cpf) || cleanCpf(employee.documents?.cpf);
  const cpfFromCpfObject = cleanCpf(employee.cpf?.cpf);
  const pisFromDocument = cleanCpf(employee.document?.pis) || cleanCpf(employee.documents?.pis) || null;
  
  // Converter cost_center.id do Convenia para UUID interno
  const costCenterUuid = employee.cost_center?.id 
    ? costCenterMap.get(employee.cost_center.id) || null 
    : null;

  const { personalPhone, residentialPhone } = extractPhones(employee);
  const personalEmail = employee.contact_information?.personal_email 
    || (employee as any).alternative_email 
    || null;
  
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
    registration: employee.registration || (employee as any).payroll?.registration || null,
    cpf: cpfFromDocument || cpfFromCpfObject || null,
    pis: pisFromDocument || cleanCpf(employee.ctps?.pis) || null,
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
    cost_center_id: costCenterUuid,
    cost_center_name: employee.cost_center?.name || null,
    cost_center: employee.cost_center || null,
    supervisor_id: employee.supervisor?.id || null,
    supervisor_name: employee.supervisor?.name || null,
    supervisor_last_name: employee.supervisor?.last_name || null,
    job_id: employee.job?.id || null,
    job_name: employee.job?.name || null,
    residential_phone: residentialPhone,
    personal_phone: personalPhone,
    personal_email: personalEmail,
    bank_accounts: extractBankAccounts(employee),
    rg_number: employee.rg?.number || (employee.documents as any)?.rg || null,
    rg_emission_date: employee.rg?.emission_date || null,
    rg_issuing_agency: employee.rg?.issuing_agency || (employee.documents as any)?.rg_expedition || (employee.documents as any)?.rg_emission || null,
    ctps_number: employee.ctps?.number || (employee.documents as any)?.ctps || null,
    ctps_serial_number: employee.ctps?.serial_number || (employee.documents as any)?.ctps_serial || null,
    ctps_emission_date: employee.ctps?.emission_date || (employee.documents as any)?.ctps_emission_date || null,
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

// Campos críticos que indicam registro incompleto
const CRITICAL_FIELDS = ["cpf", "personal_phone", "pis", "rg_number", "job_name", "cost_center_id", "name"] as const;

function isRecordIncomplete(record: Record<string, any>): boolean {
  return CRITICAL_FIELDS.some(field => !record[field]);
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
    
    const costCenterToken = Deno.env.get("CONVENIA_COST_CENTER_TOKEN") || convenia_token;
    
    const costCentersResponse = await fetch(
      "https://public-api.convenia.com.br/api/v3/companies/cost-centers",
      {
        method: "GET",
        headers: {
          "token": costCenterToken,
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

    // Buscar mapa de cost_center (convenia_id -> uuid interno)
    const { data: costCenterRecords } = await supabaseAdmin
      .from("cost_center")
      .select("id, convenia_id");
    
    const costCenterMap = new Map<string, string>();
    (costCenterRecords || []).forEach((cc: { id: string; convenia_id: string }) => {
      costCenterMap.set(cc.convenia_id, cc.id);
    });
    console.log(`Mapa de cost centers carregado: ${costCenterMap.size} registros`);

    // PASSO 1: Buscar colaboradores ativos do Convenia com paginação
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
    
    // PASSO 2: Sincronizar colaboradores ativos da listagem
    console.log("Salvando colaboradores em lotes...");
    const allEmployees: ConveniaEmployee[] = allEmployeesBasic;
    let colaboradoresConveniaUpdated = 0;
    const colaboradoresConveniaErrors: string[] = [];
    const BATCH_SIZE = 20;
    
    for (let i = 0; i < allEmployees.length; i += BATCH_SIZE) {
      const batch = allEmployees.slice(i, i + BATCH_SIZE);
      
      for (const employee of batch) {
        const mappedData = mapToColaboradoresConvenia(employee, costCenterMap);
        
        const { error: upsertError } = await supabaseAdmin
          .from("colaboradores_convenia")
          .upsert(mappedData, { onConflict: "convenia_id" });

        if (upsertError) {
          colaboradoresConveniaErrors.push(`Erro ${employee.name}: ${upsertError.message}`);
        } else {
          colaboradoresConveniaUpdated++;
        }
      }
      console.log(`Lote salvo: ${Math.min(i + BATCH_SIZE, allEmployees.length)}/${allEmployees.length}`);
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

    // PASSO 4: Marcar colaboradores desligados em colaboradores_convenia
    // Usando cálculo em memória para evitar problemas com .not("convenia_id", "in", ...)
    console.log("Marcando colaboradores desligados em colaboradores_convenia...");
    
    const activeConveniaIds = new Set(allEmployees.map(e => e.id));
    
    // Buscar IDs de demitidos conhecidos
    const { data: demitidosConvenia } = await supabaseAdmin
      .from("colaboradores_demitidos_convenia")
      .select("convenia_employee_id");
    
    const demitidosIds = (demitidosConvenia || []).map((d: { convenia_employee_id: string }) => d.convenia_employee_id);
    const demitidosIdsSet = new Set(demitidosIds);
    
    let marcadosDesligados = 0;
    
    // Marcar demitidos conhecidos
    if (demitidosIds.length > 0) {
      // Processar em lotes de 100 para evitar limites do .in()
      for (let i = 0; i < demitidosIds.length; i += 100) {
        const batch = demitidosIds.slice(i, i + 100);
        const { data: updatedRows, error: updateDismissedError } = await supabaseAdmin
          .from("colaboradores_convenia")
          .update({ status: "Desligado", synced_at: new Date().toISOString() })
          .in("convenia_id", batch)
          .select("id");
        
        if (updateDismissedError) {
          console.error("Erro ao marcar desligados:", updateDismissedError.message);
        } else {
          marcadosDesligados += updatedRows?.length || 0;
        }
      }
      console.log(`Marcados como desligados (demitidos conhecidos): ${marcadosDesligados}`);
    }

    // Detectar órfãos em memória: buscar todos os convenia_id da tabela e calcular diferença
    console.log("Detectando registros órfãos...");
    const { data: allConveniaRecords } = await supabaseAdmin
      .from("colaboradores_convenia")
      .select("convenia_id")
      .neq("status", "Desligado");
    
    const orphanIds: string[] = [];
    for (const record of (allConveniaRecords || [])) {
      if (!activeConveniaIds.has(record.convenia_id) && !demitidosIdsSet.has(record.convenia_id)) {
        orphanIds.push(record.convenia_id);
      }
    }
    
    let orphanCount = 0;
    if (orphanIds.length > 0) {
      for (let i = 0; i < orphanIds.length; i += 100) {
        const batch = orphanIds.slice(i, i + 100);
        const { data: orphanRows, error: orphanError } = await supabaseAdmin
          .from("colaboradores_convenia")
          .update({ status: "Desligado", synced_at: new Date().toISOString() })
          .in("convenia_id", batch)
          .select("id");
        
        if (!orphanError && orphanRows) {
          orphanCount += orphanRows.length;
        }
      }
      marcadosDesligados += orphanCount;
      console.log(`Registros órfãos marcados como desligados: ${orphanCount}`);
    } else {
      console.log("Nenhum registro órfão encontrado.");
    }

    // PASSO 5: Buscar e inserir demitidos ausentes em colaboradores_convenia
    console.log("Verificando demitidos ausentes em colaboradores_convenia...");
    
    const { data: existingConveniaIds } = await supabaseAdmin
      .from("colaboradores_convenia")
      .select("convenia_id");
    
    const existingIdsSet = new Set((existingConveniaIds || []).map((r: { convenia_id: string }) => r.convenia_id));
    const missingDemitidosIds = demitidosIds.filter((id: string) => !existingIdsSet.has(id));
    
    console.log(`Demitidos ausentes em colaboradores_convenia: ${missingDemitidosIds.length}`);
    
    let demitidosInseridos = 0;
    const demitidosInsertErrors: string[] = [];
    
    if (missingDemitidosIds.length > 0) {
      for (const employeeId of missingDemitidosIds) {
        const details = await fetchEmployeeDetails(employeeId, convenia_token);
        
        if (details) {
          const mappedData = mapToColaboradoresConvenia(details, costCenterMap);
          mappedData.status = "Desligado";
          
          const { error: insertErr } = await supabaseAdmin
            .from("colaboradores_convenia")
            .upsert(mappedData, { onConflict: "convenia_id" });
          
          if (insertErr) {
            demitidosInsertErrors.push(`Erro ${details.name}: ${insertErr.message}`);
          } else {
            demitidosInseridos++;
          }
        } else {
          // API não retornou dados - inserir registro mínimo a partir dos dados de demissão
          const { data: demitidoData } = await supabaseAdmin
            .from("colaboradores_demitidos_convenia")
            .select("convenia_employee_id, corporate_email, raw_data")
            .eq("convenia_employee_id", employeeId)
            .single();
          
          if (demitidoData) {
            // Tentar extrair name/cpf do raw_data de demissão se disponível
            const rawDemitido = demitidoData.raw_data as Record<string, any> | null;
            const minimalData: Record<string, any> = {
              convenia_id: employeeId,
              email: demitidoData.corporate_email || null,
              status: "Desligado",
              synced_at: new Date().toISOString(),
              raw_data: demitidoData.raw_data,
            };
            // Extrair o que for possível do raw_data de demissão
            if (rawDemitido) {
              if (rawDemitido.name) minimalData.name = rawDemitido.name;
              if (rawDemitido.last_name) minimalData.last_name = rawDemitido.last_name;
              if (rawDemitido.corporate_email) minimalData.email = rawDemitido.corporate_email;
            }
            
            const { error: minInsertErr } = await supabaseAdmin
              .from("colaboradores_convenia")
              .upsert(minimalData, { onConflict: "convenia_id" });
            
            if (minInsertErr) {
              demitidosInsertErrors.push(`Erro minimal ${employeeId}: ${minInsertErr.message}`);
            } else {
              demitidosInseridos++;
            }
          }
        }
        
        await delay(200);
      }
      console.log(`Demitidos inseridos em colaboradores_convenia: ${demitidosInseridos}`);
    }

    // PASSO 6: Enriquecer ativos incompletos buscando detalhe na API
    console.log("Enriquecendo registros incompletos com endpoint de detalhe...");
    
    // Buscar registros com campos críticos faltando (qualquer um, não só cpf)
    const { data: incompleteActiveRecords } = await supabaseAdmin
      .from("colaboradores_convenia")
      .select("id, convenia_id, cpf, personal_phone, pis, rg_number, job_name, cost_center_id, name")
      .neq("status", "Desligado")
      .or("cpf.is.null,personal_phone.is.null,pis.is.null,rg_number.is.null,job_name.is.null,name.is.null");

    let enriched = 0;
    const enrichErrors: string[] = [];
    const MAX_ENRICH = 50; // Limitar para não estourar timeout
    
    const toEnrich = (incompleteActiveRecords || []).slice(0, MAX_ENRICH);
    console.log(`Registros ativos incompletos para enriquecer: ${incompleteActiveRecords?.length || 0} (processando ${toEnrich.length})`);
    
    for (const record of toEnrich) {
      const details = await fetchEmployeeDetails(record.convenia_id, convenia_token);
      if (details) {
        const mappedData = mapToColaboradoresConvenia(details, costCenterMap);
        // Preservar status atual (não sobrescrever com o do detalhe)
        delete (mappedData as any).status;
        // Atualizar raw_data com o payload completo do detalhe
        mappedData.raw_data = details;
        
        const { error: enrichErr } = await supabaseAdmin
          .from("colaboradores_convenia")
          .update(mappedData)
          .eq("id", record.id);
        
        if (enrichErr) {
          enrichErrors.push(`Enrich ${record.convenia_id}: ${enrichErr.message}`);
        } else {
          enriched++;
        }
      }
      await delay(200);
    }
    console.log(`Registros enriquecidos com detalhe: ${enriched}`);

    // PASSO 7: Reparar registros incompletos usando raw_data (filtro amplo)
    console.log("Reparando registros com dados incompletos a partir de raw_data...");
    
    const { data: incompleteRecords } = await supabaseAdmin
      .from("colaboradores_convenia")
      .select("id, convenia_id, cpf, personal_phone, rg_number, pis, job_name, cost_center_id, name, residential_phone, personal_email, rg_emission_date, rg_issuing_agency, ctps_number, ctps_serial_number, ctps_emission_date, driver_license_number, driver_license_category, raw_data")
      .not("raw_data", "is", null)
      .or("cpf.is.null,personal_phone.is.null,pis.is.null,rg_number.is.null,job_name.is.null,name.is.null");
    
    let reparados = 0;
    const repairErrors: string[] = [];
    
    for (const record of (incompleteRecords || [])) {
      if (!record.raw_data) continue;
      
      const rawEmployee = record.raw_data as ConveniaEmployee;
      const mappedData = mapToColaboradoresConvenia(rawEmployee, costCenterMap);
      
      // Só atualizar campos que estão nulos no registro atual
      const updates: Record<string, any> = {};
      const fieldsToRepair: Array<{ dbField: string; mappedField: string }> = [
        { dbField: "cpf", mappedField: "cpf" },
        { dbField: "personal_phone", mappedField: "personal_phone" },
        { dbField: "residential_phone", mappedField: "residential_phone" },
        { dbField: "personal_email", mappedField: "personal_email" },
        { dbField: "rg_number", mappedField: "rg_number" },
        { dbField: "rg_emission_date", mappedField: "rg_emission_date" },
        { dbField: "rg_issuing_agency", mappedField: "rg_issuing_agency" },
        { dbField: "pis", mappedField: "pis" },
        { dbField: "ctps_number", mappedField: "ctps_number" },
        { dbField: "ctps_serial_number", mappedField: "ctps_serial_number" },
        { dbField: "ctps_emission_date", mappedField: "ctps_emission_date" },
        { dbField: "driver_license_number", mappedField: "driver_license_number" },
        { dbField: "driver_license_category", mappedField: "driver_license_category" },
        { dbField: "job_name", mappedField: "job_name" },
        { dbField: "name", mappedField: "name" },
        { dbField: "cost_center_id", mappedField: "cost_center_id" },
      ];
      
      for (const { dbField, mappedField } of fieldsToRepair) {
        if (!record[dbField] && (mappedData as any)[mappedField]) {
          updates[dbField] = (mappedData as any)[mappedField];
        }
      }
      
      if (Object.keys(updates).length > 0) {
        updates.synced_at = new Date().toISOString();
        const { error: repairErr } = await supabaseAdmin
          .from("colaboradores_convenia")
          .update(updates)
          .eq("id", record.id);
        
        if (repairErr) {
          repairErrors.push(`Reparo ${record.convenia_id}: ${repairErr.message}`);
        } else {
          reparados++;
        }
      }
    }
    
    console.log(`Registros reparados: ${reparados}/${incompleteRecords?.length || 0}`);

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
          marcados_desligados: marcadosDesligados,
          orfaos_detectados: orphanCount,
          demitidos_inseridos: demitidosInseridos,
          demitidos_ausentes: missingDemitidosIds.length,
          enriquecidos: enriched,
          enriquecimento_candidatos: incompleteActiveRecords?.length || 0,
          reparados: reparados,
          reparos_total: incompleteRecords?.length || 0,
        },
        colaboradores: {
          total_banco: existingColaboradores?.length || 0,
          inserted,
          updated,
          errors: errors.length,
        },
      },
      errors: errors.length > 0 || colaboradoresConveniaErrors.length > 0 || costCentersErrors.length > 0 || demitidosInsertErrors.length > 0 || repairErrors.length > 0 || enrichErrors.length > 0
        ? { colaboradores: errors, colaboradores_convenia: colaboradoresConveniaErrors, cost_centers: costCentersErrors, demitidos_insert: demitidosInsertErrors, enriquecimento: enrichErrors, reparos: repairErrors } 
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
