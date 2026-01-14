import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ConveniaEmployeeBasic {
  id: string;
  name: string;
  last_name: string;
  email: string;
  status: string;
  hiring_date: string;
  cpf?: string;
  job?: {
    name?: string;
  };
  contact_information?: {
    personal_phone?: string;
  };
}

interface ConveniaListResponse {
  data: ConveniaEmployeeBasic[];
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
  return phone.replace(/\D/g, '');
}

function normalizeString(str: string): string {
  return str.toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\s+/g, " ")
    .trim();
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

    console.log("Buscando colaboradores do Convenia...");

    // Buscar todos os colaboradores ativos do Convenia com paginação
    let allEmployees: ConveniaEmployeeBasic[] = [];
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
      allEmployees = [...allEmployees, ...data.data];
      
      if (data.meta) {
        lastPage = data.meta.last_page;
        console.log(`Página ${currentPage}/${lastPage} - Total: ${data.meta.total}`);
      }
      
      currentPage++;
    } while (currentPage <= lastPage);

    console.log(`Total de colaboradores encontrados no Convenia: ${allEmployees.length}`);

    // Buscar colaboradores existentes no banco
    const { data: existingColaboradores, error: fetchError } = await supabaseAdmin
      .from("colaboradores")
      .select("id, cpf, nome_completo, email, telefone, cargo, data_admissao");

    if (fetchError) {
      console.error("Erro ao buscar colaboradores existentes:", fetchError);
      return new Response(
        JSON.stringify({ error: "Erro ao buscar colaboradores existentes" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Criar mapa de nomes normalizados para comparação
    const nomeMap = new Map<string, any>();
    existingColaboradores?.forEach((colab) => {
      if (colab.nome_completo) {
        const normalizedName = normalizeString(colab.nome_completo);
        nomeMap.set(normalizedName, colab);
      }
    });

    let updated = 0;
    let inserted = 0;
    let skipped = 0;
    const errors: string[] = [];

    for (const employee of allEmployees) {
      const nomeCompleto = `${employee.name} ${employee.last_name}`.trim();
      const normalizedNomeConvenia = normalizeString(nomeCompleto);
      
      // O CPF pode vir diretamente na listagem ou não
      const cpf = cleanCpf(employee.cpf);
      
      const colaboradorData = {
        nome_completo: nomeCompleto,
        email: employee.email || null,
        telefone: formatPhone(employee.contact_information?.personal_phone),
        cargo: employee.job?.name || null,
        data_admissao: employee.hiring_date || null,
        status_colaborador: "ativo" as const,
      };

      // Tentar encontrar por nome normalizado
      const existing = nomeMap.get(normalizedNomeConvenia);

      if (existing) {
        // Atualizar colaborador existente
        const updateData: any = {
          email: colaboradorData.email || existing.email,
          telefone: colaboradorData.telefone || existing.telefone,
          cargo: colaboradorData.cargo || existing.cargo,
          data_admissao: colaboradorData.data_admissao || existing.data_admissao,
        };

        const { error: updateError } = await supabaseAdmin
          .from("colaboradores")
          .update(updateData)
          .eq("id", existing.id);

        if (updateError) {
          console.error(`Erro ao atualizar ${nomeCompleto}:`, updateError);
          errors.push(`Erro ao atualizar ${nomeCompleto}: ${updateError.message}`);
        } else {
          console.log(`Atualizado: ${nomeCompleto}`);
          updated++;
        }
      } else {
        // Para inserir, precisamos de CPF
        if (!cpf) {
          console.log(`Colaborador ${nomeCompleto} sem CPF e não existe no banco, pulando inserção...`);
          skipped++;
          continue;
        }

        // Inserir novo colaborador
        const { error: insertError } = await supabaseAdmin
          .from("colaboradores")
          .insert({
            ...colaboradorData,
            cpf: cpf,
          });

        if (insertError) {
          console.error(`Erro ao inserir ${nomeCompleto}:`, insertError);
          errors.push(`Erro ao inserir ${nomeCompleto}: ${insertError.message}`);
        } else {
          console.log(`Inserido: ${nomeCompleto}`);
          inserted++;
        }
      }
    }

    const result = {
      success: true,
      message: `Sincronização concluída`,
      summary: {
        total_convenia: allEmployees.length,
        total_banco: existingColaboradores?.length || 0,
        inserted,
        updated,
        skipped,
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
    const errorMessage = error instanceof Error ? error.message : "Erro desconhecido";
    return new Response(
      JSON.stringify({ error: `Erro interno: ${errorMessage}` }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
