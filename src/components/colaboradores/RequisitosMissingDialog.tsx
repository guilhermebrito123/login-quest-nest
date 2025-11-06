import { AlertDialog, AlertDialogAction, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from "@/components/ui/alert-dialog";
import { AlertTriangle } from "lucide-react";

interface RequisitosMissingDialogProps {
  open: boolean;
  onClose: () => void;
  missingEntities: string[];
}

export function RequisitosMissingDialog({ open, onClose, missingEntities }: RequisitosMissingDialogProps) {
  return (
    <AlertDialog open={open} onOpenChange={onClose}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <div className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-destructive" />
            <AlertDialogTitle>Requisitos Não Atendidos</AlertDialogTitle>
          </div>
          <AlertDialogDescription className="space-y-3">
            <p>
              Para cadastrar um colaborador, é necessário ter pelo menos uma instância cadastrada de cada uma das seguintes entidades:
            </p>
            <div className="bg-muted p-3 rounded-md">
              <p className="font-medium mb-2">Entidades faltantes:</p>
              <ul className="list-disc list-inside space-y-1">
                {missingEntities.map((entity) => (
                  <li key={entity} className="text-sm">{entity}</li>
                ))}
              </ul>
            </div>
            <p className="text-sm">
              Por favor, cadastre as entidades necessárias antes de adicionar colaboradores.
            </p>
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogAction onClick={onClose}>Entendi</AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
