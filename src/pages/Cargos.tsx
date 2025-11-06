import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { DashboardLayout } from "@/components/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Plus, Search } from "lucide-react";
import { CargoForm } from "@/components/colaboradores/CargoForm";
import { CargoCard } from "@/components/colaboradores/CargoCard";
import { toast } from "sonner";

export default function Cargos() {
  const [searchTerm, setSearchTerm] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [editingCargo, setEditingCargo] = useState<any>(null);

  const { data: cargos, refetch } = useQuery({
    queryKey: ["cargos"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("cargos")
        .select("*")
        .order("nome");
      
      if (error) throw error;
      return data;
    },
  });

  const filteredCargos = cargos?.filter((cargo) =>
    cargo.nome.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleEdit = (cargo: any) => {
    setEditingCargo(cargo);
    setShowForm(true);
  };

  const handleDelete = async (id: string) => {
    try {
      const { error } = await supabase
        .from("cargos")
        .delete()
        .eq("id", id);

      if (error) throw error;
      
      toast.success("Cargo excluído com sucesso");
      refetch();
    } catch (error: any) {
      toast.error(error.message || "Erro ao excluir cargo");
    }
  };

  const handleCloseForm = () => {
    setShowForm(false);
    setEditingCargo(null);
  };

  const handleSuccess = () => {
    handleCloseForm();
    refetch();
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">Cargos</h1>
          <Button onClick={() => setShowForm(true)}>
            <Plus className="mr-2 h-4 w-4" />
            Novo Cargo
          </Button>
        </div>

        <div className="flex items-center gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Buscar cargos..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-9"
            />
          </div>
        </div>

        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {filteredCargos?.map((cargo) => (
            <CargoCard
              key={cargo.id}
              cargo={cargo}
              onEdit={handleEdit}
              onDelete={handleDelete}
            />
          ))}
        </div>

        {filteredCargos?.length === 0 && (
          <div className="text-center py-12">
            <p className="text-muted-foreground">Nenhum cargo encontrado</p>
          </div>
        )}

        <CargoForm
          open={showForm}
          cargo={editingCargo}
          onClose={handleCloseForm}
          onSuccess={handleSuccess}
        />
      </div>
    </DashboardLayout>
  );
}
