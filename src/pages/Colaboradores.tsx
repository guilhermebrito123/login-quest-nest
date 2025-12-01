import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Plus, Search, Edit, Trash2, History, Calendar, MapPin, Unlink } from "lucide-react";
import { ColaboradorForm } from "@/components/colaboradores/ColaboradorForm";
import { PresencaDialog } from "@/components/colaboradores/PresencaDialog";
import { RequisitosMissingDialog } from "@/components/colaboradores/RequisitosMissingDialog";
import { AtribuirEscalaDialog } from "@/components/colaboradores/AtribuirEscalaDialog";
import { AtribuirUnidadeDialog } from "@/components/colaboradores/AtribuirUnidadeDialog";
import { DashboardLayout } from "@/components/DashboardLayout";
import { toast } from "sonner";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";

export default function Colaboradores() {
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [unidadeFilter, setUnidadeFilter] = useState<string>("all");
  const [showForm, setShowForm] = useState(false);
  const [editingColaborador, setEditingColaborador] = useState<any>(null);
  const [presencaColaborador, setPresencaColaborador] = useState<any>(null);
  const [showRequisitosMissing, setShowRequisitosMissing] = useState(false);
  const [missingEntities, setMissingEntities] = useState<string[]>([]);
  const [escalaColaborador, setEscalaColaborador] = useState<any>(null);
  const [unidadeColaborador, setUnidadeColaborador] = useState<any>(null);

  const { data: colaboradores, refetch } = useQuery({
    queryKey: ["colaboradores", statusFilter, unidadeFilter],
    queryFn: async () => {
      let query = supabase
        .from("colaboradores")
        .select(`
          *,
          unidade:unidades(nome),
          escala:escalas(nome, tipo),
          posto:postos_servico(nome)
        `)
        .order("nome_completo");

      if (statusFilter !== "all") {
        query = query.eq("status_colaborador", statusFilter as "ativo" | "inativo");
      }
      if (unidadeFilter !== "all") {
        query = query.eq("unidade_id", unidadeFilter);
      }

      const { data, error } = await query;
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
      toast.error(error.message || "Erro ao excluir colaborador");
    }
  };

  const handleDesvincularPosto = async (colaboradorId: string) => {
    try {
      const { error } = await supabase
        .from("colaboradores")
        .update({ posto_servico_id: null })
        .eq("id", colaboradorId);

      if (error) throw error;
      toast.success("Posto de serviço desvinculado com sucesso");
      refetch();
    } catch (error: any) {
      toast.error(error.message || "Erro ao desvincular posto de serviço");
    }
  };

  const handleNewColaborador = () => {
    // Verificar requisitos
    const missing = [];
    if (!unidades || unidades.length === 0) missing.push("Unidades");

    if (missing.length > 0) {
      setMissingEntities(missing);
      setShowRequisitosMissing(true);
      return;
    }

    setShowForm(true);
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">Colaboradores</h1>
          <Button onClick={handleNewColaborador}>
            <Plus className="mr-2 h-4 w-4" />
            Novo Colaborador
          </Button>
        </div>

        <div className="flex flex-col gap-4 md:flex-row">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Buscar por nome, CPF ou email..."
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
              <SelectItem value="all">Todos Status</SelectItem>
              <SelectItem value="ativo">Ativo</SelectItem>
              <SelectItem value="inativo">Inativo</SelectItem>
            </SelectContent>
          </Select>
          <Select value={unidadeFilter} onValueChange={setUnidadeFilter}>
            <SelectTrigger className="w-full md:w-[180px]">
              <SelectValue placeholder="Unidade" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Todas Unidades</SelectItem>
              {unidades?.map((unidade) => (
                <SelectItem key={unidade.id} value={unidade.id}>
                  {unidade.nome}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Nome</TableHead>
                <TableHead>Cargo</TableHead>
                <TableHead>Função</TableHead>
                <TableHead>Tipo</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Unidade Padrão</TableHead>
                <TableHead className="text-right">Ações</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredColaboradores?.map((colaborador) => (
                <TableRow key={colaborador.id}>
                  <TableCell className="font-medium">{colaborador.nome_completo}</TableCell>
                  <TableCell>{colaborador.cargo || "-"}</TableCell>
                  <TableCell>{colaborador.posto?.nome || "-"}</TableCell>
                  <TableCell>
                    {colaborador.escala?.tipo === "12x36" ? "escala_12x36" : 
                     colaborador.escala?.tipo === "diarista" ? "diarista" : 
                     colaborador.escala?.tipo || "efetivo"}
                  </TableCell>
                  <TableCell>
                    <Badge
                      variant={
                        colaborador.status_colaborador === "ativo"
                          ? "default"
                          : "outline"
                      }
                    >
                      {colaborador.status_colaborador}
                    </Badge>
                  </TableCell>
                  <TableCell>{colaborador.unidade?.nome || "-"}</TableCell>
                  <TableCell className="text-right">
                    <div className="flex items-center justify-end gap-2">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => setEscalaColaborador(colaborador)}
                        title="Atribuir Escala"
                      >
                        <Calendar className="h-4 w-4" />
                      </Button>
                      {!colaborador.posto_servico_id && (
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => setUnidadeColaborador(colaborador)}
                          title="Atribuir Unidade/Posto"
                        >
                          <MapPin className="h-4 w-4" />
                        </Button>
                      )}
                      {colaborador.posto_servico_id && (
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleDesvincularPosto(colaborador.id)}
                          title="Desvincular Posto de Serviço"
                        >
                          <Unlink className="h-4 w-4 text-orange-500" />
                        </Button>
                      )}
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => setPresencaColaborador(colaborador)}
                        title="Histórico de Presença"
                      >
                        <History className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => handleEdit(colaborador)}
                      >
                        <Edit className="h-4 w-4" />
                      </Button>
                      <AlertDialog>
                        <AlertDialogTrigger asChild>
                          <Button variant="ghost" size="icon">
                            <Trash2 className="h-4 w-4 text-destructive" />
                          </Button>
                        </AlertDialogTrigger>
                        <AlertDialogContent>
                          <AlertDialogHeader>
                            <AlertDialogTitle>Confirmar exclusão</AlertDialogTitle>
                            <AlertDialogDescription>
                              Tem certeza que deseja excluir este colaborador?
                            </AlertDialogDescription>
                          </AlertDialogHeader>
                          <AlertDialogFooter>
                            <AlertDialogCancel>Cancelar</AlertDialogCancel>
                            <AlertDialogAction onClick={() => handleDelete(colaborador.id)}>
                              Excluir
                            </AlertDialogAction>
                          </AlertDialogFooter>
                        </AlertDialogContent>
                      </AlertDialog>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>

        {showForm && (
          <ColaboradorForm
            open={showForm}
            onClose={() => {
              setShowForm(false);
              setEditingColaborador(null);
            }}
            colaborador={editingColaborador}
            onSuccess={() => {
              setShowForm(false);
              setEditingColaborador(null);
              refetch();
            }}
          />
        )}

        {presencaColaborador && (
          <PresencaDialog
            open={!!presencaColaborador}
            onClose={() => setPresencaColaborador(null)}
            colaborador={presencaColaborador}
            onSuccess={refetch}
          />
        )}

        {showRequisitosMissing && (
          <RequisitosMissingDialog
            open={showRequisitosMissing}
            onClose={() => setShowRequisitosMissing(false)}
            missingEntities={missingEntities}
          />
        )}

        {escalaColaborador && (
          <AtribuirEscalaDialog
            open={!!escalaColaborador}
            onClose={() => setEscalaColaborador(null)}
            colaborador={escalaColaborador}
            onSuccess={refetch}
          />
        )}

        {unidadeColaborador && (
          <AtribuirUnidadeDialog
            open={!!unidadeColaborador}
            onClose={() => setUnidadeColaborador(null)}
            colaborador={unidadeColaborador}
            onSuccess={refetch}
          />
        )}
      </div>
    </DashboardLayout>
  );
}
