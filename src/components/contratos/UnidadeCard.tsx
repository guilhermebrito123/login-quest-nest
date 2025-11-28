import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { MapPin, AlertCircle, Trash2, Edit } from "lucide-react";
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

interface UnidadeCardProps {
  unidade: {
    id: string;
    contrato_id: string;
    nome: string;
    codigo: string;
    endereco: string | null;
    cidade: string | null;
    uf: string | null;
    criticidade: string;
    status: string;
  };
  contrato?: {
    negocio: string;
  };
  onSelect: () => void;
  onEdit: () => void;
  onDelete: () => void;
}

const UnidadeCard = ({ unidade, contrato, onSelect, onEdit, onDelete }: UnidadeCardProps) => {
  const handleDelete = async () => {
    try {
      // Check for related records
      const { data: postos } = await supabase
        .from("postos_servico")
        .select("id")
        .eq("unidade_id", unidade.id)
        .limit(1);

      const { data: colaboradores } = await supabase
        .from("colaboradores")
        .select("id")
        .eq("unidade_id", unidade.id)
        .limit(1);

      const { data: chamados } = await supabase
        .from("chamados")
        .select("id")
        .eq("unidade_id", unidade.id)
        .limit(1);

      const { data: ordens } = await supabase
        .from("ordens_servico")
        .select("id")
        .eq("unidade_id", unidade.id)
        .limit(1);

      if (postos && postos.length > 0) {
        toast({
          title: "Não é possível excluir",
          description: "Esta unidade possui postos de serviço relacionados. Exclua os postos primeiro.",
          variant: "destructive",
        });
        return;
      }

      if (colaboradores && colaboradores.length > 0) {
        toast({
          title: "Não é possível excluir",
          description: "Esta unidade possui colaboradores relacionados. Remova a vinculação dos colaboradores primeiro.",
          variant: "destructive",
        });
        return;
      }

      if (chamados && chamados.length > 0) {
        toast({
          title: "Não é possível excluir",
          description: "Esta unidade possui chamados relacionados. Exclua os chamados primeiro.",
          variant: "destructive",
        });
        return;
      }

      if (ordens && ordens.length > 0) {
        toast({
          title: "Não é possível excluir",
          description: "Esta unidade possui ordens de serviço relacionadas. Exclua as ordens primeiro.",
          variant: "destructive",
        });
        return;
      }

      const { error } = await supabase
        .from("unidades")
        .delete()
        .eq("id", unidade.id);

      if (error) throw error;

      toast({
        title: "Unidade excluída",
        description: "Unidade excluída com sucesso",
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

  const getCriticidadeColor = (criticidade: string) => {
    switch (criticidade) {
      case "critica": return "destructive";
      case "alta": return "default";
      case "media": return "secondary";
      default: return "outline";
    }
  };

  return (
    <Card className="hover:shadow-lg transition-shadow cursor-pointer">
      <CardHeader onClick={onSelect}>
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-primary/10 rounded-lg">
              <MapPin className="h-4 w-4 text-primary" />
            </div>
            <div>
              <CardTitle className="text-base">{unidade.nome}</CardTitle>
              <p className="text-sm text-muted-foreground">{unidade.codigo}</p>
            </div>
          </div>
          <div className="flex gap-1">
            <Badge variant={getCriticidadeColor(unidade.criticidade)}>
              {unidade.criticidade}
            </Badge>
            <Badge variant={unidade.status === "ativo" ? "default" : "secondary"}>
              {unidade.status}
            </Badge>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-2">
          {contrato && (
            <p className="text-sm text-muted-foreground">
              Contrato: {contrato.negocio}
            </p>
          )}
          {unidade.endereco && (
            <p className="text-sm">{unidade.endereco}</p>
          )}
          {(unidade.cidade || unidade.uf) && (
            <p className="text-sm text-muted-foreground">
              {unidade.cidade}{unidade.cidade && unidade.uf ? "/" : ""}{unidade.uf}
            </p>
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
                  Tem certeza que deseja excluir esta unidade? Esta ação não pode ser desfeita.
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

export default UnidadeCard;
