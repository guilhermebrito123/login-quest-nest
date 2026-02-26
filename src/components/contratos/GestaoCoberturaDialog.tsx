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
  funcao: string;
  efetivo_planejado: number;
  efetivo_atual: number;
  unidade: {
    nome: string;
    contrato: {
      negocio: string;
      conq_perd: number;
    } | null;
  };
}

interface DiaVago {
  id: string;
  data: string;
  motivo: string | null;
  posto: {
    nome: string;
    unidade: {
      nome: string;
      contrato: {
        negocio: string;
        conq_perd: number;
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

interface Diarista {
  id: string;
  nome_completo: string;
  telefone: string;
  cidade: string | null;
}

export function GestaoCoberturaDialog({ open, onClose }: GestaoCoberturaDialogProps) {
  const [loading, setLoading] = useState(true);
  const [postosVagos, setPostosVagos] = useState<PostoVago[]>([]);
  const [diasVagos, setDiasVagos] = useState<DiaVago[]>([]);
  const [colaboradoresReserva, setColaboradoresReserva] = useState<ColaboradorReserva[]>([]);
  const [diaristas, setDiaristas] = useState<Diarista[]>([]);
  const [filterPosto, setFilterPosto] = useState<string>("all");
  const [filterData, setFilterData] = useState<Date | undefined>(undefined);
  const [postos, setPostos] = useState<{ id: string; nome: string }[]>([]);

  useEffect(() => {
    if (open) {
      loadData();
    }
  }, [open]);

  const loadData = async () => {
    setLoading(true);
    try {
      await Promise.all([loadPostosVagos(), loadDiasVagos(), loadPostos(), loadColaboradoresReserva(), loadDiaristas()]);
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
      .select("id, nome")
      .in("status", ["ocupado", "ocupado_temporariamente"])
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
        funcao,
        escala,
        unidades (
          nome,
          contratos (
            negocio,
            conq_perd
          )
        )
      `)
      .in("status", ["ocupado", "ocupado_temporariamente"]);

    if (postosError) throw postosError;

    // For each posto, count colaboradores
    const postosVagosData: PostoVago[] = [];
    
    for (const posto of postosData || []) {
      const { data: colabsData } = await supabase
        .from("colaboradores")
        .select("id")
        .eq("posto_servico_id", posto.id)
        .eq("status_colaborador", "ativo");

      const efetivoAtual = colabsData?.length || 0;
      // Para jornada 12x36, são necessários 4 colaboradores
      const efetivoNecessario = posto.escala === '12x36' ? 4 : 1;

      if (efetivoAtual < efetivoNecessario) {
        postosVagosData.push({
          id: posto.id,
          nome: posto.nome,
          funcao: posto.funcao,
          efetivo_planejado: efetivoNecessario,
          efetivo_atual: efetivoAtual,
          unidade: {
            nome: posto.unidades?.nome || "Sem unidade",
            contrato: posto.unidades?.contratos
              ? {
                  negocio: posto.unidades.contratos.negocio,
                  conq_perd: posto.unidades.contratos.conq_perd,
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
        unidade: {
          nome: item.postos_servico?.unidades?.nome || "Sem unidade",
          contrato: item.postos_servico?.unidades?.contratos
            ? {
                negocio: item.postos_servico.unidades.contratos.negocio,
                conq_perd: item.postos_servico.unidades.contratos.conq_perd,
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
      .eq("status_colaborador", "ativo")
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

  const loadDiaristas = async () => {
    const { data, error } = await supabase
      .from("diaristas")
      .select("id, nome_completo, telefone, cidade")
      .eq("status", "ativo")
      .order("nome_completo");

    if (error) throw error;

    setDiaristas(data || []);
  };

  const filteredPostosVagos = postosVagos.filter((posto) => {
    if (filterPosto !== "all" && posto.id !== filterPosto) return false;
    return true;
  });

  const filteredDiasVagos = diasVagos.filter((dia) => {
    if (filterPosto !== "all") {
      const postoMatch = postos.find((p) => p.id === filterPosto);
      if (postoMatch && dia.posto.nome !== postoMatch.nome) return false;
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
                        {posto.nome}
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
                            </div>
                            <div className="space-y-1 mb-2">
                              {posto.unidade.contrato && (
                                <p className="text-sm text-muted-foreground">
                                  <span className="font-medium">Contrato:</span> {posto.unidade.contrato.negocio} (Ano: {posto.unidade.contrato.conq_perd})
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
                            </div>
                            <div className="space-y-1 mb-2">
                              {dia.posto.unidade.contrato && (
                                <p className="text-sm text-muted-foreground">
                                  <span className="font-medium">Contrato:</span> {dia.posto.unidade.contrato.negocio} (Ano: {dia.posto.unidade.contrato.conq_perd})
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
                                   {dia.motivo === 'DIÁRIA - FALTA ATESTADO' ? 'Falta Atestado' :
                                    dia.motivo === 'DIÁRIA - FALTA' ? 'Falta' :
                                    dia.motivo === 'DIÁRIA - SALÁRIO' ? 'Salário' :
                                    dia.motivo === 'AFASTAMENTO INSS' ? 'Afastamento INSS' :
                                    dia.motivo === 'DIÁRIA - FÉRIAS' ? 'Férias' :
                                    dia.motivo === 'SUSPENSÃO' ? 'Suspensão' :
                                    dia.motivo === 'LICENÇA MATERNIDADE' ? 'Licença Maternidade' :
                                    dia.motivo === 'LICENÇA PATERNIDADE' ? 'Licença Paternidade' :
                                    dia.motivo === 'LICENÇA CASAMENTO' ? 'Licença Casamento' :
                                    dia.motivo === 'LICENÇA NOJO (FALECIMENTO)' ? 'Licença Nojo' :
                                    dia.motivo === 'DIÁRIA - DEMANDA EXTRA' ? 'Demanda Extra' :
                                    dia.motivo === 'DIÁRIA - BÔNUS' ? 'Bônus' :
                                    dia.motivo}
                                </Badge>
                              </div>
                            )}
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}

                  {/* Diaristas Disponíveis */}
                  {diaristas.length > 0 && (
                    <div className="mt-6 pt-6 border-t">
                      <h3 className="text-lg font-semibold mb-3 flex items-center gap-2">
                        <Users className="h-5 w-5 text-blue-500" />
                        Diaristas Disponíveis ({diaristas.length})
                      </h3>
                      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                        {diaristas.map((diarista) => (
                          <Card key={diarista.id} className="border-blue-200">
                            <CardContent className="p-3">
                              <div>
                                <h4 className="font-semibold text-sm mb-2">
                                  {diarista.nome_completo}
                                </h4>
                                <div className="space-y-1">
                                  <div className="flex items-center gap-2 text-xs">
                                    <span className="text-muted-foreground">Telefone:</span>
                                    <span className="font-medium">{diarista.telefone}</span>
                                  </div>
                                  <div className="flex items-center gap-2 text-xs">
                                    <span className="text-muted-foreground">Cidade:</span>
                                    <span className="font-medium">{diarista.cidade || "Não informada"}</span>
                                  </div>
                                </div>
                                <Badge variant="outline" className="text-xs bg-blue-50 mt-2">
                                  Diarista
                                </Badge>
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
        </div>
      </DialogContent>
    </Dialog>
  );
}
