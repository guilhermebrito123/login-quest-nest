import { useState, useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { DashboardLayout } from "@/components/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Plus, Search, Eye } from "lucide-react";
import { ChamadoForm } from "@/components/chamados/ChamadoForm";
import { ChamadoDetails } from "@/components/chamados/ChamadoDetails";
import { Card } from "@/components/ui/card";
import { format } from "date-fns";
import { ptBR } from "date-fns/locale";

export default function Chamados() {
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("todos");
  const [categoriaFilter, setCategoriaFilter] = useState<string>("todos");
  const [prioridadeFilter, setPrioridadeFilter] = useState<string>("todos");
  const [atribuidoFilter, setAtribuidoFilter] = useState<string>("todos");
  const [showForm, setShowForm] = useState(false);
  const [editingChamado, setEditingChamado] = useState<any>(null);
  const [detailsChamado, setDetailsChamado] = useState<any>(null);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);

  useEffect(() => {
    const fetchUser = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) setCurrentUserId(user.id);
    };
    fetchUser();
  }, []);

  const { data: chamados, isLoading, refetch } = useQuery({
    queryKey: ["chamados", statusFilter, categoriaFilter, prioridadeFilter, atribuidoFilter, currentUserId],
    queryFn: async () => {
      let query = supabase
        .from("chamados")
        .select(`
          *,
          unidade:unidades(nome)
        `)
        .order("data_abertura", { ascending: false });

      if (statusFilter !== "todos") {
        query = query.eq("status", statusFilter);
      }
      if (categoriaFilter !== "todos") {
        query = query.eq("categoria", categoriaFilter);
      }
      if (prioridadeFilter !== "todos") {
        query = query.eq("prioridade", prioridadeFilter);
      }
      if (atribuidoFilter === "meus" && currentUserId) {
        query = query.eq("atribuido_para_id", currentUserId);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data;
    },
  });

  const filteredChamados = chamados?.filter((chamado) =>
    chamado.titulo?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    chamado.numero?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    chamado.descricao?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const stats = {
    total: chamados?.length || 0,
    abertos: chamados?.filter((c) => c.status === "aberto").length || 0,
    em_andamento: chamados?.filter((c) => c.status === "em_andamento").length || 0,
    concluidos: chamados?.filter((c) => c.status === "concluido").length || 0,
  };

  const handleEdit = (chamado: any) => {
    setEditingChamado(chamado);
    setShowForm(true);
  };

  const handleDelete = async (id: string) => {
    const { error } = await supabase.from("chamados").delete().eq("id", id);
    if (!error) {
      refetch();
    }
  };

  const getStatusColor = (status: string) => {
    const colors = {
      aberto: "bg-yellow-500/10 text-yellow-600 border-yellow-500/20",
      em_andamento: "bg-blue-500/10 text-blue-600 border-blue-500/20",
      pendente: "bg-orange-500/10 text-orange-600 border-orange-500/20",
      concluido: "bg-green-500/10 text-green-600 border-green-500/20",
    };
    return colors[status as keyof typeof colors] || "";
  };

  const getPrioridadeColor = (prioridade: string) => {
    const colors = {
      baixa: "bg-gray-500/10 text-gray-600 border-gray-500/20",
      media: "bg-blue-500/10 text-blue-600 border-blue-500/20",
      alta: "bg-orange-500/10 text-orange-600 border-orange-500/20",
      critica: "bg-red-500/10 text-red-600 border-red-500/20",
    };
    return colors[prioridade as keyof typeof colors] || "";
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold">Chamados</h1>
            <p className="text-muted-foreground">Gestão completa de chamados e solicitações</p>
          </div>
          <Button onClick={() => { setEditingChamado(null); setShowForm(true); }}>
            <Plus className="mr-2 h-4 w-4" />
            Novo Chamado
          </Button>
        </div>

        <div className="grid gap-4 md:grid-cols-4">
          <Card className="p-4">
            <div className="text-sm font-medium text-muted-foreground">Total</div>
            <div className="text-2xl font-bold">{stats.total}</div>
          </Card>
          <Card className="p-4">
            <div className="text-sm font-medium text-muted-foreground">Abertos</div>
            <div className="text-2xl font-bold text-yellow-600">{stats.abertos}</div>
          </Card>
          <Card className="p-4">
            <div className="text-sm font-medium text-muted-foreground">Em Andamento</div>
            <div className="text-2xl font-bold text-blue-600">{stats.em_andamento}</div>
          </Card>
          <Card className="p-4">
            <div className="text-sm font-medium text-muted-foreground">Concluídos</div>
            <div className="text-2xl font-bold text-green-600">{stats.concluidos}</div>
          </Card>
        </div>

        <div className="flex flex-col gap-4 md:flex-row">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Buscar por título, número ou descrição..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-9"
            />
          </div>
          <Select value={statusFilter} onValueChange={setStatusFilter}>
            <SelectTrigger className="w-full md:w-[180px]">
              <SelectValue placeholder="Status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todos">Todos Status</SelectItem>
              <SelectItem value="aberto">Aberto</SelectItem>
              <SelectItem value="em_andamento">Em Andamento</SelectItem>
              <SelectItem value="pendente">Pendente</SelectItem>
              <SelectItem value="concluido">Concluído</SelectItem>
            </SelectContent>
          </Select>
          <Select value={categoriaFilter} onValueChange={setCategoriaFilter}>
            <SelectTrigger className="w-full md:w-[180px]">
              <SelectValue placeholder="Categoria" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todos">Todas Categorias</SelectItem>
              <SelectItem value="manutencao">Manutenção</SelectItem>
              <SelectItem value="rh">RH</SelectItem>
              <SelectItem value="suprimentos">Suprimentos</SelectItem>
              <SelectItem value="atendimento">Atendimento</SelectItem>
            </SelectContent>
          </Select>
          <Select value={prioridadeFilter} onValueChange={setPrioridadeFilter}>
            <SelectTrigger className="w-full md:w-[180px]">
              <SelectValue placeholder="Prioridade" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todos">Todas Prioridades</SelectItem>
              <SelectItem value="baixa">Baixa</SelectItem>
              <SelectItem value="media">Média</SelectItem>
              <SelectItem value="alta">Alta</SelectItem>
              <SelectItem value="critica">Crítica</SelectItem>
            </SelectContent>
          </Select>
          <Select value={atribuidoFilter} onValueChange={setAtribuidoFilter}>
            <SelectTrigger className="w-full md:w-[180px]">
              <SelectValue placeholder="Atribuição" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todos">Todos</SelectItem>
              <SelectItem value="meus">Meus Chamados</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Número</TableHead>
                <TableHead>Título</TableHead>
                <TableHead>Unidade</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Prioridade</TableHead>
                <TableHead>Data Abertura</TableHead>
                <TableHead className="text-right">Ações</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredChamados?.map((chamado) => (
                <TableRow
                  key={chamado.id}
                  className="cursor-pointer hover:bg-muted/50"
                  onClick={() => setDetailsChamado(chamado)}
                >
                  <TableCell className="font-mono text-sm">{chamado.numero}</TableCell>
                  <TableCell className="font-medium">{chamado.titulo}</TableCell>
                  <TableCell>{chamado.unidade?.nome || "-"}</TableCell>
                  <TableCell>
                    <Badge variant="outline" className={getStatusColor(chamado.status)}>
                      {chamado.status?.replace("_", " ")}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline" className={getPrioridadeColor(chamado.prioridade)}>
                      {chamado.prioridade}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    {format(new Date(chamado.data_abertura), "dd/MM/yyyy HH:mm", { locale: ptBR })}
                  </TableCell>
                  <TableCell className="text-right">
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={(e) => {
                        e.stopPropagation();
                        setDetailsChamado(chamado);
                      }}
                    >
                      <Eye className="h-4 w-4" />
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>

        {showForm && (
          <ChamadoForm
            open={showForm}
            onOpenChange={(open) => {
              setShowForm(open);
              if (!open) setEditingChamado(null);
            }}
            chamado={editingChamado}
            onSuccess={() => {
              setShowForm(false);
              setEditingChamado(null);
              refetch();
            }}
          />
        )}

        {detailsChamado && (
          <ChamadoDetails
            chamado={detailsChamado}
            open={!!detailsChamado}
            onOpenChange={(open) => !open && setDetailsChamado(null)}
            onEdit={handleEdit}
            onDelete={handleDelete}
          />
        )}
      </div>
    </DashboardLayout>
  );
}
