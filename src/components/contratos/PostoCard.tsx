import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Briefcase, Clock, Users, Trash2, Edit, UserCheck, UserX, Calendar as CalendarIcon } from "lucide-react";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "@/hooks/use-toast";
import { Calendar } from "@/components/ui/calendar";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
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

interface PostoCardProps {
  posto: {
    id: string;
    unidade_id: string;
    nome: string;
    codigo: string;
    funcao: string;
    status: string;
    horario_inicio?: string;
    horario_fim?: string;
    efetivo_planejado?: number;
    escala?: string;
  };
  unidade?: {
    nome: string;
  };
  onEdit: () => void;
  onDelete: () => void;
}

const PostoCard = ({ posto, unidade, onEdit, onDelete }: PostoCardProps) => {
  const [colaboradoresLotados, setColaboradoresLotados] = useState<any[]>([]);
  const [ocupacaoAtual, setOcupacaoAtual] = useState<'ocupado' | 'vago' | 'parcial'>('vago');
  const [selectedDate, setSelectedDate] = useState<Date>();
  const [calendarOpen, setCalendarOpen] = useState(false);
  const [diasConfirmados, setDiasConfirmados] = useState<Date[]>([]);
  const [diasPresenca, setDiasPresenca] = useState<Date[]>([]);
  const [diasVagos, setDiasVagos] = useState<Date[]>([]);
  const [dayActionOpen, setDayActionOpen] = useState(false);
  const [selectedDayForAction, setSelectedDayForAction] = useState<Date | null>(null);
  const [motivoVago, setMotivoVago] = useState<string>("");

  useEffect(() => {
    fetchColaboradores();
    fetchJornadaConfirmada();
    fetchDiasVagos();
    
    // Subscribe to realtime changes
    const channel = supabase
      .channel(`posto-${posto.id}-colaboradores`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'colaboradores',
          filter: `posto_servico_id=eq.${posto.id}`
        },
        () => {
          fetchColaboradores();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [posto.id]);

  const fetchDiasVagos = async () => {
    const hoje = new Date();
    const primeiroDiaMes = new Date(hoje.getFullYear(), hoje.getMonth(), 1);
    const ultimoDiaMes = new Date(hoje.getFullYear(), hoje.getMonth() + 1, 0);

    const { data, error } = await supabase
      .from("posto_dias_vagos")
      .select("data")
      .eq("posto_servico_id", posto.id)
      .gte("data", primeiroDiaMes.toISOString().split('T')[0])
      .lte("data", ultimoDiaMes.toISOString().split('T')[0]);

    if (!error && data) {
      const diasConvertidos = data.map((item) => new Date(item.data + 'T00:00:00'));
      setDiasVagos(diasConvertidos);
    }
  };

  const fetchJornadaConfirmada = async () => {
    const hoje = new Date();
    const mes = hoje.getMonth() + 1;
    const ano = hoje.getFullYear();

    const { data, error } = await supabase
      .from("posto_jornadas")
      .select("dias_trabalho")
      .eq("posto_servico_id", posto.id)
      .eq("mes", mes)
      .eq("ano", ano)
      .maybeSingle();

    if (!error && data) {
      const diasConvertidos = data.dias_trabalho.map((dia: string) => new Date(dia + 'T00:00:00'));
      setDiasConfirmados(diasConvertidos);
    }
  };

  const fetchColaboradores = async () => {
    const { data, error } = await supabase
      .from("colaboradores")
      .select("id, nome_completo, status")
      .eq("posto_servico_id", posto.id);

    if (!error && data) {
      setColaboradoresLotados(data);
      calcularOcupacao(data.length);
    }
  };

  const calcularOcupacao = (totalColaboradores: number) => {
    // Para jornada 12x36, são necessários 4 colaboradores
    let efetivoNecessario = posto.efetivo_planejado || 1;
    if (posto.escala === '12x36') {
      efetivoNecessario = 4;
      // Para 12x36, só há dois estados: vago ou ocupado (não há parcial)
      if (totalColaboradores >= efetivoNecessario) {
        setOcupacaoAtual('ocupado');
      } else {
        setOcupacaoAtual('vago');
      }
    } else {
      if (totalColaboradores === 0) {
        setOcupacaoAtual('vago');
      } else if (totalColaboradores >= efetivoNecessario) {
        setOcupacaoAtual('ocupado');
      } else {
        setOcupacaoAtual('parcial');
      }
    }
  };

  const handleDelete = async () => {
    try {
      // Check for related employees
      const { data: colaboradores } = await supabase
        .from("colaboradores")
        .select("id")
        .eq("posto_servico_id", posto.id)
        .limit(1);

      const { data: chamados } = await supabase
        .from("chamados")
        .select("id")
        .eq("posto_servico_id", posto.id)
        .limit(1);

      if (colaboradores && colaboradores.length > 0) {
        toast({
          title: "Não é possível excluir",
          description: "Este posto possui colaboradores relacionados. Remova a vinculação dos colaboradores primeiro.",
          variant: "destructive",
        });
        return;
      }

      if (chamados && chamados.length > 0) {
        toast({
          title: "Não é possível excluir",
          description: "Este posto possui chamados relacionados. Exclua os chamados primeiro.",
          variant: "destructive",
        });
        return;
      }

      const { error } = await supabase
        .from("postos_servico")
        .delete()
        .eq("id", posto.id);

      if (error) throw error;

      toast({
        title: "Posto excluído",
        description: "Posto de serviço excluído com sucesso",
      });
      onDelete();
    } catch (error: any) {
      toast({
        title: "Erro",
        description: error.message,
        variant: "destructive",
      });
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "ativo": return "default";
      case "vago": return "secondary";
      default: return "outline";
    }
  };

  const getOcupacaoColor = (ocupacao: string) => {
    switch (ocupacao) {
      case "ocupado": return "default";
      case "parcial": return "secondary";
      case "vago": return "destructive";
      default: return "outline";
    }
  };

  const getOcupacaoIcon = (ocupacao: string) => {
    switch (ocupacao) {
      case "ocupado": return <UserCheck className="h-4 w-4" />;
      case "vago": return <UserX className="h-4 w-4" />;
      default: return <Users className="h-4 w-4" />;
    }
  };

  const calcularDiasJornada = async () => {
    if (!posto.escala) return;
    
    // Validação: só pode cadastrar jornada se o posto estiver ocupado
    if (ocupacaoAtual === 'vago') {
      toast({
        title: "Posto vago",
        description: "É necessário ter colaboradores lotados no posto para cadastrar a jornada",
        variant: "destructive",
      });
      return;
    }
    
    const escalaMatch = posto.escala.match(/(\d+)x(\d+)/);
    if (!escalaMatch) return;
    
    const diasTrabalhados = parseInt(escalaMatch[1]);
    const diasFolga = parseInt(escalaMatch[2]);
    
    const hoje = new Date();
    const diasParaPreencher: Date[] = [];
    
    // Define início e fim do mês corrente
    const primeiroDiaMes = new Date(hoje.getFullYear(), hoje.getMonth(), 1);
    const ultimoDiaMes = new Date(hoje.getFullYear(), hoje.getMonth() + 1, 0);
    const totalDiasMes = ultimoDiaMes.getDate();
    
    // Jornada 5x2: Trabalha de segunda a sexta, folga fim de semana
    if (diasTrabalhados === 5 && diasFolga === 2) {
      for (let dia = 1; dia <= totalDiasMes; dia++) {
        const data = new Date(hoje.getFullYear(), hoje.getMonth(), dia);
        const diaSemana = data.getDay();
        
        // 0 = domingo, 6 = sábado - trabalha de segunda (1) a sexta (5)
        if (diaSemana >= 1 && diaSemana <= 5) {
          diasParaPreencher.push(data);
        }
      }
    }
    // Jornada 12x36: Todos os dias devem ser preenchidos
    else if (diasTrabalhados === 12 && diasFolga === 36) {
      for (let dia = 1; dia <= totalDiasMes; dia++) {
        const data = new Date(hoje.getFullYear(), hoje.getMonth(), dia);
        diasParaPreencher.push(data);
      }
    }
    // Outras escalas: lógica genérica por ciclo
    else {
      const totalCiclo = diasTrabalhados + diasFolga;
      for (let dia = 1; dia <= totalDiasMes; dia++) {
        const data = new Date(hoje.getFullYear(), hoje.getMonth(), dia);
        const diaAtual = hoje.getDate();
        
        const diferenca = dia - diaAtual;
        const posicaoNoCiclo = diferenca >= 0 ? diferenca % totalCiclo : (totalCiclo + (diferenca % totalCiclo)) % totalCiclo;
        
        if (posicaoNoCiclo < diasTrabalhados) {
          diasParaPreencher.push(data);
        }
      }
    }
    
    // Salvar no banco de dados
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error("Usuário não autenticado");

      const mes = hoje.getMonth() + 1;
      const ano = hoje.getFullYear();
      const diasFormatados = diasParaPreencher.map(d => d.toISOString().split('T')[0]);

      const { error } = await supabase
        .from("posto_jornadas")
        .upsert({
          posto_servico_id: posto.id,
          mes,
          ano,
          dias_trabalho: diasFormatados,
          created_by: user.id,
        }, {
          onConflict: 'posto_servico_id,mes,ano'
        });

      if (error) throw error;

      setDiasConfirmados(diasParaPreencher);
      toast({
        title: "Jornada confirmada",
        description: `Jornada de ${posto.escala} confirmada para ${diasParaPreencher.length} dias do mês corrente`,
      });
    } catch (error: any) {
      toast({
        title: "Erro ao salvar jornada",
        description: error.message,
        variant: "destructive",
      });
    }
  };

  const handleDayClick = (day: Date | undefined) => {
    if (day) {
      setSelectedDayForAction(day);
      setDayActionOpen(true);
    }
  };

  const handleConfirmarPresenca = async () => {
    if (!selectedDayForAction) return;
    
    try {
      // Remove from database if marked as vago
      const { error } = await supabase
        .from("posto_dias_vagos")
        .delete()
        .eq("posto_servico_id", posto.id)
        .eq("data", selectedDayForAction.toISOString().split('T')[0]);

      if (error) throw error;

      // Remove dos dias vagos se estiver lá
      setDiasVagos(prev => prev.filter(d => d.getTime() !== selectedDayForAction.getTime()));
      
      // Adiciona aos dias de presença se não estiver
      if (!diasPresenca.some(d => d.getTime() === selectedDayForAction.getTime())) {
        setDiasPresenca(prev => [...prev, selectedDayForAction]);
      }
      
      setDayActionOpen(false);
      toast({
        title: "Presença confirmada",
        description: `Presença confirmada para ${selectedDayForAction.toLocaleDateString('pt-BR')}`,
      });
    } catch (error: any) {
      toast({
        title: "Erro ao confirmar presença",
        description: error.message,
        variant: "destructive",
      });
    }
  };

  const handleMarcarVago = async () => {
    if (!selectedDayForAction || !motivoVago) {
      toast({
        title: "Motivo obrigatório",
        description: "Selecione um motivo para marcar o posto como vago",
        variant: "destructive",
      });
      return;
    }
    
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error("Usuário não autenticado");

      // Find the colaborador assigned to this posto
      const { data: colabs } = await supabase
        .from("colaboradores")
        .select("id")
        .eq("posto_servico_id", posto.id)
        .eq("status", "ativo")
        .limit(1)
        .single();

      // Save to database
      const { error } = await supabase
        .from("posto_dias_vagos")
        .insert({
          posto_servico_id: posto.id,
          colaborador_id: colabs?.id || null,
          data: selectedDayForAction.toISOString().split('T')[0],
          motivo: motivoVago,
          created_by: user.id,
        });

      if (error && !error.message.includes('duplicate key')) throw error;

      // Remove dos dias de presença se estiver lá
      setDiasPresenca(prev => prev.filter(d => d.getTime() !== selectedDayForAction.getTime()));
      
      // Adiciona aos dias vagos se não estiver
      if (!diasVagos.some(d => d.getTime() === selectedDayForAction.getTime())) {
        setDiasVagos(prev => [...prev, selectedDayForAction]);
      }
      
      setDayActionOpen(false);
      setMotivoVago("");
      toast({
        title: "Posto vago",
        description: `Posto marcado como vago para ${selectedDayForAction.toLocaleDateString('pt-BR')}`,
        variant: "destructive",
      });
    } catch (error: any) {
      toast({
        title: "Erro ao marcar dia vago",
        description: error.message,
        variant: "destructive",
      });
    }
  };

  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader>
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-primary/10 rounded-lg">
              <Briefcase className="h-4 w-4 text-primary" />
            </div>
            <div>
              <CardTitle className="text-base">{posto.nome}</CardTitle>
              <p className="text-sm text-muted-foreground">{posto.codigo}</p>
            </div>
          </div>
          <div className="flex gap-2 items-center">
            <Dialog open={calendarOpen} onOpenChange={setCalendarOpen}>
              <DialogTrigger asChild>
                <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                  <CalendarIcon className="h-4 w-4" />
                </Button>
              </DialogTrigger>
              <DialogContent className="sm:max-w-md">
                <DialogHeader>
                  <DialogTitle>Calendário - {posto.nome}</DialogTitle>
                </DialogHeader>
                <div className="space-y-4">
                  <div className="flex justify-center">
                    <Calendar
                      mode="single"
                      selected={selectedDate}
                      onSelect={handleDayClick}
                      className="rounded-md border pointer-events-auto"
                      modifiers={{
                        confirmado: diasConfirmados,
                        presenca: diasPresenca,
                        vago: diasVagos,
                      }}
                      modifiersStyles={{
                        confirmado: {
                          backgroundColor: 'hsl(var(--primary) / 0.2)',
                          color: 'hsl(var(--foreground))',
                        },
                        presenca: {
                          backgroundColor: 'hsl(142 76% 36%)',
                          color: 'white',
                          fontWeight: 'bold',
                        },
                        vago: {
                          backgroundColor: 'hsl(0 84% 60%)',
                          color: 'white',
                          fontWeight: 'bold',
                        },
                      }}
                    />
                  </div>
                  {posto.escala && (
                    <div className="space-y-2">
                      {ocupacaoAtual === 'vago' && (
                        <p className="text-sm text-destructive text-center">
                          É necessário ter colaboradores lotados para cadastrar jornada
                        </p>
                      )}
                      <div className="flex justify-center gap-2">
                        <Button 
                          onClick={calcularDiasJornada}
                          className="w-full"
                          disabled={diasConfirmados.length > 0 || ocupacaoAtual === 'vago'}
                        >
                          {diasConfirmados.length > 0 ? 'Jornada Confirmada' : 'Confirmar Jornada'}
                        </Button>
                        {diasConfirmados.length > 0 && (
                          <Button 
                            onClick={async () => {
                              try {
                                const hoje = new Date();
                                const { error } = await supabase
                                  .from("posto_jornadas")
                                  .delete()
                                  .eq("posto_servico_id", posto.id)
                                  .eq("mes", hoje.getMonth() + 1)
                                  .eq("ano", hoje.getFullYear());

                                if (error) throw error;

                                setDiasConfirmados([]);
                                toast({
                                  title: "Jornada limpa",
                                  description: "Jornada removida com sucesso",
                                });
                              } catch (error: any) {
                                toast({
                                  title: "Erro ao limpar jornada",
                                  description: error.message,
                                  variant: "destructive",
                                });
                              }
                            }}
                            variant="outline"
                          >
                            Limpar
                          </Button>
                        )}
                      </div>
                    </div>
                  )}
                </div>
              </DialogContent>
            </Dialog>
            <Badge variant={getStatusColor(posto.status)}>
              {posto.status}
            </Badge>
            <Badge variant={getOcupacaoColor(ocupacaoAtual)} className="flex items-center gap-1">
              {getOcupacaoIcon(ocupacaoAtual)}
              {ocupacaoAtual}
            </Badge>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-2">
          {unidade && (
            <p className="text-sm text-muted-foreground">
              Unidade: {unidade.nome}
            </p>
          )}
          <div className="flex items-center gap-2 text-sm">
            <Users className="h-4 w-4 text-muted-foreground" />
            <span>{posto.funcao}</span>
          </div>
          {posto.escala && (
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <Briefcase className="h-4 w-4" />
              <span>Escala: {posto.escala}</span>
            </div>
          )}
          <div className="flex items-center justify-between text-sm pt-2 border-t">
            <span className="text-muted-foreground">Colaboradores lotados:</span>
            <span className="font-semibold">
              {colaboradoresLotados.length}/{posto.escala === '12x36' ? 4 : (posto.efetivo_planejado || 1)}
            </span>
          </div>
          {posto.horario_inicio && posto.horario_fim && (
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <Clock className="h-4 w-4" />
              <span>{posto.horario_inicio} - {posto.horario_fim}</span>
            </div>
          )}
        </div>

        <div className="flex gap-2 mt-4">
          <Button variant="outline" size="sm" className="flex-1" onClick={onEdit}>
            <Edit className="h-3 w-3 mr-1" />
            Editar
          </Button>
          <AlertDialog>
            <AlertDialogTrigger asChild>
              <Button variant="outline" size="sm">
                <Trash2 className="h-3 w-3" />
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>Confirmar exclusão</AlertDialogTitle>
                <AlertDialogDescription>
                  Tem certeza que deseja excluir este posto? Esta ação não pode ser desfeita.
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>Cancelar</AlertDialogCancel>
                <AlertDialogAction onClick={handleDelete}>Excluir</AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
        </div>
      </CardContent>

      <Dialog open={dayActionOpen} onOpenChange={setDayActionOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>
              {selectedDayForAction && `Marcar dia ${selectedDayForAction.toLocaleDateString('pt-BR')}`}
            </DialogTitle>
          </DialogHeader>
          <div className="flex flex-col gap-4">
            <Button 
              onClick={handleConfirmarPresenca}
              className="w-full bg-green-600 hover:bg-green-700"
            >
              <UserCheck className="h-4 w-4 mr-2" />
              Confirmar Presença
            </Button>
            
            <div className="space-y-2">
              <Label htmlFor="motivo">Motivo da Ausência</Label>
              <Select value={motivoVago} onValueChange={setMotivoVago}>
                <SelectTrigger id="motivo">
                  <SelectValue placeholder="Selecione o motivo" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="falta_justificada">Falta Justificada</SelectItem>
                  <SelectItem value="falta_injustificada">Falta Injustificada</SelectItem>
                  <SelectItem value="pedido">Pedido</SelectItem>
                  <SelectItem value="afastamento_inss">Afastamento INSS</SelectItem>
                  <SelectItem value="folga">Folga</SelectItem>
                  <SelectItem value="ferias">Férias</SelectItem>
                  <SelectItem value="suspensao">Suspensão</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            <Button 
              onClick={handleMarcarVago}
              variant="destructive"
              className="w-full"
              disabled={!motivoVago}
            >
              <UserX className="h-4 w-4 mr-2" />
              Posto Vago
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </Card>
  );
};

export default PostoCard;
