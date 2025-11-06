import { useState, useEffect } from "react";
import { DashboardLayout } from "@/components/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Plus, Search, Edit, Trash2, Package, AlertTriangle } from "lucide-react";
import { ItemEstoqueForm } from "@/components/recursos/ItemEstoqueForm";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";

export default function Estoque() {
  const [itens, setItens] = useState<any[]>([]);
  const [filteredItens, setFilteredItens] = useState<any[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [formOpen, setFormOpen] = useState(false);
  const [selectedItem, setSelectedItem] = useState<any>(null);
  const [stats, setStats] = useState<any>({});

  useEffect(() => {
    fetchItens();
  }, []);

  useEffect(() => {
    const filtered = itens.filter(
      (item) =>
        item.sku?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.descricao?.toLowerCase().includes(searchTerm.toLowerCase())
    );
    setFilteredItens(filtered);
  }, [searchTerm, itens]);

  const fetchItens = async () => {
    const { data, error } = await supabase
      .from("itens_estoque")
      .select("*, unidades(nome)")
      .order("created_at", { ascending: false });

    if (error) {
      toast.error("Erro ao carregar itens");
      return;
    }

    setItens(data || []);
    calculateStats(data || []);
  };

  const calculateStats = (data: any[]) => {
    const totalItens = data.length;
    const abaixoMinimo = data.filter(
      (item) => item.quantidade_atual < item.quantidade_minima
    ).length;
    const quantidadeTotal = data.reduce(
      (acc, item) => acc + (item.quantidade_atual || 0),
      0
    );

    setStats({ totalItens, abaixoMinimo, quantidadeTotal });
  };

  const handleDelete = async (id: string) => {
    if (!confirm("Tem certeza que deseja deletar este item?")) return;

    const { error } = await supabase.from("itens_estoque").delete().eq("id", id);
    if (error) {
      toast.error("Erro ao deletar item");
      return;
    }
    toast.success("Item deletado com sucesso!");
    fetchItens();
  };

  const handleEdit = (item: any) => {
    setSelectedItem(item);
    setFormOpen(true);
  };

  const handleNewItem = () => {
    setSelectedItem(null);
    setFormOpen(true);
  };

  const isAbaixoMinimo = (item: any) => {
    return item.quantidade_atual < item.quantidade_minima;
  };

  return (
    <DashboardLayout>
      <div className="p-6 space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-3xl font-bold">Gestão de Estoque</h1>
          <Button onClick={handleNewItem}>
            <Plus className="h-4 w-4 mr-2" />
            Novo Item
          </Button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total de Itens</CardTitle>
              <Package className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalItens || 0}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Abaixo do Mínimo</CardTitle>
              <AlertTriangle className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.abaixoMinimo || 0}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Quantidade Total</CardTitle>
              <Package className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.quantidadeTotal || 0}</div>
            </CardContent>
          </Card>
        </div>

        <Card>
          <CardHeader>
            <div className="flex items-center gap-4">
              <div className="relative flex-1">
                <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Buscar por SKU ou descrição..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-8"
                />
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>SKU</TableHead>
                  <TableHead>Descrição</TableHead>
                  <TableHead>Unidade</TableHead>
                  <TableHead>Un. Medida</TableHead>
                  <TableHead>Qtd. Mínima</TableHead>
                  <TableHead>Qtd. Atual</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Ações</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredItens.map((item) => (
                  <TableRow key={item.id}>
                    <TableCell className="font-medium">{item.sku}</TableCell>
                    <TableCell>{item.descricao}</TableCell>
                    <TableCell>{item.unidades?.nome}</TableCell>
                    <TableCell>{item.unidade_medida}</TableCell>
                    <TableCell>{item.quantidade_minima}</TableCell>
                    <TableCell>{item.quantidade_atual}</TableCell>
                    <TableCell>
                      {isAbaixoMinimo(item) ? (
                        <Badge variant="destructive">Abaixo do Mínimo</Badge>
                      ) : (
                        <Badge variant="default">Normal</Badge>
                      )}
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-2">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleEdit(item)}
                        >
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleDelete(item.id)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>

      <ItemEstoqueForm
        open={formOpen}
        onOpenChange={setFormOpen}
        item={selectedItem}
        onSuccess={fetchItens}
      />
    </DashboardLayout>
  );
}
