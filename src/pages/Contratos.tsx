import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { DashboardLayout } from "@/components/DashboardLayout";
import { 
  Building2, 
  Plus, 
  Search, 
  ArrowLeft,
  FileText,
  AlertCircle,
  TrendingUp,
  Users
} from "lucide-react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { toast } from "@/hooks/use-toast";
import ClienteForm from "@/components/contratos/ClienteForm";
import ContratoForm from "@/components/contratos/ContratoForm";
import UnidadeForm from "@/components/contratos/UnidadeForm";
import PostoForm from "@/components/contratos/PostoForm";
import ClienteCard from "@/components/contratos/ClienteCard";
import ContratoCard from "@/components/contratos/ContratoCard";
import UnidadeCard from "@/components/contratos/UnidadeCard";
import PostoCard from "@/components/contratos/PostoCard";

interface Cliente {
  id: string;
  razao_social: string;
  cnpj: string;
  contato_nome: string | null;
  contato_email: string | null;
  contato_telefone: string | null;
  status: string;
}

interface Contrato {
  id: string;
  cliente_id: string;
  nome: string;
  codigo: string;
  data_inicio: string;
  data_fim: string | null;
  sla_alvo_pct: number;
  nps_meta: number | null;
  status: string;
}

interface Unidade {
  id: string;
  contrato_id: string;
  nome: string;
  codigo: string;
  endereco: string | null;
  cidade: string | null;
  uf: string | null;
  criticidade: string;
  status: string;
}

interface Posto {
  id: string;
  unidade_id: string;
  nome: string;
  codigo: string;
  funcao: string;
  status: string;
}

const Contratos = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [activeTab, setActiveTab] = useState("clientes");
  const [filterUnidadeId, setFilterUnidadeId] = useState<string>("all");
  const [filterOcupacao, setFilterOcupacao] = useState<string>("all");
  const [colaboradoresPorPosto, setColaboradoresPorPosto] = useState<Record<string, number>>({});
  
  // State for entities
  const [clientes, setClientes] = useState<Cliente[]>([]);
  const [contratos, setContratos] = useState<Contrato[]>([]);
  const [unidades, setUnidades] = useState<Unidade[]>([]);
  const [postos, setPostos] = useState<Posto[]>([]);
  
  // State for forms
  const [showClienteForm, setShowClienteForm] = useState(false);
  const [showContratoForm, setShowContratoForm] = useState(false);
  const [showUnidadeForm, setShowUnidadeForm] = useState(false);
  const [showPostoForm, setShowPostoForm] = useState(false);
  
  // State for editing entities
  const [editingClienteId, setEditingClienteId] = useState<string | undefined>(undefined);
  const [editingContratoId, setEditingContratoId] = useState<string | undefined>(undefined);
  const [editingUnidadeId, setEditingUnidadeId] = useState<string | undefined>(undefined);
  const [editingPostoId, setEditingPostoId] = useState<string | undefined>(undefined);
  
  // Selected entities for hierarchy
  const [selectedCliente, setSelectedCliente] = useState<string | null>(null);
  const [selectedContrato, setSelectedContrato] = useState<string | null>(null);
  const [selectedUnidade, setSelectedUnidade] = useState<string | null>(null);

  useEffect(() => {
    checkAuth();
    loadData();
  }, []);

  const checkAuth = async () => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      navigate("/auth");
    }
  };

  const loadData = async () => {
    setLoading(true);
    try {
      await Promise.all([
        loadClientes(),
        loadContratos(),
        loadUnidades(),
        loadPostos()
      ]);
    } catch (error) {
      console.error("Erro ao carregar dados:", error);
      toast({
        title: "Erro",
        description: "Erro ao carregar dados",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const loadClientes = async () => {
    const { data, error } = await supabase
      .from("clientes")
      .select("*")
      .order("razao_social");
    
    if (error) throw error;
    setClientes(data || []);
  };

  const loadContratos = async () => {
    const { data, error } = await supabase
      .from("contratos")
      .select("*")
      .order("nome");
    
    if (error) throw error;
    setContratos(data || []);
  };

  const loadUnidades = async () => {
    const { data, error } = await supabase
      .from("unidades")
      .select("*")
      .order("nome");
    
    if (error) throw error;
    setUnidades(data || []);
  };

  const loadPostos = async () => {
    const { data, error } = await supabase
      .from("postos_servico")
      .select("*")
      .order("nome");
    
    if (error) throw error;
    setPostos(data || []);
    
    // Load colaboradores count for each posto
    if (data) {
      const postoIds = data.map(p => p.id);
      const { data: colaboradoresData } = await supabase
        .from("colaboradores")
        .select("posto_servico_id")
        .in("posto_servico_id", postoIds);
      
      if (colaboradoresData) {
        const countMap: Record<string, number> = {};
        colaboradoresData.forEach(col => {
          if (col.posto_servico_id) {
            countMap[col.posto_servico_id] = (countMap[col.posto_servico_id] || 0) + 1;
          }
        });
        setColaboradoresPorPosto(countMap);
      }
    }
  };

  const filteredClientes = clientes.filter(c => 
    c.razao_social.toLowerCase().includes(searchTerm.toLowerCase()) ||
    c.cnpj.includes(searchTerm)
  );

  const filteredContratos = selectedCliente 
    ? contratos.filter(c => c.cliente_id === selectedCliente)
    : contratos.filter(c => 
        c.nome.toLowerCase().includes(searchTerm.toLowerCase()) ||
        c.codigo.toLowerCase().includes(searchTerm.toLowerCase())
      );

  const filteredUnidades = selectedContrato
    ? unidades.filter(u => u.contrato_id === selectedContrato)
    : unidades.filter(u => 
        u.nome.toLowerCase().includes(searchTerm.toLowerCase()) ||
        u.codigo.toLowerCase().includes(searchTerm.toLowerCase())
      );

  const filteredPostos = selectedUnidade
    ? postos.filter(p => {
        const matchesUnidade = p.unidade_id === selectedUnidade;
        const matchesSearch = p.nome.toLowerCase().includes(searchTerm.toLowerCase()) ||
          p.codigo.toLowerCase().includes(searchTerm.toLowerCase());
        
        if (filterOcupacao === "all") return matchesUnidade && matchesSearch;
        
        const totalColaboradores = colaboradoresPorPosto[p.id] || 0;
        const efetivoNecessario = (p as any).efetivo_planejado || 1;
        const isOcupado = totalColaboradores >= efetivoNecessario;
        const matchesOcupacao = filterOcupacao === "ocupado" ? isOcupado : !isOcupado;
        
        return matchesUnidade && matchesSearch && matchesOcupacao;
      })
    : postos.filter(p => {
        const matchesSearch = p.nome.toLowerCase().includes(searchTerm.toLowerCase()) ||
          p.codigo.toLowerCase().includes(searchTerm.toLowerCase());
        const matchesUnidade = filterUnidadeId === "all" || p.unidade_id === filterUnidadeId;
        
        if (filterOcupacao === "all") return matchesSearch && matchesUnidade;
        
        const totalColaboradores = colaboradoresPorPosto[p.id] || 0;
        const efetivoNecessario = (p as any).efetivo_planejado || 1;
        const isOcupado = totalColaboradores >= efetivoNecessario;
        const matchesOcupacao = filterOcupacao === "ocupado" ? isOcupado : !isOcupado;
        
        return matchesSearch && matchesUnidade && matchesOcupacao;
      });

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <DashboardLayout>
      <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b bg-card shadow-sm">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-gradient-to-br from-primary to-accent rounded-lg">
              <Building2 className="h-6 w-6 text-primary-foreground" />
            </div>
            <div>
              <h1 className="text-xl font-bold">Gestão de Contratos</h1>
              <p className="text-sm text-muted-foreground">
                Hierarquia: Cliente → Contrato → Unidade → Posto
              </p>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        {/* Metrics Dashboard */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <Card>
            <CardHeader className="pb-3">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Total Clientes
                </CardTitle>
                <Users className="h-4 w-4 text-primary" />
              </div>
              <p className="text-2xl font-bold">{clientes.length}</p>
            </CardHeader>
          </Card>
          <Card>
            <CardHeader className="pb-3">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  SLA Médio
                </CardTitle>
                <TrendingUp className="h-4 w-4 text-green-600" />
              </div>
              <p className="text-2xl font-bold text-green-600">0%</p>
            </CardHeader>
          </Card>
          <Card>
            <CardHeader className="pb-3">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  NPS Médio
                </CardTitle>
                <TrendingUp className="h-4 w-4 text-blue-600" />
              </div>
              <p className="text-2xl font-bold text-blue-600">0</p>
            </CardHeader>
          </Card>
          <Card>
            <CardHeader className="pb-3">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  OS Abertas
                </CardTitle>
                <FileText className="h-4 w-4 text-orange-600" />
              </div>
              <p className="text-2xl font-bold text-orange-600">0</p>
            </CardHeader>
          </Card>
        </div>

        {/* Breadcrumb Navigation */}
        {(selectedCliente || selectedContrato || selectedUnidade) && (
          <div className="mb-4 flex items-center gap-2 text-sm">
            <Button
              variant="link"
              size="sm"
              onClick={() => {
                setSelectedCliente(null);
                setSelectedContrato(null);
                setSelectedUnidade(null);
                setActiveTab("clientes");
              }}
            >
              Clientes
            </Button>
            {selectedCliente && (
              <>
                <span>/</span>
                <Button
                  variant="link"
                  size="sm"
                  onClick={() => {
                    setSelectedContrato(null);
                    setSelectedUnidade(null);
                    setActiveTab("contratos");
                  }}
                >
                  {clientes.find(c => c.id === selectedCliente)?.razao_social}
                </Button>
              </>
            )}
            {selectedContrato && (
              <>
                <span>/</span>
                <Button
                  variant="link"
                  size="sm"
                  onClick={() => {
                    setSelectedUnidade(null);
                    setActiveTab("unidades");
                  }}
                >
                  {contratos.find(c => c.id === selectedContrato)?.nome}
                </Button>
              </>
            )}
            {selectedUnidade && (
              <>
                <span>/</span>
                <span className="text-muted-foreground">
                  {unidades.find(u => u.id === selectedUnidade)?.nome}
                </span>
              </>
            )}
          </div>
        )}

        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="clientes">Clientes</TabsTrigger>
            <TabsTrigger value="contratos">Contratos</TabsTrigger>
            <TabsTrigger value="unidades">Unidades</TabsTrigger>
            <TabsTrigger value="postos">Postos</TabsTrigger>
          </TabsList>

          {/* Clientes Tab */}
          <TabsContent value="clientes" className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="relative flex-1 max-w-sm">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Buscar cliente..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10"
                />
              </div>
              <Button onClick={() => setShowClienteForm(true)}>
                <Plus className="h-4 w-4 mr-2" />
                Novo Cliente
              </Button>
            </div>

            {showClienteForm && (
              <ClienteForm
                clienteId={editingClienteId}
                onClose={() => {
                  setShowClienteForm(false);
                  setEditingClienteId(undefined);
                }}
                onSuccess={() => {
                  loadClientes();
                  setShowClienteForm(false);
                  setEditingClienteId(undefined);
                }}
              />
            )}

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {filteredClientes.map((cliente) => (
                <ClienteCard
                  key={cliente.id}
                  cliente={cliente}
                  onSelect={() => {
                    setSelectedCliente(cliente.id);
                    setActiveTab("contratos");
                  }}
                  onEdit={() => {
                    setEditingClienteId(cliente.id);
                    setShowClienteForm(true);
                  }}
                  onDelete={() => loadClientes()}
                />
              ))}
            </div>

            {filteredClientes.length === 0 && (
              <Card>
                <CardContent className="flex flex-col items-center justify-center py-12">
                  <AlertCircle className="h-12 w-12 text-muted-foreground mb-4" />
                  <p className="text-muted-foreground">Nenhum cliente encontrado</p>
                </CardContent>
              </Card>
            )}
          </TabsContent>

          {/* Contratos Tab */}
          <TabsContent value="contratos" className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="relative flex-1 max-w-sm">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Buscar contrato..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10"
                />
              </div>
              <Button onClick={() => setShowContratoForm(true)}>
                <Plus className="h-4 w-4 mr-2" />
                Novo Contrato
              </Button>
            </div>

            {showContratoForm && (
              <ContratoForm
                contratoId={editingContratoId}
                clienteId={selectedCliente || undefined}
                onClose={() => {
                  setShowContratoForm(false);
                  setEditingContratoId(undefined);
                }}
                onSuccess={() => {
                  loadContratos();
                  setShowContratoForm(false);
                  setEditingContratoId(undefined);
                }}
              />
            )}

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {filteredContratos.map((contrato) => (
                <ContratoCard
                  key={contrato.id}
                  contrato={contrato}
                  cliente={clientes.find(c => c.id === contrato.cliente_id)}
                  onSelect={() => {
                    setSelectedContrato(contrato.id);
                    setActiveTab("unidades");
                  }}
                  onEdit={() => {
                    setEditingContratoId(contrato.id);
                    setShowContratoForm(true);
                  }}
                  onDelete={() => loadContratos()}
                />
              ))}
            </div>

            {filteredContratos.length === 0 && (
              <Card>
                <CardContent className="flex flex-col items-center justify-center py-12">
                  <AlertCircle className="h-12 w-12 text-muted-foreground mb-4" />
                  <p className="text-muted-foreground">Nenhum contrato encontrado</p>
                </CardContent>
              </Card>
            )}
          </TabsContent>

          {/* Unidades Tab */}
          <TabsContent value="unidades" className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="relative flex-1 max-w-sm">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Buscar unidade..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10"
                />
              </div>
              <Button onClick={() => setShowUnidadeForm(true)}>
                <Plus className="h-4 w-4 mr-2" />
                Nova Unidade
              </Button>
            </div>

            {showUnidadeForm && (
              <UnidadeForm
                unidadeId={editingUnidadeId}
                contratoId={selectedContrato || undefined}
                onClose={() => {
                  setShowUnidadeForm(false);
                  setEditingUnidadeId(undefined);
                }}
                onSuccess={() => {
                  loadUnidades();
                  setShowUnidadeForm(false);
                  setEditingUnidadeId(undefined);
                }}
              />
            )}

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {filteredUnidades.map((unidade) => (
                <UnidadeCard
                  key={unidade.id}
                  unidade={unidade}
                  contrato={contratos.find(c => c.id === unidade.contrato_id)}
                  onSelect={() => {
                    setSelectedUnidade(unidade.id);
                    setActiveTab("postos");
                  }}
                  onEdit={() => {
                    setEditingUnidadeId(unidade.id);
                    setShowUnidadeForm(true);
                  }}
                  onDelete={() => loadUnidades()}
                />
              ))}
            </div>

            {filteredUnidades.length === 0 && (
              <Card>
                <CardContent className="flex flex-col items-center justify-center py-12">
                  <AlertCircle className="h-12 w-12 text-muted-foreground mb-4" />
                  <p className="text-muted-foreground">Nenhuma unidade encontrada</p>
                </CardContent>
              </Card>
            )}
          </TabsContent>

          {/* Postos Tab */}
          <TabsContent value="postos" className="space-y-4">
            <div className="flex items-center justify-between gap-4">
              <div className="flex items-center gap-2 flex-1">
                <div className="relative flex-1 max-w-sm">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                    placeholder="Buscar posto..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10"
                  />
                </div>
                {!selectedUnidade && (
                  <Select value={filterUnidadeId} onValueChange={setFilterUnidadeId}>
                    <SelectTrigger className="w-[250px]">
                      <SelectValue placeholder="Filtrar por unidade" />
                    </SelectTrigger>
                    <SelectContent className="bg-popover z-50">
                      <SelectItem value="all">Todas as unidades</SelectItem>
                      {unidades.map((unidade) => (
                        <SelectItem key={unidade.id} value={unidade.id}>
                          {unidade.nome}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                )}
                <Select value={filterOcupacao} onValueChange={setFilterOcupacao}>
                  <SelectTrigger className="w-[200px]">
                    <SelectValue placeholder="Filtrar por ocupação" />
                  </SelectTrigger>
                  <SelectContent className="bg-popover z-50">
                    <SelectItem value="all">Todos os postos</SelectItem>
                    <SelectItem value="ocupado">Ocupados</SelectItem>
                    <SelectItem value="vago">Vagos</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <Button onClick={() => setShowPostoForm(true)}>
                <Plus className="h-4 w-4 mr-2" />
                Novo Posto
              </Button>
            </div>

            {showPostoForm && (
              <PostoForm
                postoId={editingPostoId}
                unidadeId={selectedUnidade || undefined}
                onClose={() => {
                  setShowPostoForm(false);
                  setEditingPostoId(undefined);
                }}
                onSuccess={() => {
                  loadPostos();
                  setShowPostoForm(false);
                  setEditingPostoId(undefined);
                }}
              />
            )}

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {filteredPostos.map((posto) => (
                <PostoCard
                  key={posto.id}
                  posto={posto}
                  unidade={unidades.find(u => u.id === posto.unidade_id)}
                  onEdit={() => {
                    setEditingPostoId(posto.id);
                    setShowPostoForm(true);
                  }}
                  onDelete={() => loadPostos()}
                />
              ))}
            </div>

            {filteredPostos.length === 0 && (
              <Card>
                <CardContent className="flex flex-col items-center justify-center py-12">
                  <AlertCircle className="h-12 w-12 text-muted-foreground mb-4" />
                  <p className="text-muted-foreground">Nenhum posto encontrado</p>
                </CardContent>
              </Card>
            )}
          </TabsContent>
        </Tabs>
      </main>
    </div>
    </DashboardLayout>
  );
};

export default Contratos;
