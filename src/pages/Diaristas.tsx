import { useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { DashboardLayout } from "@/components/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Plus, Search, Edit, Trash2 } from "lucide-react";
import { toast } from "sonner";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { DiaristaForm } from "@/components/diaristas/DiaristaForm";

export default function Diaristas() {
  const [searchTerm, setSearchTerm] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [editingDiarista, setEditingDiarista] = useState<any>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const queryClient = useQueryClient();

  const { data: diaristas, isLoading } = useQuery({
    queryKey: ["diaristas"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("diaristas")
        .select("*")
        .order("nome_completo");

      if (error) throw error;
      return data || [];
    },
  });

  const filteredDiaristas = diaristas?.filter((diarista) =>
    diarista.nome_completo.toLowerCase().includes(searchTerm.toLowerCase()) ||
    diarista.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
    diarista.telefone.includes(searchTerm)
  );

  const handleEdit = (diarista: any) => {
    setEditingDiarista(diarista);
    setShowForm(true);
  };

  const handleDelete = async (id: string) => {
    try {
      const { error } = await supabase.from("diaristas").delete().eq("id", id);

      if (error) throw error;

      toast.success("Diarista excluído com sucesso");
      queryClient.invalidateQueries({ queryKey: ["diaristas"] });
      setDeletingId(null);
    } catch (error: any) {
      toast.error("Erro ao excluir diarista: " + error.message);
    }
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-3xl font-bold">Diaristas</h1>
          <Button
            onClick={() => {
              setEditingDiarista(null);
              setShowForm(true);
            }}
          >
            <Plus className="mr-2 h-4 w-4" />
            Novo Diarista
          </Button>
        </div>

        <div className="flex items-center gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
            <Input
              placeholder="Buscar por nome, email ou telefone..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10"
            />
          </div>
        </div>

        <div className="border rounded-lg">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Nome</TableHead>
                <TableHead>RG</TableHead>
                <TableHead>CNH</TableHead>
                <TableHead>Telefone</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Endereço</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Ações</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading ? (
                <TableRow>
                  <TableCell colSpan={8} className="text-center">
                    Carregando...
                  </TableCell>
                </TableRow>
              ) : filteredDiaristas?.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8} className="text-center">
                    Nenhum diarista encontrado
                  </TableCell>
                </TableRow>
              ) : (
                filteredDiaristas?.map((diarista) => (
                  <TableRow key={diarista.id}>
                    <TableCell className="font-medium">
                      {diarista.nome_completo}
                    </TableCell>
                    <TableCell>{diarista.rg}</TableCell>
                    <TableCell>{diarista.cnh}</TableCell>
                    <TableCell>{diarista.telefone}</TableCell>
                    <TableCell>{diarista.email}</TableCell>
                    <TableCell>{diarista.endereco}</TableCell>
                    <TableCell>
                      <Badge
                        variant={
                          diarista.status === "ativo" ? "default" : "secondary"
                        }
                      >
                        {diarista.status}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleEdit(diarista)}
                        >
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => setDeletingId(diarista.id)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </div>
      </div>

      <DiaristaForm
        open={showForm}
        onClose={() => {
          setShowForm(false);
          setEditingDiarista(null);
        }}
        onSuccess={() => {
          queryClient.invalidateQueries({ queryKey: ["diaristas"] });
          setShowForm(false);
          setEditingDiarista(null);
        }}
        diarista={editingDiarista}
      />

      <AlertDialog open={!!deletingId} onOpenChange={() => setDeletingId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Confirmar exclusão</AlertDialogTitle>
            <AlertDialogDescription>
              Tem certeza que deseja excluir este diarista? Esta ação não pode
              ser desfeita.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => deletingId && handleDelete(deletingId)}
            >
              Excluir
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </DashboardLayout>
  );
}
