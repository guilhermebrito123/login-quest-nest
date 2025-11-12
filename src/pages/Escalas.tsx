import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client-custom";
import { DashboardLayout } from "@/components/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Calendar, Clock, MapPin } from "lucide-react";
import { EscalaForm } from "@/components/colaboradores/EscalaForm";
import { toast } from "sonner";

export default function Escalas() {
  const [editingEscala, setEditingEscala] = useState<any>(null);

  const { data: escalasComDetalhes, isLoading, refetch } = useQuery({
    queryKey: ["escalas-detalhes"],
    queryFn: async () => {
      // Buscar todas as escalas únicas dos postos de serviço
      const { data: postos, error } = await supabase
        .from("postos_servico")
        .select(`
          id,
          nome,
          codigo,
          escala,
          turno,
          jornada,
          horario_inicio,
          horario_fim,
          dias_semana,
          unidade:unidades(nome, codigo)
        `)
        .eq("status", "ativo")
        .order("escala");

      if (error) throw error;

      // Agrupar postos por escala
      const escalasMap = new Map();
      postos?.forEach((posto) => {
        if (posto.escala) {
          if (!escalasMap.has(posto.escala)) {
            escalasMap.set(posto.escala, {
              escala: posto.escala,
              turno: posto.turno,
              jornada: posto.jornada,
              horario_inicio: posto.horario_inicio,
              horario_fim: posto.horario_fim,
              dias_semana: posto.dias_semana,
              postos: [],
            });
          }
          escalasMap.get(posto.escala).postos.push({
            id: posto.id,
            nome: posto.nome,
            codigo: posto.codigo,
            unidade: posto.unidade,
          });
        }
      });

      return Array.from(escalasMap.values());
    },
  });

  const { data: escalasModelo } = useQuery({
    queryKey: ["escalas-modelo"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("escalas")
        .select("*")
        .order("nome");
      if (error) throw error;
      return data;
    },
  });

  const handleDelete = async (id: string) => {
    try {
      const { error } = await supabase
        .from("escalas")
        .delete()
        .eq("id", id);

      if (error) throw error;
      toast.success("Escala excluída com sucesso");
      refetch();
    } catch (error: any) {
      toast.error("Erro ao excluir escala: " + error.message);
    }
  };

  return (
    <DashboardLayout>
      <div className="min-h-screen bg-background p-8">
        <div className="max-w-7xl mx-auto space-y-8">
          <div>
            <h1 className="text-4xl font-bold text-foreground">Escalas</h1>
            <p className="text-muted-foreground mt-2">
              Gestão de escalas e turnos de trabalho
            </p>
          </div>

          {/* Escalas dos Postos de Serviço */}
          <div className="space-y-4">
            <h2 className="text-2xl font-semibold">Escalas em Uso</h2>
            {isLoading ? (
              <div className="text-center py-12">
                <p className="text-muted-foreground">Carregando escalas...</p>
              </div>
            ) : escalasComDetalhes && escalasComDetalhes.length > 0 ? (
              <div className="grid gap-4 md:grid-cols-2">
                {escalasComDetalhes.map((escalaInfo, idx) => (
                  <Card key={idx}>
                    <CardHeader>
                      <div className="flex items-start justify-between">
                        <div>
                          <CardTitle className="flex items-center gap-2">
                            <Calendar className="h-5 w-5" />
                            {escalaInfo.escala}
                          </CardTitle>
                          <CardDescription className="mt-2">
                            {escalaInfo.postos.length} posto(s) de serviço
                          </CardDescription>
                        </div>
                        {escalaInfo.turno && (
                          <Badge variant="outline">{escalaInfo.turno}</Badge>
                        )}
                      </div>
                    </CardHeader>
                    <CardContent className="space-y-4">
                      {escalaInfo.horario_inicio && escalaInfo.horario_fim && (
                        <div className="flex items-center gap-2 text-sm">
                          <Clock className="h-4 w-4 text-muted-foreground" />
                          <span>
                            {escalaInfo.horario_inicio.slice(0, 5)} às {escalaInfo.horario_fim.slice(0, 5)}
                          </span>
                        </div>
                      )}
                      
                      {escalaInfo.jornada && (
                        <div className="text-sm">
                          <span className="font-medium">Jornada:</span> {escalaInfo.jornada}
                        </div>
                      )}

                      {escalaInfo.dias_semana && escalaInfo.dias_semana.length > 0 && (
                        <div className="text-sm">
                          <span className="font-medium">Dias:</span>{" "}
                          {escalaInfo.dias_semana.join(", ")}
                        </div>
                      )}

                      <div className="pt-3 border-t">
                        <p className="text-sm font-medium mb-2">Postos de Serviço:</p>
                        <div className="space-y-2">
                          {escalaInfo.postos.map((posto: any) => (
                            <div key={posto.id} className="flex items-center gap-2 text-sm">
                              <MapPin className="h-3 w-3 text-muted-foreground" />
                              <span>
                                {posto.codigo} - {posto.nome}
                                {posto.unidade && (
                                  <span className="text-muted-foreground ml-1">
                                    ({posto.unidade.nome})
                                  </span>
                                )}
                              </span>
                            </div>
                          ))}
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            ) : (
              <Card>
                <CardContent className="py-12 text-center">
                  <Calendar className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
                  <p className="text-muted-foreground">
                    Nenhuma escala em uso. Crie postos de serviço com escalas definidas.
                  </p>
                </CardContent>
              </Card>
            )}
          </div>

          {/* Escalas Modelo */}
          <div className="space-y-4">
            <h2 className="text-2xl font-semibold">Escalas Modelo</h2>
            {escalasModelo && escalasModelo.length > 0 ? (
              <div className="grid gap-4 md:grid-cols-2">
                {escalasModelo.map((escala) => (
                  <Card key={escala.id}>
                    <CardHeader>
                      <div className="flex items-start justify-between">
                        <div>
                          <CardTitle>{escala.nome}</CardTitle>
                          {escala.descricao && (
                            <CardDescription className="mt-2">
                              {escala.descricao}
                            </CardDescription>
                          )}
                        </div>
                        <Badge variant="outline">{escala.tipo}</Badge>
                      </div>
                    </CardHeader>
                    <CardContent className="space-y-2">
                      {escala.dias_trabalhados && escala.dias_folga && (
                        <div className="text-sm">
                          <span className="font-medium">Regime:</span>{" "}
                          {escala.dias_trabalhados}x{escala.dias_folga}
                        </div>
                      )}
                      <div className="flex gap-2 pt-3">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => setEditingEscala(escala)}
                        >
                          Editar
                        </Button>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handleDelete(escala.id)}
                        >
                          Excluir
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            ) : (
              <Card>
                <CardContent className="py-12 text-center">
                  <Calendar className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
                  <p className="text-muted-foreground">
                    Nenhuma escala modelo cadastrada
                  </p>
                </CardContent>
              </Card>
            )}
          </div>
        </div>
      </div>

      {editingEscala && (
        <EscalaForm
          escala={editingEscala}
          open={!!editingEscala}
          onClose={() => setEditingEscala(null)}
          onSuccess={() => {
            setEditingEscala(null);
            refetch();
          }}
        />
      )}
    </DashboardLayout>
  );
}
