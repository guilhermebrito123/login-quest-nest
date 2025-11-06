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

  return (
    <>
      <Card 
        className="p-4 hover:shadow-lg transition-all cursor-pointer hover:border-primary/50"
        onClick={() => setShowDetails(true)}
      >
        <div className="space-y-3">
          <div className="flex items-start justify-between gap-2">
            <div className="flex-1 min-w-0">
              <span className="text-xs font-mono text-muted-foreground">{chamado.numero}</span>
              <h3 className="font-semibold line-clamp-2 mt-1">{chamado.titulo}</h3>
            </div>
          </div>

          <div className="flex flex-wrap gap-2">
            <Badge variant="outline" className={getStatusColor(chamado.status)}>
              {chamado.status?.replace("_", " ")}
            </Badge>
            <Badge variant="outline" className={getPrioridadeColor(chamado.prioridade)}>
              {chamado.prioridade}
            </Badge>
          </div>

          <div className="text-xs text-muted-foreground">
            {chamado.unidade && <div>{chamado.unidade.nome}</div>}
            <div>{format(new Date(chamado.data_abertura), "dd/MM/yyyy HH:mm", { locale: ptBR })}</div>
          </div>
        </div>
      </Card>

      {showDetails && (
        <ChamadoDetails
          chamado={chamado}
          open={showDetails}
          onOpenChange={setShowDetails}
          onEdit={onEdit}
          onDelete={onDelete}
        />
      )}
    </>
  );
}
