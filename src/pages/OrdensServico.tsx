import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import { Plus, Search, FileText, ClipboardList, CheckCircle2, XCircle } from "lucide-react";
import { OrdemServicoForm } from "@/components/os/OrdemServicoForm";
import { OrdemServicoCard } from "@/components/os/OrdemServicoCard";
import { DashboardLayout } from "@/components/DashboardLayout";
import { toast } from "sonner";

export default function OrdensServico() {
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("ativas");
  const [prioridadeFilter, setPrioridadeFilter] = useState<string>("all");
  const [tipoFilter, setTipoFilter] = useState<string>("all");
  const [showForm, setShowForm] = useState(false);
  const [editingOS, setEditingOS] = useState<any>(null);

  const { data: ordensServico, isLoading, refetch } = useQuery({
    queryKey: ["ordens-servico", statusFilter, prioridadeFilter, tipoFilter],
    queryFn: async () => {
      let query = supabase
        .from("ordens_servico")
        .select(`
          *,
          unidade:unidades(nome),
          solicitante:profiles!ordens_servico_solicitante_id_fkey(full_name),
          responsavel:profiles!ordens_servico_responsavel_id_fkey(full_name)
        `)
        .order("created_at", { ascending: false });

      // Filtro especial para "ativas" (não concluídas)
      if (statusFilter === "ativas") {
        query = query.neq("status", "concluida");
      } else if (statusFilter !== "all") {
        query = query.eq("status", statusFilter);
      }
      
      if (prioridadeFilter !== "all") {
        query = query.eq("prioridade", prioridadeFilter);
      }
      if (tipoFilter !== "all") {
        query = query.eq("tipo", tipoFilter);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data;
    },
  });

  const filteredOS = ordensServico?.filter((os) =>
    os.numero.toLowerCase().includes(searchTerm.toLowerCase()) ||
    os.titulo.toLowerCase().includes(searchTerm.toLowerCase()) ||
    os.descricao?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const stats = {
    total: ordensServico?.length || 0,
    abertas: ordensServico?.filter(os => os.status === "aberta").length || 0,
    emAndamento: ordensServico?.filter(os => os.status === "em_andamento").length || 0,
    concluidas: ordensServico?.filter(os => os.status === "concluida").length || 0,
  };

  const handleEdit = (os: any) => {
    setEditingOS(os);
    setShowForm(true);
  };

  const handleDelete = async (id: string) => {
    try {
      const { error } = await supabase
        .from("ordens_servico")
        .delete()
        .eq("id", id);

      if (error) throw error;
      toast.success("OS excluída com sucesso");
      refetch();
    } catch (error: any) {
      toast.error("Erro ao excluir OS: " + error.message);
    }
  };

  const handleConcluir = async (id: string) => {
    try {
      const { error } = await supabase
        .from("ordens_servico")
        .update({ 
          status: "concluida",
          data_conclusao: new Date().toISOString()
        })
        .eq("id", id);

      if (error) throw error;
      toast.success("OS concluída com sucesso");
      refetch();
    } catch (error: any) {
      toast.error("Erro ao concluir OS: " + error.message);
    }
  };

  return (
    <DashboardLayout>
      <div className="min-h-screen bg-background p-8">
        <div className="max-w-7xl mx-auto space-y-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-4xl font-bold text-foreground">Ordens de Serviço</h1>
            <p className="text-muted-foreground mt-2">
              Gestão completa de ordens de serviço preventivas, corretivas e emergenciais
            </p>
          </div>
          <Button onClick={() => {
            setEditingOS(null);
            setShowForm(true);
          }}>
            <Plus className="mr-2 h-4 w-4" />
            Nova OS
          </Button>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card>
            <CardHeader className="pb-2">
              <CardDescription>Total de OS</CardDescription>
              <CardTitle className="text-3xl">{stats.total}</CardTitle>
            </CardHeader>
            <CardContent>
              <FileText className="h-4 w-4 text-muted-foreground" />
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="pb-2">
              <CardDescription>Abertas</CardDescription>
              <CardTitle className="text-3xl text-yellow-600">{stats.abertas}</CardTitle>
            </CardHeader>
            <CardContent>
              <ClipboardList className="h-4 w-4 text-yellow-600" />
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="pb-2">
              <CardDescription>Em Andamento</CardDescription>
              <CardTitle className="text-3xl text-blue-600">{stats.emAndamento}</CardTitle>
            </CardHeader>
            <CardContent>
              <ClipboardList className="h-4 w-4 text-blue-600" />
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="pb-2">
              <CardDescription>Concluídas</CardDescription>
              <CardTitle className="text-3xl text-green-600">{stats.concluidas}</CardTitle>
            </CardHeader>
            <CardContent>
              <CheckCircle2 className="h-4 w-4 text-green-600" />
            </CardContent>
          </Card>
        </div>

        {/* Filters */}
        <Card>
          <CardContent className="pt-6">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div className="relative">
                <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Buscar por número, título..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-9"
                />
              </div>
              <Select value={statusFilter} onValueChange={setStatusFilter}>
                <SelectTrigger>
                  <SelectValue placeholder="Status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ativas">Ativas (Abertas e Em Andamento)</SelectItem>
                  <SelectItem value="all">Todos os Status</SelectItem>
                  <SelectItem value="aberta">Aberta</SelectItem>
                  <SelectItem value="em_andamento">Em Andamento</SelectItem>
                  <SelectItem value="concluida">Concluída</SelectItem>
                  <SelectItem value="cancelada">Cancelada</SelectItem>
                </SelectContent>
              </Select>
              <Select value={prioridadeFilter} onValueChange={setPrioridadeFilter}>
                <SelectTrigger>
                  <SelectValue placeholder="Prioridade" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Todas as Prioridades</SelectItem>
                  <SelectItem value="baixa">Baixa</SelectItem>
                  <SelectItem value="media">Média</SelectItem>
                  <SelectItem value="alta">Alta</SelectItem>
                  <SelectItem value="urgente">Urgente</SelectItem>
                </SelectContent>
              </Select>
              <Select value={tipoFilter} onValueChange={setTipoFilter}>
                <SelectTrigger>
                  <SelectValue placeholder="Tipo" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Todos os Tipos</SelectItem>
                  <SelectItem value="preventiva">Preventiva</SelectItem>
                  <SelectItem value="corretiva">Corretiva</SelectItem>
                  <SelectItem value="emergencial">Emergencial</SelectItem>
                  <SelectItem value="melhoria">Melhoria</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </CardContent>
        </Card>

        {/* OS List */}
        <div className="space-y-4">
          {isLoading ? (
            <div className="text-center py-12">
              <p className="text-muted-foreground">Carregando ordens de serviço...</p>
            </div>
          ) : filteredOS && filteredOS.length > 0 ? (
            <div className="grid gap-4">
              {filteredOS.map((os) => (
                <OrdemServicoCard
                  key={os.id}
                  os={os}
                  onEdit={handleEdit}
                  onDelete={handleDelete}
                  onConcluir={handleConcluir}
                />
              ))}
            </div>
          ) : (
            <Card>
              <CardContent className="py-12 text-center">
                <FileText className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
                <p className="text-muted-foreground">Nenhuma ordem de serviço encontrada</p>
                <Button onClick={() => setShowForm(true)} className="mt-4">
                  <Plus className="mr-2 h-4 w-4" />
                  Criar primeira OS
                </Button>
              </CardContent>
            </Card>
          )}
        </div>

        {/* Form Dialog */}
        {showForm && (
          <OrdemServicoForm
            os={editingOS}
            open={showForm}
            onClose={() => {
              setShowForm(false);
              setEditingOS(null);
            }}
            onSuccess={() => {
              setShowForm(false);
              setEditingOS(null);
              refetch();
            }}
          />
        )}
        </div>
      </div>
    </DashboardLayout>
  );
}