import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { DashboardLayout } from "@/components/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Plus, Search } from "lucide-react";
import { ChamadoCard } from "@/components/chamados/ChamadoCard";
import { ChamadoForm } from "@/components/chamados/ChamadoForm";
import { Skeleton } from "@/components/ui/skeleton";
import { Card } from "@/components/ui/card";

export default function Chamados() {
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("todos");
  const [categoriaFilter, setCategoriaFilter] = useState<string>("todos");
  const [prioridadeFilter, setPrioridadeFilter] = useState<string>("todos");
  const [showForm, setShowForm] = useState(false);
  const [editingChamado, setEditingChamado] = useState<any>(null);

  const { data: chamados, isLoading, refetch } = useQuery({
    queryKey: ["chamados", statusFilter, categoriaFilter, prioridadeFilter],
    queryFn: async () => {
      let query = supabase
        .from("chamados")
        .select(`
          *,
          unidade:unidades(nome, codigo),
          posto_servico:postos_servico(nome, codigo),
          contrato:contratos(nome, codigo),
          solicitante:colaboradores!chamados_solicitante_id_fkey(nome_completo),
          atribuido:colaboradores!chamados_atribuido_para_id_fkey(nome_completo),
          responsavel:colaboradores!chamados_responsavel_id_fkey(nome_completo)
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
        </div>

        {isLoading ? (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {[1, 2, 3].map((i) => (
              <Skeleton key={i} className="h-[200px]" />
            ))}
          </div>
        ) : filteredChamados && filteredChamados.length > 0 ? (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {filteredChamados.map((chamado) => (
              <ChamadoCard
                key={chamado.id}
                chamado={chamado}
                onEdit={handleEdit}
                onDelete={handleDelete}
              />
            ))}
          </div>
        ) : (
          <Card className="p-8 text-center">
            <p className="text-muted-foreground">Nenhum chamado encontrado</p>
          </Card>
        )}

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
      </div>
    </DashboardLayout>
  );
}
