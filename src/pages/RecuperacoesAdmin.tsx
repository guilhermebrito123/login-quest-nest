import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { DashboardLayout } from "@/components/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
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
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { Loader2, ShieldCheck, ShieldX, Copy, KeyRound, RefreshCw } from "lucide-react";
import { format } from "date-fns";
import { ptBR } from "date-fns/locale";

interface RecoveryRequest {
  id: string;
  user_id: string | null;
  requested_identifier: string;
  status: string;
  reason: string | null;
  opened_at: string;
  reviewed_at: string | null;
  reviewed_by: string | null;
  rejection_reason: string | null;
  ip: string | null;
  usuario?: { full_name: string | null; email: string } | null;
}

const statusLabels: Record<string, { label: string; variant: "default" | "secondary" | "destructive" | "outline" }> = {
  pending: { label: "Pendente", variant: "secondary" },
  approved: { label: "Aprovado", variant: "default" },
  rejected: { label: "Rejeitado", variant: "destructive" },
  consumed: { label: "Concluído", variant: "outline" },
  expired: { label: "Expirado", variant: "outline" },
};

const RecuperacoesAdmin = () => {
  const [requests, setRequests] = useState<RecoveryRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [isAdmin, setIsAdmin] = useState<boolean | null>(null);
  const [rejectDialog, setRejectDialog] = useState<{ open: boolean; requestId: string | null }>({
    open: false,
    requestId: null,
  });
  const [rejectReason, setRejectReason] = useState("");
  const [approvedDialog, setApprovedDialog] = useState<{
    open: boolean;
    link: string;
    expiresInMinutes: number;
  }>({ open: false, link: "", expiresInMinutes: 0 });
  const { toast } = useToast();

  const checkAdmin = async () => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      setIsAdmin(false);
      return false;
    }

    const { data: profile } = await supabase
      .from("internal_profiles")
      .select("nivel_acesso")
      .eq("user_id", user.id)
      .maybeSingle();

    const admin = profile?.nivel_acesso === "admin";
    setIsAdmin(admin);
    return admin;
  };

  const loadRequests = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from("account_recovery_requests")
      .select("*")
      .order("opened_at", { ascending: false })
      .limit(100);

    if (error) {
      toast({
        title: "Erro ao carregar pedidos",
        description: error.message,
        variant: "destructive",
      });
      setLoading(false);
      return;
    }

    // Carrega dados dos usuários relacionados
    const userIds = [...new Set((data || []).map((r) => r.user_id).filter(Boolean))] as string[];
    let usuariosMap: Record<string, { full_name: string | null; email: string }> = {};

    if (userIds.length > 0) {
      const { data: usuarios } = await supabase
        .from("usuarios")
        .select("id, full_name, email")
        .in("id", userIds);

      usuariosMap = Object.fromEntries(
        (usuarios || []).map((u) => [u.id, { full_name: u.full_name, email: u.email }]),
      );
    }

    setRequests(
      (data || []).map((r) => ({
        ...r,
        usuario: r.user_id ? usuariosMap[r.user_id] ?? null : null,
      })),
    );
    setLoading(false);
  };

  useEffect(() => {
    (async () => {
      const admin = await checkAdmin();
      if (admin) await loadRequests();
      else setLoading(false);
    })();
  }, []);

  const handleApprove = async (requestId: string) => {
    setActionLoading(requestId);
    try {
      const { data, error } = await supabase.functions.invoke("approve-manual-recovery", {
        body: { requestId, approve: true },
      });

      if (error) throw error;
      if (data?.error) throw new Error(data.error);

      const fullLink = `${window.location.origin}${data.recovery_link}`;
      setApprovedDialog({
        open: true,
        link: fullLink,
        expiresInMinutes: data.expires_in_minutes,
      });

      toast({
        title: "Pedido aprovado",
        description: "O usuário foi notificado e o link foi gerado.",
      });

      await loadRequests();
    } catch (error: any) {
      toast({
        title: "Erro ao aprovar",
        description: error.message,
        variant: "destructive",
      });
    } finally {
      setActionLoading(null);
    }
  };

  const handleReject = async () => {
    if (!rejectDialog.requestId) return;
    setActionLoading(rejectDialog.requestId);
    try {
      const { data, error } = await supabase.functions.invoke("approve-manual-recovery", {
        body: {
          requestId: rejectDialog.requestId,
          approve: false,
          rejectionReason: rejectReason || null,
        },
      });

      if (error) throw error;
      if (data?.error) throw new Error(data.error);

      toast({
        title: "Pedido rejeitado",
        description: "O usuário será notificado.",
      });

      setRejectDialog({ open: false, requestId: null });
      setRejectReason("");
      await loadRequests();
    } catch (error: any) {
      toast({
        title: "Erro ao rejeitar",
        description: error.message,
        variant: "destructive",
      });
    } finally {
      setActionLoading(null);
    }
  };

  const copyLink = () => {
    navigator.clipboard.writeText(approvedDialog.link);
    toast({ title: "Link copiado!" });
  };

  if (isAdmin === null || loading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center min-h-[400px]">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </div>
      </DashboardLayout>
    );
  }

  if (!isAdmin) {
    return (
      <DashboardLayout>
        <Card>
          <CardHeader>
            <CardTitle>Acesso negado</CardTitle>
            <CardDescription>
              Apenas administradores podem acessar esta página.
            </CardDescription>
          </CardHeader>
        </Card>
      </DashboardLayout>
    );
  }

  const pendingCount = requests.filter((r) => r.status === "pending").length;

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold flex items-center gap-2">
              <KeyRound className="h-7 w-7 text-primary" />
              Pedidos de Recuperação de Acesso
            </h1>
            <p className="text-muted-foreground mt-1">
              {pendingCount} pendente{pendingCount !== 1 ? "s" : ""} de análise
            </p>
          </div>
          <Button variant="outline" onClick={loadRequests} disabled={loading}>
            <RefreshCw className="h-4 w-4 mr-2" />
            Atualizar
          </Button>
        </div>

        <Card>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Usuário</TableHead>
                  <TableHead>Identificador</TableHead>
                  <TableHead>Motivo</TableHead>
                  <TableHead>Aberto em</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Ações</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {requests.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center text-muted-foreground py-8">
                      Nenhum pedido de recuperação encontrado.
                    </TableCell>
                  </TableRow>
                ) : (
                  requests.map((req) => {
                    const status = statusLabels[req.status] ?? { label: req.status, variant: "outline" as const };
                    const isPending = req.status === "pending";
                    const userExists = !!req.user_id;

                    return (
                      <TableRow key={req.id}>
                        <TableCell>
                          {req.usuario ? (
                            <div>
                              <div className="font-medium">{req.usuario.full_name ?? "—"}</div>
                              <div className="text-xs text-muted-foreground">{req.usuario.email}</div>
                            </div>
                          ) : (
                            <span className="text-muted-foreground italic">Conta não encontrada</span>
                          )}
                        </TableCell>
                        <TableCell className="font-mono text-sm">{req.requested_identifier}</TableCell>
                        <TableCell className="max-w-xs truncate" title={req.reason ?? undefined}>
                          {req.reason || <span className="text-muted-foreground">—</span>}
                        </TableCell>
                        <TableCell className="text-sm">
                          {format(new Date(req.opened_at), "dd/MM/yyyy HH:mm", { locale: ptBR })}
                        </TableCell>
                        <TableCell>
                          <Badge variant={status.variant}>{status.label}</Badge>
                        </TableCell>
                        <TableCell className="text-right space-x-2">
                          {isPending && (
                            <>
                              <Button
                                size="sm"
                                onClick={() => handleApprove(req.id)}
                                disabled={!userExists || actionLoading === req.id}
                                title={!userExists ? "Conta não encontrada — não é possível aprovar" : ""}
                              >
                                {actionLoading === req.id ? (
                                  <Loader2 className="h-4 w-4 animate-spin" />
                                ) : (
                                  <>
                                    <ShieldCheck className="h-4 w-4 mr-1" />
                                    Aprovar
                                  </>
                                )}
                              </Button>
                              <Button
                                size="sm"
                                variant="destructive"
                                onClick={() => setRejectDialog({ open: true, requestId: req.id })}
                                disabled={actionLoading === req.id}
                              >
                                <ShieldX className="h-4 w-4 mr-1" />
                                Rejeitar
                              </Button>
                            </>
                          )}
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>

      {/* Diálogo de rejeição */}
      <AlertDialog
        open={rejectDialog.open}
        onOpenChange={(open) => !open && setRejectDialog({ open: false, requestId: null })}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Rejeitar pedido de recuperação?</AlertDialogTitle>
            <AlertDialogDescription>
              O usuário será notificado de que o pedido foi rejeitado.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <div className="space-y-2">
            <Label htmlFor="reject-reason">Motivo (opcional)</Label>
            <Textarea
              id="reject-reason"
              placeholder="Ex: Identidade não confirmada..."
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              maxLength={500}
              rows={3}
            />
          </div>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction onClick={handleReject} className="bg-destructive hover:bg-destructive/90">
              Rejeitar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Diálogo do link gerado após aprovação */}
      <Dialog
        open={approvedDialog.open}
        onOpenChange={(open) => !open && setApprovedDialog({ open: false, link: "", expiresInMinutes: 0 })}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Pedido aprovado</DialogTitle>
            <DialogDescription>
              O usuário recebeu uma notificação no sistema com o link para definir nova senha. Você também
              pode copiar o link abaixo e enviar por canal interno seguro.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-2">
            <Label>Link de redefinição (válido por {approvedDialog.expiresInMinutes} minutos)</Label>
            <div className="flex gap-2">
              <input
                readOnly
                value={approvedDialog.link}
                className="flex-1 px-3 py-2 text-sm bg-muted rounded-md border font-mono"
              />
              <Button size="icon" variant="outline" onClick={copyLink}>
                <Copy className="h-4 w-4" />
              </Button>
            </div>
          </div>
          <DialogFooter>
            <Button onClick={() => setApprovedDialog({ open: false, link: "", expiresInMinutes: 0 })}>
              Fechar
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </DashboardLayout>
  );
};

export default RecuperacoesAdmin;
