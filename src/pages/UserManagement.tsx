import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { DashboardLayout } from "@/components/DashboardLayout";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Building2, Search, Shield, UserCog, UserX, UserCheck } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { Textarea } from "@/components/ui/textarea";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";

interface UserWithRole {
  id: string;
  email: string;
  full_name: string | null;
  phone: string | null;
  role: string;
  ativo: boolean;
  deactivated_at: string | null;
  deactivation_reason: string | null;
}

interface CostCenter {
  id: string;
  name: string;
}

const UserManagement = () => {
  const [users, setUsers] = useState<UserWithRole[]>([]);
  const [filteredUsers, setFilteredUsers] = useState<UserWithRole[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [loading, setLoading] = useState(true);
  const [isAdmin, setIsAdmin] = useState(false);
  const [costCenters, setCostCenters] = useState<CostCenter[]>([]);
  const [colabDialog, setColabDialog] = useState<{ open: boolean; userId: string | null }>({
    open: false,
    userId: null,
  });
  const [selectedCostCenter, setSelectedCostCenter] = useState<string>("");
  const [submitting, setSubmitting] = useState(false);
  const [statusFilter, setStatusFilter] = useState<"ativos" | "inativos" | "todos">("ativos");
  const [deactivateDialog, setDeactivateDialog] = useState<{ open: boolean; user: UserWithRole | null }>({
    open: false,
    user: null,
  });
  const [deactivateReason, setDeactivateReason] = useState("");
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const navigate = useNavigate();
  const { toast } = useToast();

  useEffect(() => {
    checkAdminAndLoadUsers();
  }, []);

  useEffect(() => {
    filterUsers();
  }, [searchTerm, users, statusFilter]);

  const checkAdminAndLoadUsers = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        navigate("/auth");
        return;
      }
      setCurrentUserId(user.id);

      const { data: roleData } = await supabase
        .from("user_roles")
        .select("role")
        .eq("user_id", user.id)
        .single();

      if (roleData?.role !== "admin") {
        toast({
          title: "Acesso negado",
          description: "Apenas administradores podem acessar esta página.",
          variant: "destructive",
        });
        navigate("/dashboard");
        return;
      }

      setIsAdmin(true);
      await Promise.all([loadUsers(), loadCostCenters()]);
    } catch (error) {
      console.error("Error:", error);
    } finally {
      setLoading(false);
    }
  };

  const loadCostCenters = async () => {
    const { data, error } = await supabase
      .from("cost_center")
      .select("id, name")
      .order("name");
    if (error) {
      console.error(error);
      return;
    }
    setCostCenters(data || []);
  };

  const loadUsers = async () => {
    try {
      const { data: usersData, error: usersError } = await supabase
        .from("usuarios")
        .select("id, email, full_name, phone, ativo, deactivated_at, deactivation_reason");

      if (usersError) throw usersError;

      const { data: rolesData, error: rolesError } = await supabase
        .from("user_roles")
        .select("user_id, role");

      if (rolesError) throw rolesError;

      const roleMap = new Map<string, string>();
      (rolesData || []).forEach((r: any) => {
        if (!roleMap.has(r.user_id)) roleMap.set(r.user_id, r.role);
      });

      const usersWithRoles: UserWithRole[] = (usersData || []).map((user: any) => ({
        id: user.id,
        email: user.email,
        full_name: user.full_name,
        phone: user.phone,
        role: roleMap.get(user.id) || "tecnico",
        ativo: user.ativo ?? true,
        deactivated_at: user.deactivated_at ?? null,
        deactivation_reason: user.deactivation_reason ?? null,
      }));

      setUsers(usersWithRoles);
    } catch (error: any) {
      toast({
        title: "Erro ao carregar usuários",
        description: error.message,
        variant: "destructive",
      });
    }
  };

  const filterUsers = () => {
    let result = users;

    if (statusFilter === "ativos") result = result.filter((u) => u.ativo);
    else if (statusFilter === "inativos") result = result.filter((u) => !u.ativo);

    if (searchTerm.trim()) {
      const term = searchTerm.toLowerCase();
      result = result.filter(
        (u) =>
          u.email?.toLowerCase().includes(term) ||
          u.full_name?.toLowerCase().includes(term)
      );
    }
    setFilteredUsers(result);
  };

  const handleDeactivate = async () => {
    if (!deactivateDialog.user) return;
    setSubmitting(true);
    try {
      const { data, error } = await supabase.functions.invoke("deactivate-user", {
        body: { user_id: deactivateDialog.user.id, reason: deactivateReason || null },
      });
      if (error) throw error;
      if ((data as any)?.error) throw new Error((data as any).error);

      toast({
        title: "Usuário desativado",
        description: "O acesso foi bloqueado e o histórico preservado.",
      });
      setDeactivateDialog({ open: false, user: null });
      setDeactivateReason("");
      await loadUsers();
    } catch (error: any) {
      toast({
        title: "Erro ao desativar",
        description: error.message,
        variant: "destructive",
      });
    } finally {
      setSubmitting(false);
    }
  };

  const handleReactivate = async (userId: string) => {
    setSubmitting(true);
    try {
      const { data, error } = await supabase.functions.invoke("reactivate-user", {
        body: { user_id: userId },
      });
      if (error) throw error;
      if ((data as any)?.error) throw new Error((data as any).error);

      toast({
        title: "Usuário reativado",
        description: "O acesso foi restaurado.",
      });
      await loadUsers();
    } catch (error: any) {
      toast({
        title: "Erro ao reativar",
        description: error.message,
        variant: "destructive",
      });
    } finally {
      setSubmitting(false);
    }
  };

  const handleRoleChange = async (userId: string, newRole: string) => {
    // Caso especial: promover a colaborador exige escolher cost_center
    if (newRole === "colaborador") {
      setSelectedCostCenter("");
      setColabDialog({ open: true, userId });
      return;
    }

    try {
      const { error } = await supabase
        .from("user_roles")
        .update({ role: newRole as any })
        .eq("user_id", userId);

      if (error) throw error;

      toast({
        title: "Perfil atualizado",
        description: "O perfil do usuário foi alterado com sucesso.",
      });

      await loadUsers();
    } catch (error: any) {
      toast({
        title: "Erro ao atualizar perfil",
        description: error.message,
        variant: "destructive",
      });
    }
  };

  const handleConfirmColaborador = async () => {
    if (!colabDialog.userId || !selectedCostCenter) {
      toast({
        title: "Selecione um centro de custo",
        description: "É obrigatório vincular o colaborador a um centro de custo.",
        variant: "destructive",
      });
      return;
    }

    setSubmitting(true);
    try {
      const { error } = await supabase.rpc("definir_usuario_como_colaborador", {
        p_user_id: colabDialog.userId,
        p_cost_center_id: selectedCostCenter,
      });
      if (error) throw error;

      toast({
        title: "Colaborador vinculado",
        description: "Usuário promovido a colaborador e vinculado ao centro de custo.",
      });
      setColabDialog({ open: false, userId: null });
      setSelectedCostCenter("");
      await loadUsers();
    } catch (error: any) {
      toast({
        title: "Erro ao definir colaborador",
        description: error.message,
        variant: "destructive",
      });
    } finally {
      setSubmitting(false);
    }
  };

  const roleLabels: Record<string, string> = {
    admin: "Administrador",
    gestor_operacoes: "Gestor de Operações",
    supervisor: "Supervisor",
    analista_centro_controle: "Analista Centro Controle",
    tecnico: "Técnico",
    cliente_view: "Cliente (Visualização)",
    colaborador: "Colaborador",
  };

  const getRoleBadgeColor = (role: string) => {
    const colors: Record<string, string> = {
      admin: "bg-red-500",
      gestor_operacoes: "bg-purple-500",
      supervisor: "bg-blue-500",
      analista_centro_controle: "bg-cyan-500",
      tecnico: "bg-green-500",
      cliente_view: "bg-gray-500",
      colaborador: "bg-amber-500",
    };
    return colors[role] || "bg-gray-500";
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!isAdmin) return null;

  return (
    <DashboardLayout>
      <div className="min-h-screen bg-background">
        <header className="border-b bg-card shadow-sm">
          <div className="container mx-auto px-4 py-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-gradient-to-br from-primary to-accent rounded-lg">
                <Building2 className="h-6 w-6 text-primary-foreground" />
              </div>
              <div>
                <h1 className="text-xl font-bold">Facilities Center</h1>
                <p className="text-sm text-muted-foreground">Gestão de Usuários</p>
              </div>
            </div>
          </div>
        </header>

        <main className="container mx-auto px-4 py-8">
          <div className="mb-6">
            <div className="flex items-center gap-2 mb-4">
              <Shield className="h-6 w-6 text-primary" />
              <h2 className="text-2xl font-bold">Gestão de Perfis de Usuários</h2>
            </div>
            <p className="text-muted-foreground mb-6">
              Gerencie os perfis de acesso de todos os usuários do sistema
            </p>

            <div className="relative max-w-md">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Buscar por nome ou email..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredUsers.map((user) => (
              <Card key={user.id} className="hover:shadow-md transition-shadow">
                <CardHeader>
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-3">
                      <div className="p-2 bg-primary/10 rounded-lg">
                        <UserCog className="h-5 w-5 text-primary" />
                      </div>
                      <div>
                        <CardTitle className="text-base">
                          {user.full_name || "Sem nome"}
                        </CardTitle>
                        <CardDescription className="text-xs">
                          {user.email}
                        </CardDescription>
                      </div>
                    </div>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {user.phone && (
                      <p className="text-sm text-muted-foreground">Tel: {user.phone}</p>
                    )}
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Perfil de Acesso</label>
                      <Select
                        value={user.role}
                        onValueChange={(value) => handleRoleChange(user.id, value)}
                      >
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          {Object.entries(roleLabels).map(([value, label]) => (
                            <SelectItem key={value} value={value}>
                              <div className="flex items-center gap-2">
                                <div
                                  className={`w-2 h-2 rounded-full ${getRoleBadgeColor(value)}`}
                                />
                                {label}
                              </div>
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                    <Badge className={`${getRoleBadgeColor(user.role)} text-white`}>
                      {roleLabels[user.role] || user.role}
                    </Badge>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {filteredUsers.length === 0 && (
            <Card className="mt-8">
              <CardContent className="py-12 text-center">
                <p className="text-muted-foreground">
                  Nenhum usuário encontrado com os filtros aplicados.
                </p>
              </CardContent>
            </Card>
          )}
        </main>

        <Dialog
          open={colabDialog.open}
          onOpenChange={(open) =>
            !submitting && setColabDialog({ open, userId: open ? colabDialog.userId : null })
          }
        >
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Promover a Colaborador</DialogTitle>
              <DialogDescription>
                Selecione o centro de custo ao qual este colaborador estará vinculado. Ele só
                poderá abrir chamados em locais deste centro de custo.
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-2 py-4">
              <Label>Centro de Custo</Label>
              <Select value={selectedCostCenter} onValueChange={setSelectedCostCenter}>
                <SelectTrigger>
                  <SelectValue placeholder="Selecione um centro de custo" />
                </SelectTrigger>
                <SelectContent>
                  {costCenters.map((cc) => (
                    <SelectItem key={cc.id} value={cc.id}>
                      {cc.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => setColabDialog({ open: false, userId: null })}
                disabled={submitting}
              >
                Cancelar
              </Button>
              <Button onClick={handleConfirmColaborador} disabled={submitting || !selectedCostCenter}>
                {submitting ? "Vinculando..." : "Confirmar"}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>
    </DashboardLayout>
  );
};

export default UserManagement;
