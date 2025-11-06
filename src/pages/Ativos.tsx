import { useState, useEffect } from "react";
import { DashboardLayout } from "@/components/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Plus, Search, Edit, Trash2, Package } from "lucide-react";
import { AtivoForm } from "@/components/recursos/AtivoForm";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";

export default function Ativos() {
  const [ativos, setAtivos] = useState<any[]>([]);
  const [filteredAtivos, setFilteredAtivos] = useState<any[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [formOpen, setFormOpen] = useState(false);
  const [selectedAtivo, setSelectedAtivo] = useState<any>(null);
  const [stats, setStats] = useState<any>({});

  useEffect(() => {
    fetchAtivos();
  }, []);

  useEffect(() => {
    const filtered = ativos.filter(
      (ativo) =>
        ativo.tag_patrimonio?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        ativo.categoria?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        ativo.fabricante?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        ativo.modelo?.toLowerCase().includes(searchTerm.toLowerCase())
    );
    setFilteredAtivos(filtered);
  }, [searchTerm, ativos]);

  const fetchAtivos = async () => {
    const { data, error } = await supabase
      .from("ativos")
      .select("*, unidades(nome)")
      .order("created_at", { ascending: false });

    if (error) {
      toast.error("Erro ao carregar ativos");
      return;
    }

    setAtivos(data || []);
    calculateStats(data || []);
  };

  const calculateStats = (data: any[]) => {
    const totalAtivos = data.length;
    const categorias = data.reduce((acc: any, ativo) => {
      const cat = ativo.categoria || "Sem categoria";
      acc[cat] = (acc[cat] || 0) + 1;
      return acc;
    }, {});

    const operacionais = data.filter((a) => a.status === "operacional").length;
    const criticos = data.filter((a) => a.critico).length;

    setStats({ totalAtivos, categorias, operacionais, criticos });
  };

  const handleDelete = async (id: string) => {
    if (!confirm("Tem certeza que deseja deletar este ativo?")) return;

    const { error } = await supabase.from("ativos").delete().eq("id", id);
    if (error) {
      toast.error("Erro ao deletar ativo");
      return;
    }
    toast.success("Ativo deletado com sucesso!");
    fetchAtivos();
  };

  const handleEdit = (ativo: any) => {
    setSelectedAtivo(ativo);
    setFormOpen(true);
  };

  const handleNewAtivo = () => {
    setSelectedAtivo(null);
    setFormOpen(true);
  };

  return (
    <DashboardLayout>
      <div className="p-6 space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-3xl font-bold">Gestão de Ativos</h1>
          <Button onClick={handleNewAtivo}>
            <Plus className="h-4 w-4 mr-2" />
            Novo Ativo
          </Button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total de Ativos</CardTitle>
              <Package className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalAtivos || 0}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Operacionais</CardTitle>
              <Package className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.operacionais || 0}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Críticos</CardTitle>
              <Package className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.criticos || 0}</div>
            </CardContent>
          </Card>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {Object.entries(stats.categorias || {}).map(([categoria, count]) => (
            <Card key={categoria}>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium capitalize">{categoria}</CardTitle>
                <Package className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{count as number}</div>
              </CardContent>
            </Card>
          ))}
        </div>

        <Card>
          <CardHeader>
            <div className="flex items-center gap-4">
              <div className="relative flex-1">
                <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Buscar por tag, categoria, fabricante ou modelo..."
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
                  <TableHead>Tag Patrimônio</TableHead>
                  <TableHead>Categoria</TableHead>
                  <TableHead>Fabricante</TableHead>
                  <TableHead>Modelo</TableHead>
                  <TableHead>Unidade</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Crítico</TableHead>
                  <TableHead>Ações</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredAtivos.map((ativo) => (
                  <TableRow key={ativo.id}>
                    <TableCell className="font-medium">{ativo.tag_patrimonio}</TableCell>
                    <TableCell>{ativo.categoria}</TableCell>
                    <TableCell>{ativo.fabricante}</TableCell>
                    <TableCell>{ativo.modelo}</TableCell>
                    <TableCell>{ativo.unidades?.nome}</TableCell>
                    <TableCell>
                      <Badge
                        variant={
                          ativo.status === "operacional"
                            ? "default"
                            : ativo.status === "manutencao"
                            ? "secondary"
                            : "outline"
                        }
                      >
                        {ativo.status}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      {ativo.critico ? (
                        <Badge variant="destructive">Sim</Badge>
                      ) : (
                        <Badge variant="outline">Não</Badge>
                      )}
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-2">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleEdit(ativo)}
                        >
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleDelete(ativo.id)}
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

      <AtivoForm
        open={formOpen}
        onOpenChange={setFormOpen}
        ativo={selectedAtivo}
        onSuccess={fetchAtivos}
      />
    </DashboardLayout>
  );
}
