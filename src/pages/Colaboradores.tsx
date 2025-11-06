import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Plus, Search, Users, UserCheck, UserX, Briefcase, Calendar } from "lucide-react";
import { ColaboradorForm } from "@/components/colaboradores/ColaboradorForm";
import { ColaboradorCard } from "@/components/colaboradores/ColaboradorCard";
import { EfetivoStats } from "@/components/colaboradores/EfetivoStats";
import { PresencaDialog } from "@/components/colaboradores/PresencaDialog";
import { DashboardLayout } from "@/components/DashboardLayout";
import { toast } from "sonner";

export default function Colaboradores() {
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [cargoFilter, setCargoFilter] = useState<string>("all");
  const [unidadeFilter, setUnidadeFilter] = useState<string>("all");
  const [showForm, setShowForm] = useState(false);
  const [editingColaborador, setEditingColaborador] = useState<any>(null);
  const [presencaColaborador, setPresencaColaborador] = useState<any>(null);

  const { data: colaboradores, isLoading, refetch } = useQuery({
    queryKey: ["colaboradores", statusFilter, cargoFilter, unidadeFilter],
    queryFn: async () => {
      let query = supabase
        .from("colaboradores")
        .select(`
          *,
          cargo:cargos(nome),
          unidade:unidades(nome),
          escala:escalas(nome, tipo),
          posto:postos_servico(nome, codigo)
        `)
        .order("nome_completo");

      if (statusFilter !== "all") {
        query = query.eq("status", statusFilter);
      }
      if (cargoFilter !== "all") {
        query = query.eq("cargo_id", cargoFilter);
      }
      if (unidadeFilter !== "all") {
        query = query.eq("unidade_id", unidadeFilter);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data;
    },
  });

  const { data: cargos } = useQuery({
    queryKey: ["cargos"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("cargos")
        .select("id, nome")
        .order("nome");
      if (error) throw error;
      return data;
    },
  });

  const { data: unidades } = useQuery({
    queryKey: ["unidades"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("unidades")
        .select("id, nome")
        .eq("status", "ativo")
        .order("nome");
      if (error) throw error;
      return data;
    },
  });

  const filteredColaboradores = colaboradores?.filter((colab) =>
    colab.nome_completo.toLowerCase().includes(searchTerm.toLowerCase()) ||
    colab.cpf?.includes(searchTerm) ||
    colab.email?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleEdit = (colaborador: any) => {
    setEditingColaborador(colaborador);
    setShowForm(true);
  };

  const handleDelete = async (id: string) => {
    try {
      const { error } = await supabase
        .from("colaboradores")
        .delete()
        .eq("id", id);

      if (error) throw error;
      toast.success("Colaborador excluído com sucesso");
      refetch();
    } catch (error: any) {
      toast.error("Erro ao excluir colaborador: " + error.message);
    }
  };

  const handlePresenca = (colaborador: any) => {
    setPresencaColaborador(colaborador);
  };

  return (
    <DashboardLayout>
      <div className="min-h-screen bg-background p-8">
        <div className="max-w-7xl mx-auto space-y-8">
          <div className="flex items-center justify-between">
          <div>
            <h1 className="text-4xl font-bold text-foreground">Colaboradores</h1>
            <p className="text-muted-foreground mt-2">
              Gestão completa de colaboradores, escalas e controle de presença
            </p>
          </div>
          <Button onClick={() => {
            setEditingColaborador(null);
            setShowForm(true);
          }}>
            <Plus className="mr-2 h-4 w-4" />
            Novo Colaborador
          </Button>
        </div>

        {/* Stats Dashboard */}
        <EfetivoStats colaboradores={colaboradores || []} />

        {/* Filters */}
        <Card>
          <CardContent className="pt-6">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div className="relative">
                <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Buscar por nome, CPF, email..."
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
                  <SelectItem value="all">Todos os Status</SelectItem>
                  <SelectItem value="ativo">Ativo</SelectItem>
                  <SelectItem value="inativo">Inativo</SelectItem>
                  <SelectItem value="ferias">Férias</SelectItem>
                  <SelectItem value="afastado">Afastado</SelectItem>
                </SelectContent>
              </Select>
              <Select value={cargoFilter} onValueChange={setCargoFilter}>
                <SelectTrigger>
                  <SelectValue placeholder="Cargo" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Todos os Cargos</SelectItem>
                  {cargos?.map((cargo) => (
                    <SelectItem key={cargo.id} value={cargo.id}>
                      {cargo.nome}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Select value={unidadeFilter} onValueChange={setUnidadeFilter}>
                <SelectTrigger>
                  <SelectValue placeholder="Unidade" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Todas as Unidades</SelectItem>
                  {unidades?.map((unidade) => (
                    <SelectItem key={unidade.id} value={unidade.id}>
                      {unidade.nome}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </CardContent>
        </Card>

        {/* Colaboradores List */}
        <div className="space-y-4">
          {isLoading ? (
            <div className="text-center py-12">
              <p className="text-muted-foreground">Carregando colaboradores...</p>
            </div>
          ) : filteredColaboradores && filteredColaboradores.length > 0 ? (
            <div className="grid gap-4">
              {filteredColaboradores.map((colaborador) => (
                <ColaboradorCard
                  key={colaborador.id}
                  colaborador={colaborador}
                  onEdit={handleEdit}
                  onDelete={handleDelete}
                  onPresenca={handlePresenca}
                />
              ))}
            </div>
          ) : (
            <Card>
              <CardContent className="py-12 text-center">
                <Users className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
                <p className="text-muted-foreground">Nenhum colaborador encontrado</p>
                <Button onClick={() => setShowForm(true)} className="mt-4">
                  <Plus className="mr-2 h-4 w-4" />
                  Adicionar primeiro colaborador
                </Button>
              </CardContent>
            </Card>
          )}
        </div>

        {/* Form Dialog */}
        {showForm && (
          <ColaboradorForm
            colaborador={editingColaborador}
            open={showForm}
            onClose={() => {
              setShowForm(false);
              setEditingColaborador(null);
            }}
            onSuccess={() => {
              setShowForm(false);
              setEditingColaborador(null);
              refetch();
            }}
          />
        )}

        {/* Presenca Dialog */}
        {presencaColaborador && (
          <PresencaDialog
            colaborador={presencaColaborador}
            open={!!presencaColaborador}
            onClose={() => setPresencaColaborador(null)}
            onSuccess={() => {
              setPresencaColaborador(null);
              toast.success("Presença registrada com sucesso");
            }}
          />
        )}
        </div>
      </div>
    </DashboardLayout>
  );
}