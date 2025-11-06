import { useState } from "react";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Pencil, Trash2, Mail, Phone, Briefcase, MapPin, Calendar, CalendarCheck, Clock, ChevronDown, ChevronUp } from "lucide-react";
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

interface ColaboradorCardProps {
  colaborador: any;
  onEdit: (colaborador: any) => void;
  onDelete: (id: string) => void;
  onPresenca: (colaborador: any) => void;
  onEscala: (colaborador: any) => void;
  onUnidade: (colaborador: any) => void;
}

export function ColaboradorCard({ colaborador, onEdit, onDelete, onPresenca, onEscala, onUnidade }: ColaboradorCardProps) {
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [showDetails, setShowDetails] = useState(false);

  const getStatusColor = (status: string) => {
    switch (status) {
      case "ativo": return "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-100";
      case "inativo": return "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-100";
      case "ferias": return "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-100";
      case "afastado": return "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-100";
      default: return "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-100";
    }
  };

  const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString("pt-BR");
  };

  return (
    <>
      <Card className="hover:shadow-md transition-shadow">
        <CardHeader className="pb-3">
          <div className="flex items-start justify-between gap-4">
            <div className="space-y-1 flex-1">
              <div className="flex items-center gap-2 flex-wrap">
                <h3 className="text-lg font-semibold">{colaborador.nome_completo}</h3>
                <Badge className={getStatusColor(colaborador.status)}>{colaborador.status}</Badge>
                {colaborador.cargo && (
                  <Badge variant="outline">{colaborador.cargo}</Badge>
                )}
              </div>
            </div>
            <div className="flex gap-1 flex-shrink-0">
              {colaborador.status === "ativo" && (
                <>
                  <Button variant="ghost" size="icon" onClick={() => onPresenca(colaborador)} title="Registrar Presença">
                    <CalendarCheck className="h-4 w-4" />
                  </Button>
                  <Button 
                    variant="ghost" 
                    size="icon" 
                    onClick={() => onEscala(colaborador)} 
                    title={colaborador.escala_id ? "Alterar Escala" : "Atribuir Escala"}
                  >
                    <Clock className="h-4 w-4" />
                  </Button>
                </>
              )}
              <Button 
                variant="ghost" 
                size="icon" 
                onClick={() => onUnidade(colaborador)} 
                title={colaborador.unidade_id ? "Alterar Unidade" : "Atribuir Unidade"}
              >
                <MapPin className="h-4 w-4" />
              </Button>
              <Button variant="ghost" size="icon" onClick={() => setShowDetails(!showDetails)}>
                {showDetails ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
              </Button>
              <Button variant="ghost" size="icon" onClick={() => onEdit(colaborador)}>
                <Pencil className="h-4 w-4" />
              </Button>
              <Button variant="ghost" size="icon" onClick={() => setShowDeleteDialog(true)}>
                <Trash2 className="h-4 w-4 text-destructive" />
              </Button>
            </div>
          </div>
        </CardHeader>
        
        {showDetails && (
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
              {colaborador.cpf && (
                <div className="flex items-center gap-2">
                  <span className="font-medium">CPF:</span>
                  <span>{colaborador.cpf}</span>
                </div>
              )}
              {colaborador.email && (
                <div className="flex items-center gap-2">
                  <Mail className="h-4 w-4 text-muted-foreground" />
                  <span className="truncate">{colaborador.email}</span>
                </div>
              )}
              {colaborador.telefone && (
                <div className="flex items-center gap-2">
                  <Phone className="h-4 w-4 text-muted-foreground" />
                  <span>{colaborador.telefone}</span>
                </div>
              )}
              {colaborador.unidade?.nome && (
                <div className="flex items-center gap-2">
                  <MapPin className="h-4 w-4 text-muted-foreground" />
                  <span className="truncate">{colaborador.unidade.nome}</span>
                </div>
              )}
              {colaborador.data_admissao && (
                <div className="flex items-center gap-2">
                  <Calendar className="h-4 w-4 text-muted-foreground" />
                  <span>{formatDate(colaborador.data_admissao)}</span>
                </div>
              )}
              {colaborador.posto?.nome && (
                <div className="flex items-center gap-2">
                  <Briefcase className="h-4 w-4 text-muted-foreground" />
                  <span>{colaborador.posto.codigo} - {colaborador.posto.nome}</span>
                </div>
              )}
              {colaborador.escala && (
                <div className="flex items-center gap-2">
                  <Clock className="h-4 w-4 text-muted-foreground" />
                  <span>{colaborador.escala.nome} ({colaborador.escala.tipo})</span>
                </div>
              )}
            </div>
          </CardContent>
        )}
      </Card>

      <AlertDialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Confirmar exclusão</AlertDialogTitle>
            <AlertDialogDescription>
              Tem certeza que deseja excluir o colaborador {colaborador.nome_completo}? Esta ação não pode ser desfeita.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction onClick={() => onDelete(colaborador.id)} className="bg-destructive text-destructive-foreground">
              Excluir
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}