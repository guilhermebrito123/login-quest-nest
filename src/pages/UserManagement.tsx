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
import { Building2, ArrowLeft, Search, Shield, UserCog } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

interface UserWithRole {
  id: string;
  email: string;
  full_name: string | null;
  phone: string | null;
  role: string;
}

const UserManagement = () => {
  const [users, setUsers] = useState<UserWithRole[]>([]);
  const [filteredUsers, setFilteredUsers] = useState<UserWithRole[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [loading, setLoading] = useState(true);
  const [isAdmin, setIsAdmin] = useState(false);
  const navigate = useNavigate();
  const { toast } = useToast();

  useEffect(() => {
    checkAdminAndLoadUsers();
  }, []);

  useEffect(() => {
    filterUsers();
  }, [searchTerm, users]);

  const checkAdminAndLoadUsers = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        navigate("/auth");
        return;
      }

      // Check if user is admin
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
      await loadUsers();
    } catch (error) {
      console.error("Error:", error);
    } finally {
      setLoading(false);
    }
  };

  const loadUsers = async () => {
    try {
      const { data, error } = await supabase
        .from("profiles")
        .select(`
          id,
          email,
          full_name,
          phone,
          user_roles (role)
        `);

      if (error) throw error;

      const usersWithRoles = data?.map((user: any) => ({
        id: user.id,
        email: user.email,
        full_name: user.full_name,
        phone: user.phone,
        role: user.user_roles?.[0]?.role || "tecnico",
      })) || [];

      setUsers(usersWithRoles);
      setFilteredUsers(usersWithRoles);
    } catch (error: any) {
      toast({
        title: "Erro ao carregar usuários",
        description: error.message,
        variant: "destructive",
      });
    }
  };

  const filterUsers = () => {
    if (!searchTerm.trim()) {
      setFilteredUsers(users);
      return;
    }

    const term = searchTerm.toLowerCase();
    const filtered = users.filter(
      (user) =>
        user.email?.toLowerCase().includes(term) ||
        user.full_name?.toLowerCase().includes(term)
    );
    setFilteredUsers(filtered);
  };

  const handleRoleChange = async (
    userId: string,
    newRole: "admin" | "gestor_operacoes" | "supervisor" | "analista_centro_controle" | "tecnico" | "cliente_view"
  ) => {
    try {
      const { error } = await supabase
        .from("user_roles")
        .update({ role: newRole })
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

  const roleLabels: Record<string, string> = {
    admin: "Administrador",
    gestor_operacoes: "Gestor de Operações",
    supervisor: "Supervisor",
    analista_centro_controle: "Analista Centro Controle",
    tecnico: "Técnico",
    cliente_view: "Cliente (Visualização)",
  };

  const getRoleBadgeColor = (role: string) => {
    const colors: Record<string, string> = {
      admin: "bg-red-500",
      gestor_operacoes: "bg-purple-500",
      supervisor: "bg-blue-500",
      analista_centro_controle: "bg-cyan-500",
      tecnico: "bg-green-500",
      cliente_view: "bg-gray-500",
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
      {/* Header */}
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

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        <div className="mb-6">
          <div className="flex items-center gap-2 mb-4">
            <Shield className="h-6 w-6 text-primary" />
            <h2 className="text-2xl font-bold">Gestão de Perfis de Usuários</h2>
          </div>
          <p className="text-muted-foreground mb-6">
            Gerencie os perfis de acesso de todos os usuários do sistema
          </p>

          {/* Search */}
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
                    <p className="text-sm text-muted-foreground">
                      Tel: {user.phone}
                    </p>
                  )}
                  <div className="space-y-2">
                    <label className="text-sm font-medium">Perfil de Acesso</label>
                    <Select
                      value={user.role}
                      onValueChange={(value) => handleRoleChange(user.id, value as any)}
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
                  <Badge
                    className={`${getRoleBadgeColor(user.role)} text-white`}
                  >
                    {roleLabels[user.role]}
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
    </div>
    </DashboardLayout>
  );
};

export default UserManagement;