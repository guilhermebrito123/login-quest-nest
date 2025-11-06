import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Users, UserCheck, UserX, Briefcase, Calendar } from "lucide-react";

interface EfetivoStatsProps {
  colaboradores: any[];
}

export function EfetivoStats({ colaboradores }: EfetivoStatsProps) {
  const stats = {
    total: colaboradores.length,
    ativos: colaboradores.filter(c => c.status === "ativo").length,
    inativos: colaboradores.filter(c => c.status === "inativo").length,
    ferias: colaboradores.filter(c => c.status === "ferias").length,
    afastados: colaboradores.filter(c => c.status === "afastado").length,
  };

  const cargosCounts = colaboradores.reduce((acc, colab) => {
    const cargoNome = colab.cargo?.nome || "Sem cargo";
    acc[cargoNome] = (acc[cargoNome] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  const topCargos = Object.entries(cargosCounts)
    .sort(([, a], [, b]) => (b as number) - (a as number))
    .slice(0, 3);

  const percentualAtivos = stats.total > 0 ? ((stats.ativos / stats.total) * 100).toFixed(1) : "0";

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      <Card>
        <CardHeader className="pb-2">
          <CardDescription>Efetivo Total</CardDescription>
          <CardTitle className="text-3xl">{stats.total}</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-2">
            <Users className="h-4 w-4 text-muted-foreground" />
            <span className="text-sm text-muted-foreground">Colaboradores cadastrados</span>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="pb-2">
          <CardDescription>Ativos</CardDescription>
          <CardTitle className="text-3xl text-green-600">{stats.ativos}</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-2">
            <UserCheck className="h-4 w-4 text-green-600" />
            <span className="text-sm text-muted-foreground">{percentualAtivos}% do efetivo</span>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="pb-2">
          <CardDescription>Inativos</CardDescription>
          <CardTitle className="text-3xl text-red-600">{stats.inativos}</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-2">
            <UserX className="h-4 w-4 text-red-600" />
            <span className="text-sm text-muted-foreground">Desligados</span>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="pb-2">
          <CardDescription>Afastamentos</CardDescription>
          <CardTitle className="text-3xl text-yellow-600">{stats.ferias + stats.afastados}</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-2">
            <Calendar className="h-4 w-4 text-yellow-600" />
            <span className="text-sm text-muted-foreground">
              {stats.ferias} férias • {stats.afastados} afastados
            </span>
          </div>
        </CardContent>
      </Card>

      {topCargos.length > 0 && (
        <Card className="md:col-span-2 lg:col-span-4">
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Briefcase className="h-5 w-5" />
              Distribuição por Cargo
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {topCargos.map(([cargo, count]) => (
                <div key={cargo} className="flex items-center justify-between p-3 bg-muted rounded-lg">
                  <span className="font-medium">{cargo}</span>
                  <Badge variant="secondary">{String(count)} colaboradores</Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}