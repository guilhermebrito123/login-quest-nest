import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { format } from "date-fns";
import { ptBR } from "date-fns/locale";
import { MessageSquare, Paperclip, Send, UserCircle, Star } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { Skeleton } from "@/components/ui/skeleton";

interface ChamadoDetailsProps {
  chamado: any;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onEdit: (chamado: any) => void;
  onDelete: (id: string) => void;
}

export function ChamadoDetails({ chamado, open, onOpenChange, onEdit, onDelete }: ChamadoDetailsProps) {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const [novoComentario, setNovoComentario] = useState("");
  const [avaliacao, setAvaliacao] = useState<number | null>(chamado.avaliacao || null);

  const { data: comentarios, isLoading: loadingComentarios } = useQuery({
    queryKey: ["chamados_comentarios", chamado.id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("chamados_comentarios")
        .select(`
          *,
          usuario:profiles(full_name)
        `)
        .eq("chamado_id", chamado.id)
        .order("created_at", { ascending: true });
      
      if (error) throw error;
      return data;
    },
    enabled: open,
  });

  const { data: anexos, isLoading: loadingAnexos } = useQuery({
    queryKey: ["chamados_anexos", chamado.id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("chamados_anexos")
        .select(`
          *,
          usuario:profiles(full_name)
        `)
        .eq("chamado_id", chamado.id)
        .order("created_at", { ascending: false });
      
      if (error) throw error;
      return data;
    },
    enabled: open,
  });

  const adicionarComentario = useMutation({
    mutationFn: async (comentario: string) => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error("Usuário não autenticado");

      const { error } = await supabase
        .from("chamados_comentarios")
        .insert([{
          chamado_id: chamado.id,
          usuario_id: user.id,
          comentario,
        }]);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["chamados_comentarios", chamado.id] });
      setNovoComentario("");
      toast({ title: "Comentário adicionado com sucesso!" });
    },
    onError: (error: any) => {
      toast({
        title: "Erro ao adicionar comentário",
        description: error.message,
        variant: "destructive",
      });
    },
  });

  const avaliarChamado = useMutation({
    mutationFn: async (nota: number) => {
      const { error } = await supabase
        .from("chamados")
        .update({ avaliacao: nota })
        .eq("id", chamado.id);

      if (error) throw error;
    },
    onSuccess: () => {
      toast({ title: "Avaliação registrada com sucesso!" });
    },
    onError: (error: any) => {
      toast({
        title: "Erro ao avaliar chamado",
        description: error.message,
        variant: "destructive",
      });
    },
  });

  const handleEnviarComentario = () => {
    if (novoComentario.trim()) {
      adicionarComentario.mutate(novoComentario);
    }
  };

  const handleAvaliar = (nota: number) => {
    setAvaliacao(nota);
    avaliarChamado.mutate(nota);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <div className="flex items-center justify-between">
            <DialogTitle className="flex items-center gap-2">
              <span>{chamado.numero}</span>
              <Badge>{chamado.status?.replace("_", " ")}</Badge>
            </DialogTitle>
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => {
                  onEdit(chamado);
                  onOpenChange(false);
                }}
              >
                Editar
              </Button>
              <Button
                variant="destructive"
                size="sm"
                onClick={() => {
                  if (confirm("Tem certeza que deseja excluir este chamado?")) {
                    onDelete(chamado.id);
                    onOpenChange(false);
                  }
                }}
              >
                Excluir
              </Button>
            </div>
          </div>
        </DialogHeader>

        <div className="space-y-6">
          <div>
            <h2 className="text-2xl font-bold mb-2">{chamado.titulo}</h2>
            {chamado.descricao && (
              <p className="text-muted-foreground">{chamado.descricao}</p>
            )}
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <Card className="p-4 space-y-2">
              <h3 className="font-semibold">Informações</h3>
              <div className="text-sm space-y-1">
                <div><span className="font-medium">Tipo:</span> {chamado.tipo}</div>
                {chamado.categoria && (
                  <div><span className="font-medium">Categoria:</span> {chamado.categoria}</div>
                )}
                {chamado.subcategoria && (
                  <div><span className="font-medium">Subcategoria:</span> {chamado.subcategoria}</div>
                )}
                <div><span className="font-medium">Prioridade:</span> {chamado.prioridade}</div>
                <div><span className="font-medium">Canal:</span> {chamado.canal}</div>
                {chamado.sla_horas && (
                  <div><span className="font-medium">SLA:</span> {chamado.sla_horas} horas</div>
                )}
              </div>
            </Card>

            <Card className="p-4 space-y-2">
              <h3 className="font-semibold">Localização</h3>
              <div className="text-sm space-y-1">
                {chamado.contrato && (
                  <div><span className="font-medium">Contrato:</span> {chamado.contrato.nome}</div>
                )}
                {chamado.unidade && (
                  <div><span className="font-medium">Unidade:</span> {chamado.unidade.nome}</div>
                )}
                {chamado.posto_servico && (
                  <div><span className="font-medium">Posto:</span> {chamado.posto_servico.nome}</div>
                )}
              </div>
            </Card>

            <Card className="p-4 space-y-2">
              <h3 className="font-semibold">Pessoas</h3>
              <div className="text-sm space-y-1">
                {chamado.solicitante && (
                  <div><span className="font-medium">Solicitante:</span> {chamado.solicitante.nome_completo}</div>
                )}
                {chamado.atribuido && (
                  <div><span className="font-medium">Atribuído:</span> {chamado.atribuido.nome_completo}</div>
                )}
                {chamado.responsavel && (
                  <div><span className="font-medium">Responsável:</span> {chamado.responsavel.nome_completo}</div>
                )}
              </div>
            </Card>

            <Card className="p-4 space-y-2">
              <h3 className="font-semibold">Datas</h3>
              <div className="text-sm space-y-1">
                <div>
                  <span className="font-medium">Abertura:</span>{" "}
                  {format(new Date(chamado.data_abertura), "dd/MM/yyyy HH:mm", { locale: ptBR })}
                </div>
                {chamado.data_conclusao && (
                  <div>
                    <span className="font-medium">Conclusão:</span>{" "}
                    {format(new Date(chamado.data_conclusao), "dd/MM/yyyy HH:mm", { locale: ptBR })}
                  </div>
                )}
              </div>
            </Card>
          </div>

          {chamado.status === "concluido" && (
            <Card className="p-4">
              <h3 className="font-semibold mb-3 flex items-center gap-2">
                <Star className="h-5 w-5" />
                Avaliação NPS
              </h3>
              <div className="flex gap-2">
                {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((nota) => (
                  <Button
                    key={nota}
                    variant={avaliacao === nota ? "default" : "outline"}
                    size="sm"
                    onClick={() => handleAvaliar(nota)}
                  >
                    {nota}
                  </Button>
                ))}
              </div>
              {avaliacao && (
                <p className="text-sm text-muted-foreground mt-2">
                  Avaliação: {avaliacao}/10
                </p>
              )}
            </Card>
          )}

          <Separator />

          <div>
            <h3 className="font-semibold mb-3 flex items-center gap-2">
              <Paperclip className="h-5 w-5" />
              Anexos ({anexos?.length || 0})
            </h3>
            {loadingAnexos ? (
              <Skeleton className="h-20 w-full" />
            ) : anexos && anexos.length > 0 ? (
              <div className="grid gap-2 md:grid-cols-2">
                {anexos.map((anexo: any) => (
                  <Card key={anexo.id} className="p-3">
                    <div className="flex items-center justify-between">
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium truncate">{anexo.nome_arquivo}</p>
                        <p className="text-xs text-muted-foreground">
                          {anexo.usuario?.full_name} • {format(new Date(anexo.created_at), "dd/MM/yyyy HH:mm", { locale: ptBR })}
                        </p>
                      </div>
                    </div>
                  </Card>
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">Nenhum anexo</p>
            )}
          </div>

          <Separator />

          <div>
            <h3 className="font-semibold mb-3 flex items-center gap-2">
              <MessageSquare className="h-5 w-5" />
              Comentários ({comentarios?.length || 0})
            </h3>

            <div className="space-y-3 mb-4">
              {loadingComentarios ? (
                <Skeleton className="h-20 w-full" />
              ) : comentarios && comentarios.length > 0 ? (
                comentarios.map((comentario: any) => (
                  <Card key={comentario.id} className="p-3">
                    <div className="flex items-start gap-3">
                      <UserCircle className="h-8 w-8 text-muted-foreground" />
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <span className="text-sm font-medium">
                            {comentario.usuario?.full_name || "Usuário"}
                          </span>
                          <span className="text-xs text-muted-foreground">
                            {format(new Date(comentario.created_at), "dd/MM/yyyy HH:mm", { locale: ptBR })}
                          </span>
                        </div>
                        <p className="text-sm">{comentario.comentario}</p>
                      </div>
                    </div>
                  </Card>
                ))
              ) : (
                <p className="text-sm text-muted-foreground">Nenhum comentário ainda</p>
              )}
            </div>

            <div className="flex gap-2">
              <Textarea
                placeholder="Adicione um comentário..."
                value={novoComentario}
                onChange={(e) => setNovoComentario(e.target.value)}
                rows={2}
              />
              <Button
                onClick={handleEnviarComentario}
                disabled={!novoComentario.trim() || adicionarComentario.isPending}
              >
                <Send className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
