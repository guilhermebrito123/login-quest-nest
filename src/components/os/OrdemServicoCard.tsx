import { useState } from "react";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Pencil, Trash2, Eye, Calendar, User, MapPin, Clock, CheckCircle2 } from "lucide-react";
import { OrdemServicoDetails } from "./OrdemServicoDetails";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

interface OrdemServicoCardProps {
  os: any;
  onEdit: (os: any) => void;
  onDelete: (id: string) => void;
  onConcluir: (id: string) => void;
}

export function OrdemServicoCard({ os, onEdit, onDelete, onConcluir }: OrdemServicoCardProps) {
  const [showDetails, setShowDetails] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [showConcluirDialog, setShowConcluirDialog] = useState(false);

  const getStatusColor = (status: string) => {
    switch (status) {
      case "aberta": return "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-100";
      case "em_andamento": return "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-100";
      case "concluida": return "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-100";
      case "cancelada": return "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-100";
      default: return "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-100";
    }
  };

  const getPrioridadeColor = (prioridade: string) => {
    switch (prioridade) {
      case "baixa": return "bg-gray-100 text-gray-800";
      case "media": return "bg-blue-100 text-blue-800";
      case "alta": return "bg-orange-100 text-orange-800";
      case "urgente": return "bg-red-100 text-red-800";
      default: return "bg-gray-100 text-gray-800";
    }
  };

  const getTipoColor = (tipo: string) => {
    switch (tipo) {
      case "preventiva": return "bg-green-100 text-green-800";
      case "corretiva": return "bg-yellow-100 text-yellow-800";
      case "emergencial": return "bg-red-100 text-red-800";
      case "melhoria": return "bg-purple-100 text-purple-800";
      default: return "bg-gray-100 text-gray-800";
    }
  };

  const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString("pt-BR");
  };

  return (
    <>
      <Card className="hover:shadow-md transition-shadow">
        <CardHeader className="pb-3">
          <div className="flex items-start justify-between">
            <div className="space-y-1 flex-1">
              <div className="flex items-center gap-2">
                <span className="font-mono text-sm text-muted-foreground">{os.numero}</span>
                <Badge className={getTipoColor(os.tipo)}>{os.tipo}</Badge>
                <Badge className={getPrioridadeColor(os.prioridade)}>{os.prioridade}</Badge>
                <Badge className={getStatusColor(os.status)}>{os.status.replace("_", " ")}</Badge>
              </div>
              <h3 className="text-lg font-semibold">{os.titulo}</h3>
            </div>
            <div className="flex gap-1">
              <Button variant="ghost" size="icon" onClick={() => setShowDetails(true)}>
                <Eye className="h-4 w-4" />
              </Button>
              {os.status !== "concluida" && (
                <>
                  <Button 
                    variant="ghost" 
                    size="icon" 
                    onClick={() => setShowConcluirDialog(true)}
                    className="text-green-600 hover:text-green-700 hover:bg-green-50"
                  >
                    <CheckCircle2 className="h-4 w-4" />
                  </Button>
                  <Button variant="ghost" size="icon" onClick={() => onEdit(os)}>
                    <Pencil className="h-4 w-4" />
                  </Button>
                </>
              )}
              <Button variant="ghost" size="icon" onClick={() => setShowDeleteDialog(true)}>
                <Trash2 className="h-4 w-4 text-destructive" />
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {os.descricao && (
            <p className="text-sm text-muted-foreground mb-3 line-clamp-2">{os.descricao}</p>
          )}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
            {os.unidade?.nome && (
              <div className="flex items-center gap-2">
                <MapPin className="h-4 w-4 text-muted-foreground" />
                <span className="truncate">{os.unidade.nome}</span>
              </div>
            )}
            {os.responsavel?.full_name && (
              <div className="flex items-center gap-2">
                <User className="h-4 w-4 text-muted-foreground" />
                <span className="truncate">{os.responsavel.full_name}</span>
              </div>
            )}
            {os.data_abertura && (
              <div className="flex items-center gap-2">
                <Clock className="h-4 w-4 text-muted-foreground" />
                <span>{formatDate(os.data_abertura)}</span>
              </div>
            )}
            {os.data_prevista && (
              <div className="flex items-center gap-2">
                <Calendar className="h-4 w-4 text-muted-foreground" />
                <span>{formatDate(os.data_prevista)}</span>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {showDetails && (
        <OrdemServicoDetails
          os={os}
          open={showDetails}
          onClose={() => setShowDetails(false)}
        />
      )}

      <AlertDialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Confirmar exclusão</AlertDialogTitle>
            <AlertDialogDescription>
              Tem certeza que deseja excluir a OS {os.numero}? Esta ação não pode ser desfeita.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction onClick={() => onDelete(os.id)} className="bg-destructive text-destructive-foreground">
              Excluir
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <AlertDialog open={showConcluirDialog} onOpenChange={setShowConcluirDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Concluir Ordem de Serviço</AlertDialogTitle>
            <AlertDialogDescription>
              Tem certeza que deseja concluir a OS {os.numero}? Esta ação marcará a ordem como concluída.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction 
              onClick={() => onConcluir(os.id)} 
              className="bg-green-600 hover:bg-green-700"
            >
              Concluir
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}