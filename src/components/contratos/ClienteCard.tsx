import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Building2, Mail, Phone, User, Trash2, Edit } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "@/hooks/use-toast";
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

interface ClienteCardProps {
  cliente: {
    id: string;
    razao_social: string;
    cnpj: string;
    contato_nome: string | null;
    contato_email: string | null;
    contato_telefone: string | null;
    status: string;
  };
  onSelect: () => void;
  onEdit: () => void;
  onDelete: () => void;
}

const ClienteCard = ({ cliente, onSelect, onEdit, onDelete }: ClienteCardProps) => {
  const handleDelete = async () => {
    try {
      // Check for related contracts
      const { data: contratos } = await supabase
        .from("contratos")
        .select("id")
        .eq("cliente_id", cliente.id)
        .limit(1);

      if (contratos && contratos.length > 0) {
        toast({
          title: "Não é possível excluir",
          description: "Este cliente possui contratos relacionados. Exclua os contratos primeiro.",
          variant: "destructive",
        });
        return;
      }

      const { error } = await supabase
        .from("clientes")
        .delete()
        .eq("id", cliente.id);

      if (error) throw error;

      toast({
        title: "Cliente excluído",
        description: "Cliente excluído com sucesso",
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

  return (
    <Card className="hover:shadow-lg transition-shadow cursor-pointer">
      <CardHeader onClick={onSelect}>
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-primary/10 rounded-lg">
              <Building2 className="h-4 w-4 text-primary" />
            </div>
            <div>
              <CardTitle className="text-base">{cliente.razao_social}</CardTitle>
              <p className="text-sm text-muted-foreground">{cliente.cnpj}</p>
            </div>
          </div>
          <Badge variant={cliente.status === "ativo" ? "default" : "secondary"}>
            {cliente.status}
          </Badge>
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-2">
          {cliente.contato_nome && (
            <div className="flex items-center gap-2 text-sm">
              <User className="h-4 w-4 text-muted-foreground" />
              <span>{cliente.contato_nome}</span>
            </div>
          )}
          {cliente.contato_email && (
            <div className="flex items-center gap-2 text-sm">
              <Mail className="h-4 w-4 text-muted-foreground" />
              <span className="truncate">{cliente.contato_email}</span>
            </div>
          )}
          {cliente.contato_telefone && (
            <div className="flex items-center gap-2 text-sm">
              <Phone className="h-4 w-4 text-muted-foreground" />
              <span>{cliente.contato_telefone}</span>
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
              <Button variant="outline" size="sm" onClick={(e) => e.stopPropagation()}>
                <Trash2 className="h-3 w-3" />
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>Confirmar exclusão</AlertDialogTitle>
                <AlertDialogDescription>
                  Tem certeza que deseja excluir este cliente? Esta ação não pode ser desfeita.
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
    </Card>
  );
};

export default ClienteCard;
