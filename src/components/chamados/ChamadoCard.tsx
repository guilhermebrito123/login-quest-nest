import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Edit, Trash2, Eye, Clock, AlertTriangle } from "lucide-react";
import { format, differenceInHours } from "date-fns";
import { ptBR } from "date-fns/locale";
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
import { useState } from "react";
import { ChamadoDetails } from "./ChamadoDetails";

interface ChamadoCardProps {
  chamado: any;
  onEdit: (chamado: any) => void;
  onDelete: (id: string) => void;
}

export function ChamadoCard({ chamado, onEdit, onDelete }: ChamadoCardProps) {
  const [showDetails, setShowDetails] = useState(false);

  const getStatusColor = (status: string) => {
    const colors = {
      aberto: "bg-yellow-500/10 text-yellow-600 border-yellow-500/20",
      em_andamento: "bg-blue-500/10 text-blue-600 border-blue-500/20",
      pendente: "bg-orange-500/10 text-orange-600 border-orange-500/20",
      concluido: "bg-green-500/10 text-green-600 border-green-500/20",
    };
    return colors[status as keyof typeof colors] || "";
  };

  const getPrioridadeColor = (prioridade: string) => {
    const colors = {
      baixa: "bg-gray-500/10 text-gray-600 border-gray-500/20",
      media: "bg-blue-500/10 text-blue-600 border-blue-500/20",
      alta: "bg-orange-500/10 text-orange-600 border-orange-500/20",
      critica: "bg-red-500/10 text-red-600 border-red-500/20",
    };
    return colors[prioridade as keyof typeof colors] || "";
  };

  const getCategoriaLabel = (categoria: string) => {
    const labels = {
      manutencao: "Manutenção",
      rh: "RH",
      suprimentos: "Suprimentos",
      atendimento: "Atendimento",
    };
    return labels[categoria as keyof typeof labels] || categoria;
  };

  const calculateSLAStatus = () => {
    if (!chamado.sla_horas || chamado.status === "concluido") return null;
    
    const horasDecorridas = differenceInHours(new Date(), new Date(chamado.data_abertura));
    const percentualSLA = (horasDecorridas / chamado.sla_horas) * 100;
    
    if (percentualSLA >= 100) {
      return { color: "text-red-600", icon: AlertTriangle, label: "SLA Estourado" };
    } else if (percentualSLA >= 80) {
      return { color: "text-orange-600", icon: Clock, label: "SLA Próximo" };
    }
    return null;
  };

  const slaStatus = calculateSLAStatus();

  return (
    <>
      <Card className="p-4 hover:shadow-lg transition-shadow">
        <div className="space-y-3">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-1">
                <span className="text-sm font-mono text-muted-foreground">{chamado.numero}</span>
                {slaStatus && (
                  <Badge variant="outline" className={slaStatus.color}>
                    <slaStatus.icon className="mr-1 h-3 w-3" />
                    {slaStatus.label}
                  </Badge>
                )}
              </div>
              <h3 className="font-semibold line-clamp-1">{chamado.titulo}</h3>
            </div>
          </div>

          <div className="flex flex-wrap gap-2">
            <Badge variant="outline" className={getStatusColor(chamado.status)}>
              {chamado.status?.replace("_", " ")}
            </Badge>
            <Badge variant="outline" className={getPrioridadeColor(chamado.prioridade)}>
              {chamado.prioridade}
            </Badge>
            {chamado.categoria && (
              <Badge variant="outline">
                {getCategoriaLabel(chamado.categoria)}
              </Badge>
            )}
          </div>

          {chamado.descricao && (
            <p className="text-sm text-muted-foreground line-clamp-2">
              {chamado.descricao}
            </p>
          )}

          <div className="space-y-1 text-xs text-muted-foreground">
            {chamado.unidade && (
              <div>Unidade: {chamado.unidade.nome}</div>
            )}
            {chamado.posto_servico && (
              <div>Posto: {chamado.posto_servico.nome}</div>
            )}
            {chamado.solicitante && (
              <div>Solicitante: {chamado.solicitante.nome_completo}</div>
            )}
            {chamado.atribuido && (
              <div>Atribuído: {chamado.atribuido.nome_completo}</div>
            )}
            <div>Aberto em: {format(new Date(chamado.data_abertura), "dd/MM/yyyy HH:mm", { locale: ptBR })}</div>
            {chamado.sla_horas && (
              <div>SLA: {chamado.sla_horas}h</div>
            )}
          </div>

          <div className="flex gap-2 pt-2 border-t">
            <Button
              variant="ghost"
              size="sm"
              className="flex-1"
              onClick={() => setShowDetails(true)}
            >
              <Eye className="mr-2 h-4 w-4" />
              Detalhes
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => onEdit(chamado)}
            >
              <Edit className="h-4 w-4" />
            </Button>
            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button variant="ghost" size="sm">
                  <Trash2 className="h-4 w-4 text-destructive" />
                </Button>
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>Confirmar exclusão</AlertDialogTitle>
                  <AlertDialogDescription>
                    Tem certeza que deseja excluir este chamado? Esta ação não pode ser desfeita.
                  </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                  <AlertDialogCancel>Cancelar</AlertDialogCancel>
                  <AlertDialogAction onClick={() => onDelete(chamado.id)}>
                    Excluir
                  </AlertDialogAction>
                </AlertDialogFooter>
              </AlertDialogContent>
            </AlertDialog>
          </div>
        </div>
      </Card>

      {showDetails && (
        <ChamadoDetails
          chamado={chamado}
          open={showDetails}
          onOpenChange={setShowDetails}
        />
      )}
    </>
  );
}
