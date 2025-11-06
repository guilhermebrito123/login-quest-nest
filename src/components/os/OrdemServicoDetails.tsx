import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { Calendar, Clock, User, MapPin, FileText, History, Paperclip } from "lucide-react";
import { OSAnexos } from "./OSAnexos";
import { OSHistorico } from "./OSHistorico";

interface OrdemServicoDetailsProps {
  os: any;
  open: boolean;
  onClose: () => void;
}

export function OrdemServicoDetails({ os, open, onClose }: OrdemServicoDetailsProps) {
  const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString("pt-BR", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
    });
  };

  const formatDateTime = (date: string) => {
    return new Date(date).toLocaleString("pt-BR", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <div className="flex items-center justify-between">
            <DialogTitle>Ordem de Serviço {os.numero}</DialogTitle>
            <div className="flex gap-2">
              <Badge>{os.tipo}</Badge>
              <Badge>{os.prioridade}</Badge>
              <Badge>{os.status.replace("_", " ")}</Badge>
            </div>
          </div>
        </DialogHeader>

        <Tabs defaultValue="detalhes" className="w-full">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="detalhes">
              <FileText className="h-4 w-4 mr-2" />
              Detalhes
            </TabsTrigger>
            <TabsTrigger value="anexos">
              <Paperclip className="h-4 w-4 mr-2" />
              Anexos
            </TabsTrigger>
            <TabsTrigger value="historico">
              <History className="h-4 w-4 mr-2" />
              Histórico
            </TabsTrigger>
          </TabsList>

          <TabsContent value="detalhes" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Informações Gerais</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <h4 className="font-semibold mb-1">{os.titulo}</h4>
                  {os.descricao && (
                    <p className="text-sm text-muted-foreground">{os.descricao}</p>
                  )}
                </div>

                <Separator />

                <div className="grid grid-cols-2 gap-4">
                  {os.unidade?.nome && (
                    <div className="flex items-start gap-2">
                      <MapPin className="h-4 w-4 text-muted-foreground mt-1" />
                      <div>
                        <p className="text-sm font-medium">Unidade</p>
                        <p className="text-sm text-muted-foreground">{os.unidade.nome}</p>
                      </div>
                    </div>
                  )}

                  {os.responsavel?.full_name && (
                    <div className="flex items-start gap-2">
                      <User className="h-4 w-4 text-muted-foreground mt-1" />
                      <div>
                        <p className="text-sm font-medium">Responsável</p>
                        <p className="text-sm text-muted-foreground">{os.responsavel.full_name}</p>
                      </div>
                    </div>
                  )}

                  {os.solicitante?.full_name && (
                    <div className="flex items-start gap-2">
                      <User className="h-4 w-4 text-muted-foreground mt-1" />
                      <div>
                        <p className="text-sm font-medium">Solicitante</p>
                        <p className="text-sm text-muted-foreground">{os.solicitante.full_name}</p>
                      </div>
                    </div>
                  )}

                  {os.data_abertura && (
                    <div className="flex items-start gap-2">
                      <Clock className="h-4 w-4 text-muted-foreground mt-1" />
                      <div>
                        <p className="text-sm font-medium">Data de Abertura</p>
                        <p className="text-sm text-muted-foreground">{formatDateTime(os.data_abertura)}</p>
                      </div>
                    </div>
                  )}

                  {os.data_prevista && (
                    <div className="flex items-start gap-2">
                      <Calendar className="h-4 w-4 text-muted-foreground mt-1" />
                      <div>
                        <p className="text-sm font-medium">Data Prevista</p>
                        <p className="text-sm text-muted-foreground">{formatDate(os.data_prevista)}</p>
                      </div>
                    </div>
                  )}

                  {os.data_conclusao && (
                    <div className="flex items-start gap-2">
                      <Calendar className="h-4 w-4 text-muted-foreground mt-1" />
                      <div>
                        <p className="text-sm font-medium">Data de Conclusão</p>
                        <p className="text-sm text-muted-foreground">{formatDateTime(os.data_conclusao)}</p>
                      </div>
                    </div>
                  )}
                </div>

                {os.observacoes && (
                  <>
                    <Separator />
                    <div>
                      <p className="text-sm font-medium mb-1">Observações</p>
                      <p className="text-sm text-muted-foreground whitespace-pre-wrap">{os.observacoes}</p>
                    </div>
                  </>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="anexos">
            <OSAnexos osId={os.id} />
          </TabsContent>

          <TabsContent value="historico">
            <OSHistorico osId={os.id} />
          </TabsContent>
        </Tabs>
      </DialogContent>
    </Dialog>
  );
}