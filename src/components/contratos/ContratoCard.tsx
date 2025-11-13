import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { FileText, Calendar, TrendingUp, Trash2, Edit } from "lucide-react";
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
import { format } from "date-fns";

interface ContratoCardProps {
  contrato: {
    id: string;
    cliente_id: string;
    nome: string;
    codigo: string;
    data_inicio: string;
    data_fim: string | null;
    sla_alvo_pct: number;
    nps_meta: number | null;
    status: string;
  };
  cliente?: {
    razao_social: string;
  };
  onSelect: () => void;
  onEdit: () => void;
  onDelete: () => void;
}

const ContratoCard = ({ contrato, cliente, onSelect, onEdit, onDelete }: ContratoCardProps) => {
  const handleDelete = async () => {
    try {
      // Check for related records
      const { data: chamados } = await supabase
        .from("chamados")
        .select("id")
        .eq("contrato_id", contrato.id)
        .limit(1);

      const { data: unidades } = await supabase
        .from("unidades")
        .select("id")
        .eq("contrato_id", contrato.id)
        .limit(1);

      if (chamados && chamados.length > 0) {
        toast({
          title: "Não é possível excluir",
          description: "Este contrato possui chamados relacionados. Exclua os chamados primeiro.",
          variant: "destructive",
        });
        return;
      }

      if (unidades && unidades.length > 0) {
        toast({
          title: "Não é possível excluir",
          description: "Este contrato possui unidades relacionadas. Exclua as unidades primeiro.",
          variant: "destructive",
        });
        return;
      }

      const { error } = await supabase
        .from("contratos")
        .delete()
        .eq("id", contrato.id);

      if (error) throw error;

      toast({
        title: "Contrato excluído",
        description: "Contrato excluído com sucesso",
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
              <FileText className="h-4 w-4 text-primary" />
            </div>
            <div>
              <CardTitle className="text-base">{contrato.nome}</CardTitle>
              <p className="text-sm text-muted-foreground">{contrato.codigo}</p>
            </div>
          </div>
          <Badge variant={contrato.status === "ativo" ? "default" : "secondary"}>
            {contrato.status}
          </Badge>
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-2">
          {cliente && (
            <p className="text-sm text-muted-foreground">
              Cliente: {cliente.razao_social}
            </p>
          )}
          <div className="flex items-center gap-2 text-sm">
            <Calendar className="h-4 w-4 text-muted-foreground" />
            <span>
              {format(new Date(contrato.data_inicio), "dd/MM/yyyy")}
              {contrato.data_fim && ` - ${format(new Date(contrato.data_fim), "dd/MM/yyyy")}`}
            </span>
          </div>
          <div className="flex items-center gap-2 text-sm">
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
            <span>SLA: {contrato.sla_alvo_pct}%</span>
            {contrato.nps_meta && <span>• NPS: {contrato.nps_meta}</span>}
          </div>
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
                  Tem certeza que deseja excluir este contrato? Esta ação não pode ser desfeita.
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

export default ContratoCard;
