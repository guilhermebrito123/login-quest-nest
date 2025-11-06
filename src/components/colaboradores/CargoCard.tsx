import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Pencil, Trash2, Shield, ChevronDown, ChevronUp } from "lucide-react";
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

interface CargoCardProps {
  cargo: {
    id: string;
    nome: string;
    descricao?: string;
    is_lideranca?: boolean;
  };
  onEdit: (cargo: any) => void;
  onDelete: (id: string) => void;
}

export function CargoCard({ cargo, onEdit, onDelete }: CargoCardProps) {
  const [showDetails, setShowDetails] = useState(false);

  return (
    <Card className="overflow-hidden">
      <CardHeader className="pb-3">
        <div className="flex items-start justify-between gap-2">
          <div className="space-y-2 flex-1 min-w-0">
            <CardTitle className="text-lg truncate">{cargo.nome}</CardTitle>
            {cargo.is_lideranca && (
              <Badge variant="secondary" className="gap-1 w-fit">
                <Shield className="h-3 w-3" />
                Liderança
              </Badge>
            )}
          </div>
          <div className="flex gap-1 flex-shrink-0">
            {cargo.descricao && (
              <Button
                variant="ghost"
                size="icon"
                onClick={() => setShowDetails(!showDetails)}
                title="Ver detalhes"
              >
                {showDetails ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
              </Button>
            )}
            <Button
              variant="ghost"
              size="icon"
              onClick={() => onEdit(cargo)}
              title="Editar"
            >
              <Pencil className="h-4 w-4" />
            </Button>
            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button variant="ghost" size="icon" title="Excluir">
                  <Trash2 className="h-4 w-4 text-destructive" />
                </Button>
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>Confirmar exclusão</AlertDialogTitle>
                  <AlertDialogDescription>
                    Tem certeza que deseja excluir o cargo "{cargo.nome}"? Esta ação não pode ser desfeita.
                  </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                  <AlertDialogCancel>Cancelar</AlertDialogCancel>
                  <AlertDialogAction onClick={() => onDelete(cargo.id)} className="bg-destructive text-destructive-foreground">
                    Excluir
                  </AlertDialogAction>
                </AlertDialogFooter>
              </AlertDialogContent>
            </AlertDialog>
          </div>
        </div>
      </CardHeader>
      {showDetails && cargo.descricao && (
        <CardContent className="pt-0">
          <p className="text-sm text-muted-foreground break-words">{cargo.descricao}</p>
        </CardContent>
      )}
    </Card>
  );
}
