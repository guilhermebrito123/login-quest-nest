import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface TiqueTaqueEmployee {
  id: string;
  name: string;
  cpf?: string;
  email?: string;
  phone?: string;
  allocation_unit?: string; // unidade de alocação
  admission_date?: string;
  position?: string;
  status?: string;
}

function cleanCpf(cpf: string | undefined): string | null {
  if (!cpf) return null;
  return cpf.replace(/\D/g, '');
}

function normalizeString(str: string): string {
  return str
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim();
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const tiqueTaqueToken = Deno.env.get('TIQUETAQUE_API_TOKEN');
    if (!tiqueTaqueToken) {
      throw new Error('TIQUETAQUE_API_TOKEN não configurado');
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 1. Buscar todos os funcionários do TiqueTaque
    console.log('Buscando funcionários do TiqueTaque...');
    
    // Tentar diferentes formatos de autenticação e endpoints
    const apiUrls = [
      'https://api.tiquetaque.com.br/v1/employees',
      'https://app.tiquetaque.com.br/api/v1/employees',
      'https://api.tiquetaque.com/v1/employees'
    ];
    
    const authFormats = [
      `Token ${tiqueTaqueToken}`,
      `Bearer ${tiqueTaqueToken}`,
      tiqueTaqueToken
    ];
    
    let tiqueTaqueResponse: Response | null = null;
    let lastError = '';
    let successUrl = '';
    
    outer:
    for (const apiUrl of apiUrls) {
      for (const authHeader of authFormats) {
        try {
          console.log(`Tentando URL: ${apiUrl} com auth: ${authHeader.substring(0, 15)}...`);
          const response = await fetch(apiUrl, {
            method: 'GET',
            headers: {
              'Authorization': authHeader,
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          });
          
          if (response.ok) {
            tiqueTaqueResponse = response;
            successUrl = apiUrl;
            console.log(`Sucesso com URL: ${apiUrl}, status: ${response.status}`);
            break outer;
          }
          
          const errorText = await response.text();
          lastError = `${apiUrl} (${authHeader.substring(0, 10)}...): ${response.status} - ${errorText.substring(0, 100)}`;
          console.log(`Tentativa falhou: ${lastError}`);
        } catch (err) {
          lastError = `${apiUrl}: ${err instanceof Error ? err.message : 'erro desconhecido'}`;
          console.log(`Erro de conexão: ${lastError}`);
        }
      }
    }
    
    if (!tiqueTaqueResponse) {
      throw new Error(`Não foi possível autenticar na API TiqueTaque. Verifique se o token está correto. Última tentativa: ${lastError}`);
    }

    if (!tiqueTaqueResponse.ok) {
      const errorText = await tiqueTaqueResponse.text();
      console.error('Erro ao buscar do TiqueTaque:', errorText);
      throw new Error(`Erro ao buscar funcionários do TiqueTaque: ${tiqueTaqueResponse.status} - ${errorText}`);
    }

    const tiqueTaqueData = await tiqueTaqueResponse.json();
    const tiqueTaqueEmployees: TiqueTaqueEmployee[] = tiqueTaqueData.data || tiqueTaqueData.employees || tiqueTaqueData || [];
    
    console.log(`Total de funcionários no TiqueTaque: ${tiqueTaqueEmployees.length}`);

    // 2. Buscar colaboradores existentes no banco
    const { data: existingColaboradores, error: colaboradoresError } = await supabase
      .from('colaboradores')
      .select('id, nome_completo, cpf, cliente_id');

    if (colaboradoresError) {
      throw new Error(`Erro ao buscar colaboradores: ${colaboradoresError.message}`);
    }

    console.log(`Total de colaboradores existentes: ${existingColaboradores?.length || 0}`);

    // 3. Buscar clientes para mapear unidade de alocação
    const { data: clientes, error: clientesError } = await supabase
      .from('clientes')
      .select('id, nome_fantasia');

    if (clientesError) {
      throw new Error(`Erro ao buscar clientes: ${clientesError.message}`);
    }

    // Criar mapa de nome_fantasia normalizado -> id
    const clienteMap = new Map<string, number>();
    for (const cliente of clientes || []) {
      if (cliente.nome_fantasia) {
        clienteMap.set(normalizeString(cliente.nome_fantasia), cliente.id);
      }
    }

    // Criar mapa de CPFs e nomes normalizados existentes
    const existingCpfs = new Set<string>();
    const existingNames = new Set<string>();
    
    for (const col of existingColaboradores || []) {
      if (col.cpf) {
        existingCpfs.add(cleanCpf(col.cpf) || '');
      }
      if (col.nome_completo) {
        existingNames.add(normalizeString(col.nome_completo));
      }
    }

    // 4. Identificar colaboradores faltantes
    const missingEmployees: TiqueTaqueEmployee[] = [];
    const toUpdateClienteId: { id: string; nome: string; unidade: string; clienteId: number }[] = [];

    for (const employee of tiqueTaqueEmployees) {
      const cpfLimpo = cleanCpf(employee.cpf);
      const nomeNormalizado = employee.name ? normalizeString(employee.name) : '';
      
      const existsByCpf = cpfLimpo && existingCpfs.has(cpfLimpo);
      const existsByName = nomeNormalizado && existingNames.has(nomeNormalizado);
      
      if (!existsByCpf && !existsByName) {
        missingEmployees.push(employee);
      }
      
      // Verificar mapeamento de unidade de alocação
      if (employee.allocation_unit) {
        const clienteId = clienteMap.get(normalizeString(employee.allocation_unit));
        if (clienteId) {
          toUpdateClienteId.push({
            id: employee.id,
            nome: employee.name,
            unidade: employee.allocation_unit,
            clienteId: clienteId
          });
        }
      }
    }

    // 5. Preparar relatório (sem inserir ainda - apenas análise)
    const report = {
      total_tiquetaque: tiqueTaqueEmployees.length,
      total_existentes: existingColaboradores?.length || 0,
      total_faltantes: missingEmployees.length,
      faltantes: missingEmployees.map(e => ({
        nome: e.name,
        cpf: e.cpf,
        unidade_alocacao: e.allocation_unit,
        cargo: e.position,
      })),
      mapeamento_clientes: toUpdateClienteId.length,
      clientes_disponiveis: clientes?.map(c => c.nome_fantasia) || [],
    };

    // Verificar se deve executar a inserção
    const url = new URL(req.url);
    const executeInsert = url.searchParams.get('execute') === 'true';

    if (executeInsert && missingEmployees.length > 0) {
      console.log(`Inserindo ${missingEmployees.length} colaboradores faltantes...`);
      
      const insertData = missingEmployees.map(emp => {
        const clienteId = emp.allocation_unit 
          ? clienteMap.get(normalizeString(emp.allocation_unit)) 
          : null;
          
        return {
          nome_completo: emp.name,
          cpf: cleanCpf(emp.cpf),
          email: emp.email || null,
          telefone: emp.phone || null,
          cargo: emp.position || null,
          data_admissao: emp.admission_date || null,
          status: 'ativo',
          cliente_id: clienteId || null,
        };
      });

      const { data: inserted, error: insertError } = await supabase
        .from('colaboradores')
        .insert(insertData)
        .select();

      if (insertError) {
        console.error('Erro ao inserir:', insertError);
        return new Response(JSON.stringify({
          success: false,
          error: insertError.message,
          report
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        });
      }

      return new Response(JSON.stringify({
        success: true,
        message: `${inserted?.length || 0} colaboradores inseridos com sucesso`,
        inserted: inserted?.length || 0,
        report
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Retornar apenas o relatório (modo análise)
    return new Response(JSON.stringify({
      success: true,
      mode: 'analise',
      message: 'Análise concluída. Use ?execute=true para inserir os faltantes.',
      report
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error('Erro:', error);
    return new Response(JSON.stringify({
      success: false,
      error: error instanceof Error ? error.message : 'Erro desconhecido'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
