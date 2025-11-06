import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Clock, User } from "lucide-react";

interface OSHistoricoProps {
  osId: string;
}

export function OSHistorico({ osId }: OSHistoricoProps) {
  const { data: historico, isLoading } = useQuery({
    queryKey: ["os-historico", osId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("os_historico")
        .select("*")
        .eq("os_id", osId)
        .order("created_at", { ascending: false });
      if (error) throw error;
      
      // Fetch user details separately
      const historicoWithUsuario = await Promise.all(
        (data || []).map(async (item) => {
          const { data: profile } = await supabase
            .from("profiles")
            .select("full_name")
            .eq("id", item.usuario_id)
            .single();
          return { ...item, usuario: profile };
        })
      );
      
      return historicoWithUsuario;
    },
  });

  const formatDateTime = (date: string) => {
    return new Date(date).toLocaleString("pt-BR", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const getAcaoLabel = (acao: string) => {
    switch (acao) {
      case "criacao": return "Criação";
      case "atualizacao": return "Atualização";
      case "exclusao": return "Exclusão";
      default: return acao;
    }
  };

  const getCampoLabel = (campo: string) => {
    switch (campo) {
      case "status": return "Status";
      case "responsavel_id": return "Responsável";
      case "prioridade": return "Prioridade";
      case "tipo": return "Tipo";
      default: return campo;
    }
  };

  if (isLoading) {
    return (
      <Card>
        <CardContent className="py-8 text-center text-muted-foreground">
          Carregando histórico...
        </CardContent>
      </Card>
    );
  }

  if (!historico || historico.length === 0) {
    return (
      <Card>
        <CardContent className="py-8 text-center text-muted-foreground">
          Nenhuma alteração registrada
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {historico.map((item, index) => (
        <Card key={item.id}>
          <CardContent className="p-4">
            <div className="flex items-start gap-3">
              <div className="flex-1 space-y-2">
                <div className="flex items-center gap-2">
                  <Badge variant="outline">{getAcaoLabel(item.acao)}</Badge>
                  {item.campo_alterado && (
                    <span className="text-sm text-muted-foreground">
                      {getCampoLabel(item.campo_alterado)}
                    </span>
                  )}
                </div>

                {item.campo_alterado && (
                  <div className="text-sm space-y-1">
                    {item.valor_anterior && (
                      <div>
                        <span className="text-muted-foreground">De: </span>
                        <span className="line-through">{item.valor_anterior}</span>
                      </div>
                    )}
                    {item.valor_novo && (
                      <div>
                        <span className="text-muted-foreground">Para: </span>
                        <span className="font-medium">{item.valor_novo}</span>
                      </div>
                    )}
                  </div>
                )}

                {item.observacao && (
                  <p className="text-sm text-muted-foreground">{item.observacao}</p>
                )}

                <div className="flex items-center gap-4 text-xs text-muted-foreground pt-2">
                  <div className="flex items-center gap-1">
                    <User className="h-3 w-3" />
                    <span>{item.usuario?.full_name || "Sistema"}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <Clock className="h-3 w-3" />
                    <span>{formatDateTime(item.created_at)}</span>
                  </div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}