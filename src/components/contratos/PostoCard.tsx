import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Briefcase, Clock, Users, Trash2, Edit, UserCheck, UserX } from "lucide-react";
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

  useEffect(() => {
    fetchColaboradores();
    
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
    const efetivoNecessario = posto.efetivo_planejado || 1;
    
    if (totalColaboradores === 0) {
      setOcupacaoAtual('vago');
    } else if (totalColaboradores >= efetivoNecessario) {
      setOcupacaoAtual('ocupado');
    } else {
      setOcupacaoAtual('parcial');
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
          <div className="flex gap-2">
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
              {colaboradoresLotados.length}/{posto.efetivo_planejado || 1}
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
    </Card>
  );
};

export default PostoCard;
