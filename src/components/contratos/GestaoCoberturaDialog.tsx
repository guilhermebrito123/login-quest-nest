import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Calendar } from "@/components/ui/calendar";
import { AlertCircle, Users, CalendarOff } from "lucide-react";
import { format } from "date-fns";
import { ptBR } from "date-fns/locale";
import { toast } from "@/hooks/use-toast";

interface GestaoCoberturaDialogProps {
  open: boolean;
  onClose: () => void;
}

interface PostoVago {
  id: string;
  nome: string;
  codigo: string;
  funcao: string;
  efetivo_planejado: number;
  efetivo_atual: number;
  unidade: {
    nome: string;
    codigo: string;
    contrato: {
      nome: string;
      codigo: string;
    } | null;
  };
}

interface DiaVago {
  id: string;
  data: string;
  motivo: string | null;
  posto: {
    nome: string;
    codigo: string;
    unidade: {
      nome: string;
      contrato: {
        nome: string;
        codigo: string;
      } | null;
    };
  };
  colaborador: {
    nome_completo: string;
    cargo: string;
  } | null;
}

interface ColaboradorReserva {
  id: string;
  nome_completo: string;
  cargo: string;
  funcao: string;
}

export function GestaoCoberturaDialog({ open, onClose }: GestaoCoberturaDialogProps) {
  const [loading, setLoading] = useState(true);
  const [postosVagos, setPostosVagos] = useState<PostoVago[]>([]);
  const [diasVagos, setDiasVagos] = useState<DiaVago[]>([]);
  const [colaboradoresReserva, setColaboradoresReserva] = useState<ColaboradorReserva[]>([]);
  const [filterPosto, setFilterPosto] = useState<string>("all");
  const [filterData, setFilterData] = useState<Date | undefined>(undefined);
  const [postos, setPostos] = useState<{ id: string; nome: string; codigo: string }[]>([]);

  useEffect(() => {
    if (open) {
      loadData();
    }
  }, [open]);

  const loadData = async () => {
    setLoading(true);
    try {
      await Promise.all([loadPostosVagos(), loadDiasVagos(), loadPostos(), loadColaboradoresReserva()]);
    } catch (error: any) {
      toast({
        title: "Erro ao carregar dados",
        description: error.message,
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const loadPostos = async () => {
    const { data, error } = await supabase
      .from("postos_servico")
      .select("id, nome, codigo")
      .eq("status", "ativo")
      .order("nome");

    if (error) throw error;
    setPostos(data || []);
  };

  const loadPostosVagos = async () => {
    // Get all active postos with their units
    const { data: postosData, error: postosError } = await supabase
      .from("postos_servico")
      .select(`
        id,
        nome,
        codigo,
        funcao,
        efetivo_planejado,
        unidades (
          nome,
          codigo,
          contratos (
            nome,
            codigo
          )
        )
      `)
      .eq("status", "ativo");

    if (postosError) throw postosError;

    // For each posto, count colaboradores
    const postosVagosData: PostoVago[] = [];
    
    for (const posto of postosData || []) {
      const { data: colabsData } = await supabase
        .from("colaboradores")
        .select("id")
        .eq("posto_servico_id", posto.id)
        .eq("status", "ativo");

      const efetivoAtual = colabsData?.length || 0;
      const efetivoNecessario = posto.efetivo_planejado || 1;

      if (efetivoAtual < efetivoNecessario) {
        postosVagosData.push({
          id: posto.id,
          nome: posto.nome,
          codigo: posto.codigo,
          funcao: posto.funcao,
          efetivo_planejado: efetivoNecessario,
          efetivo_atual: efetivoAtual,
          unidade: {
            nome: posto.unidades?.nome || "Sem unidade",
            codigo: posto.unidades?.codigo || "",
            contrato: posto.unidades?.contratos
              ? {
                  nome: posto.unidades.contratos.nome,
                  codigo: posto.unidades.contratos.codigo,
                }
              : null,
          },
        });
      }
    }

    setPostosVagos(postosVagosData);
  };

  const loadDiasVagos = async () => {
    const { data, error } = await supabase
      .from("posto_dias_vagos")
      .select(`
        id,
        data,
        motivo,
        postos_servico (
          nome,
          codigo,
          unidades (
            nome,
            contratos (
              nome,
              codigo
            )
          )
        ),
        colaboradores (
          nome_completo,
          cargo
        )
      `)
      .gte("data", new Date().toISOString().split("T")[0])
      .order("data");

    if (error) throw error;

    const diasVagosData: DiaVago[] = (data || []).map((item: any) => ({
      id: item.id,
      data: item.data,
      motivo: item.motivo,
      posto: {
        nome: item.postos_servico?.nome || "Desconhecido",
        codigo: item.postos_servico?.codigo || "",
        unidade: {
          nome: item.postos_servico?.unidades?.nome || "Sem unidade",
          contrato: item.postos_servico?.unidades?.contratos
            ? {
                nome: item.postos_servico.unidades.contratos.nome,
                codigo: item.postos_servico.unidades.contratos.codigo,
              }
            : null,
        },
      },
      colaborador: item.colaboradores
        ? {
            nome_completo: item.colaboradores.nome_completo,
            cargo: item.colaboradores.cargo || "Sem cargo",
          }
        : null,
    }));

    setDiasVagos(diasVagosData);
  };

  const loadColaboradoresReserva = async () => {
    const { data, error } = await supabase
      .from("colaboradores")
      .select("id, nome_completo, cargo")
      .is("posto_servico_id", null)
      .eq("status", "ativo")
      .order("nome_completo");

    if (error) throw error;

    const reservasData: ColaboradorReserva[] = (data || []).map((colab) => ({
      id: colab.id,
      nome_completo: colab.nome_completo,
      cargo: colab.cargo || "Sem cargo",
      funcao: colab.cargo || "Sem função",
    }));

    setColaboradoresReserva(reservasData);
  };

  const filteredPostosVagos = postosVagos.filter((posto) => {
    if (filterPosto !== "all" && posto.id !== filterPosto) return false;
    return true;
  });

  const filteredDiasVagos = diasVagos.filter((dia) => {
    if (filterPosto !== "all") {
      const postoMatch = postos.find((p) => p.id === filterPosto);
      if (postoMatch && dia.posto.codigo !== postoMatch.codigo) return false;
    }
    if (filterData) {
      const diaDate = new Date(dia.data);
      if (
        diaDate.getDate() !== filterData.getDate() ||
        diaDate.getMonth() !== filterData.getMonth() ||
        diaDate.getFullYear() !== filterData.getFullYear()
      ) {
        return false;
      }
    }
    return true;
  });

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-6xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-2xl flex items-center gap-2">
            <AlertCircle className="h-6 w-6 text-orange-500" />
            Gestão de Cobertura
          </DialogTitle>
          <DialogDescription>
            Monitore postos vagos e dias com ausências programadas
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* Filters */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Filtros</CardTitle>
            </CardHeader>
            <CardContent className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium mb-2 block">Posto</label>
                <Select value={filterPosto} onValueChange={setFilterPosto}>
                  <SelectTrigger>
                    <SelectValue placeholder="Todos os postos" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Todos os postos</SelectItem>
                    {postos.map((posto) => (
                      <SelectItem key={posto.id} value={posto.id}>
                        {posto.codigo} - {posto.nome}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <label className="text-sm font-medium mb-2 block">Data</label>
                <Calendar
                  mode="single"
                  selected={filterData}
                  onSelect={setFilterData}
                  className="border rounded-md"
                  locale={ptBR}
                />
              </div>
            </CardContent>
          </Card>

          {/* Postos Vagos */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Users className="h-5 w-5 text-red-500" />
                Postos Vagos ({filteredPostosVagos.length})
              </CardTitle>
              <CardDescription>
                Postos com vagas não preenchidas
              </CardDescription>
            </CardHeader>
            <CardContent>
              {loading ? (
                <p className="text-sm text-muted-foreground">Carregando...</p>
              ) : filteredPostosVagos.length === 0 ? (
                <p className="text-sm text-muted-foreground">
                  Nenhum posto vago encontrado
                </p>
              ) : (
                <div className="space-y-3">
                  {filteredPostosVagos.map((posto) => (
                    <Card key={posto.id} className="border-red-200">
                      <CardContent className="p-4">
                        <div className="flex items-start justify-between">
                          <div className="flex-1">
                            <div className="flex items-center gap-2 mb-1">
                              <h4 className="font-semibold">{posto.nome}</h4>
                              <Badge variant="outline">{posto.codigo}</Badge>
                            </div>
                            <div className="space-y-1 mb-2">
                              {posto.unidade.contrato && (
                                <p className="text-sm text-muted-foreground">
                                  <span className="font-medium">Contrato:</span> {posto.unidade.contrato.codigo} - {posto.unidade.contrato.nome}
                                </p>
                              )}
                              <p className="text-sm text-muted-foreground">
                                <span className="font-medium">Unidade:</span> {posto.unidade.nome} • {posto.funcao}
                              </p>
                            </div>
                            <div className="flex items-center gap-4">
                              <div className="text-sm">
                                <span className="text-muted-foreground">Efetivo atual: </span>
                                <span className="font-medium text-red-500">
                                  {posto.efetivo_atual}
                                </span>
                              </div>
                              <div className="text-sm">
                                <span className="text-muted-foreground">Efetivo necessário: </span>
                                <span className="font-medium">
                                  {posto.efetivo_planejado}
                                </span>
                              </div>
                              <Badge variant="destructive">
                                Faltam {posto.efetivo_planejado - posto.efetivo_atual} colaboradores
                              </Badge>
                            </div>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}

                  {/* Reservas Técnicas Disponíveis */}
                  {colaboradoresReserva.length > 0 && (
                    <div className="mt-6 pt-6 border-t">
                      <h3 className="text-lg font-semibold mb-3 flex items-center gap-2">
                        <Users className="h-5 w-5 text-green-500" />
                        Reservas Técnicas Disponíveis ({colaboradoresReserva.length})
                      </h3>
                      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                        {colaboradoresReserva.map((colab) => (
                          <Card key={colab.id} className="border-green-200">
                            <CardContent className="p-3">
                              <div>
                                <h4 className="font-semibold text-sm mb-1">
                                  {colab.nome_completo}
                                </h4>
                                <div className="flex items-center gap-2">
                                  <Badge variant="secondary" className="text-xs">
                                    {colab.cargo}
                                  </Badge>
                                  <Badge variant="outline" className="text-xs bg-green-50">
                                    Disponível
                                  </Badge>
                                </div>
                              </div>
                            </CardContent>
                          </Card>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Dias Vagos */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <CalendarOff className="h-5 w-5 text-orange-500" />
                Dias Vagos ({filteredDiasVagos.length})
              </CardTitle>
              <CardDescription>
                Dias com ausências programadas de colaboradores
              </CardDescription>
            </CardHeader>
            <CardContent>
              {loading ? (
                <p className="text-sm text-muted-foreground">Carregando...</p>
              ) : filteredDiasVagos.length === 0 ? (
                <p className="text-sm text-muted-foreground">
                  Nenhum dia vago encontrado
                </p>
              ) : (
                <div className="space-y-3">
                  {filteredDiasVagos.map((dia) => (
                    <Card key={dia.id} className="border-orange-200">
                      <CardContent className="p-4">
                        <div className="flex items-start justify-between">
                          <div className="flex-1">
                            <div className="flex items-center gap-2 mb-1">
                              <h4 className="font-semibold">
                                {format(new Date(dia.data), "dd 'de' MMMM 'de' yyyy", {
                                  locale: ptBR,
                                })}
                              </h4>
                              <Badge variant="outline">{dia.posto.codigo}</Badge>
                            </div>
                            <div className="space-y-1 mb-2">
                              {dia.posto.unidade.contrato && (
                                <p className="text-sm text-muted-foreground">
                                  <span className="font-medium">Contrato:</span> {dia.posto.unidade.contrato.codigo} - {dia.posto.unidade.contrato.nome}
                                </p>
                              )}
                              <p className="text-sm text-muted-foreground">
                                <span className="font-medium">Unidade:</span> {dia.posto.unidade.nome} • {dia.posto.nome}
                              </p>
                            </div>
                            {dia.colaborador ? (
                              <div className="space-y-1">
                                <div className="text-sm">
                                  <span className="text-muted-foreground">Colaborador: </span>
                                  <span className="font-medium">
                                    {dia.colaborador.nome_completo}
                                  </span>
                                </div>
                                <div className="text-sm">
                                  <span className="text-muted-foreground">Cargo: </span>
                                  <span className="font-medium">
                                    {dia.colaborador.cargo}
                                  </span>
                                </div>
                              </div>
                            ) : (
                              <p className="text-sm text-muted-foreground italic">
                                Sem colaborador atribuído
                              </p>
                            )}
                            {dia.motivo && (
                              <div className="mt-2 text-sm">
                                <span className="text-muted-foreground">Motivo: </span>
                                <Badge variant="secondary">
                                  {dia.motivo === 'falta_justificada' ? 'Falta Justificada' :
                                   dia.motivo === 'falta_injustificada' ? 'Falta Injustificada' :
                                   dia.motivo === 'pedido' ? 'Pedido' :
                                   dia.motivo === 'afastamento_inss' ? 'Afastamento INSS' :
                                   dia.motivo === 'folga' ? 'Folga' :
                                   dia.motivo === 'ferias' ? 'Férias' :
                                   dia.motivo === 'suspensao' ? 'Suspensão' :
                                   dia.motivo}
                                </Badge>
                              </div>
                            )}
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </DialogContent>
    </Dialog>
  );
}
