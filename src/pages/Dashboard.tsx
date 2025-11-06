import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { User } from "@supabase/supabase-js";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { 
  Building2, 
  Users, 
  ClipboardList, 
  AlertCircle, 
  LogOut,
  Settings,
  LayoutDashboard,
  BarChart3,
  MessageSquare,
  Eye,
  Shield,
  MapPin,
  FileText,
  Package,
  CheckCircle2,
  AlertTriangle
} from "lucide-react";
import { useToast } from "@/hooks/use-toast";

const Dashboard = () => {
  const [user, setUser] = useState<User | null>(null);
  const [userRole, setUserRole] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  const { toast } = useToast();

  useEffect(() => {
    checkUser();

    // Set up auth state listener
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        if (event === "SIGNED_IN" && session) {
          setUser(session.user);
          
          // Get user role
          const { data: roleData } = await supabase
            .from("user_roles")
            .select("role")
            .eq("user_id", session.user.id)
            .single();

          if (roleData) {
            setUserRole(roleData.role);
          }
          setLoading(false);
        } else if (event === "SIGNED_OUT") {
          navigate("/auth");
        }
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  const checkUser = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        navigate("/auth");
        return;
      }

      setUser(user);

      // Get user role
      const { data: roleData } = await supabase
        .from("user_roles")
        .select("role")
        .eq("user_id", user.id)
        .single();

      if (roleData) {
        setUserRole(roleData.role);
      }
    } catch (error) {
      console.error("Error checking user:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = async () => {
    await supabase.auth.signOut();
    toast({
      title: "Logout realizado",
      description: "Até logo!",
    });
    navigate("/auth");
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  const roleLabels: Record<string, string> = {
    admin: "Administrador",
    gestor_operacoes: "Gestor de Operações",
    supervisor: "Supervisor",
    analista_centro_controle: "Analista do Centro de Controle",
    tecnico: "Técnico",
    cliente_view: "Cliente (Visualização)",
  };

  const modules = [
    {
      title: "Dashboard 24/7",
      description: "Resumo executivo e alertas em tempo real",
      icon: BarChart3,
      color: "from-blue-500 to-cyan-500",
      action: () => toast({ title: "Em desenvolvimento", description: "Módulo em breve!" }),
    },
    {
      title: "Gestão de Contratos",
      description: "Clientes, contratos, unidades e postos",
      icon: Building2,
      color: "from-purple-500 to-pink-500",
      action: () => navigate("/contratos"),
    },
    {
      title: "Mesa de Operações",
      description: "Mapa operacional e monitoramento 24/7",
      icon: MapPin,
      color: "from-green-500 to-emerald-500",
      action: () => navigate("/mesa-operacoes"),
    },
    {
      title: "Chamados",
      description: "Sistema de abertura e acompanhamento",
      icon: MessageSquare,
      color: "from-orange-500 to-amber-500",
      action: () => toast({ title: "Em desenvolvimento", description: "Módulo em breve!" }),
    },
    {
      title: "Ordens de Serviço",
      description: "Preventivas, corretivas e emergenciais",
      icon: FileText,
      color: "from-indigo-500 to-purple-500",
      action: () => toast({ title: "Em desenvolvimento", description: "Módulo em breve!" }),
    },
    {
      title: "Incidentes",
      description: "Registro e investigação de incidentes",
      icon: AlertTriangle,
      color: "from-red-500 to-rose-500",
      action: () => toast({ title: "Em desenvolvimento", description: "Módulo em breve!" }),
    },
    {
      title: "Inspeções",
      description: "Checklists e auditorias",
      icon: CheckCircle2,
      color: "from-teal-500 to-cyan-500",
      action: () => toast({ title: "Em desenvolvimento", description: "Módulo em breve!" }),
    },
    {
      title: "Recursos",
      description: "Materiais, equipamentos e veículos",
      icon: Package,
      color: "from-violet-500 to-purple-500",
      action: () => toast({ title: "Em desenvolvimento", description: "Módulo em breve!" }),
    },
    {
      title: "Colaboradores",
      description: "Gestão de pessoal e escalas",
      icon: Users,
      color: "from-blue-500 to-indigo-500",
      action: () => navigate("/users"),
    },
    {
      title: "QSMMA",
      description: "Qualidade, Segurança, Meio Ambiente e Saúde",
      icon: Shield,
      color: "from-emerald-500 to-green-500",
      action: () => toast({ title: "Em desenvolvimento", description: "Módulo em breve!" }),
    },
    {
      title: "Portal do Cliente",
      description: "Área restrita para clientes",
      icon: Eye,
      color: "from-pink-500 to-rose-500",
      action: () => toast({ title: "Em desenvolvimento", description: "Módulo em breve!" }),
    },
    {
      title: "Configurações",
      description: "Configurações do sistema",
      icon: Settings,
      color: "from-gray-500 to-slate-500",
      action: () => toast({ title: "Em desenvolvimento", description: "Módulo em breve!" }),
    },
  ];

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b bg-card shadow-sm">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-gradient-to-br from-primary to-accent rounded-lg">
              <Building2 className="h-6 w-6 text-primary-foreground" />
            </div>
            <div>
              <h1 className="text-xl font-bold">Facilities Center</h1>
              <p className="text-sm text-muted-foreground">
                Sistema de Gestão de Facilities
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {userRole === "admin" && (
              <Button
                variant="outline"
                size="sm"
                onClick={() => navigate("/users")}
              >
                <Settings className="h-4 w-4 mr-2" />
                Gestão de Usuários
              </Button>
            )}
            <Button variant="outline" size="sm" onClick={handleLogout}>
              <LogOut className="h-4 w-4 mr-2" />
              Sair
            </Button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        <div className="mb-8">
          <div className="flex items-center gap-2 mb-2">
            <LayoutDashboard className="h-6 w-6 text-primary" />
            <h2 className="text-2xl font-bold">Dashboard</h2>
          </div>
          <p className="text-muted-foreground">
            Bem-vindo, {user?.email} • Perfil: {roleLabels[userRole || ""] || userRole}
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {modules.map((module, index) => (
            <Card
              key={index}
              className="cursor-pointer hover:shadow-lg transition-all duration-300 hover:-translate-y-1"
              onClick={module.action}
            >
              <CardHeader>
                <div className={`w-12 h-12 rounded-lg bg-gradient-to-br ${module.color} flex items-center justify-center mb-4`}>
                  <module.icon className="h-6 w-6 text-white" />
                </div>
                <CardTitle className="text-lg">{module.title}</CardTitle>
                <CardDescription>{module.description}</CardDescription>
              </CardHeader>
            </Card>
          ))}
        </div>

        {/* Quick Stats */}
        <div className="mt-8 grid grid-cols-1 md:grid-cols-4 gap-6">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between mb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  SLA do Dia
                </CardTitle>
                <BarChart3 className="h-5 w-5 text-green-600" />
              </div>
              <p className="text-3xl font-bold text-green-600">0%</p>
            </CardHeader>
          </Card>
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between mb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Chamados Abertos
                </CardTitle>
                <MessageSquare className="h-5 w-5 text-primary" />
              </div>
              <p className="text-3xl font-bold">0</p>
            </CardHeader>
          </Card>
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between mb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Incidentes Críticos
                </CardTitle>
                <AlertTriangle className="h-5 w-5 text-red-600" />
              </div>
              <p className="text-3xl font-bold text-red-600">0</p>
            </CardHeader>
          </Card>
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between mb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Postos Cobertos
                </CardTitle>
                <Users className="h-5 w-5 text-primary" />
              </div>
              <p className="text-3xl font-bold">0/0</p>
            </CardHeader>
          </Card>
        </div>
      </main>
    </div>
  );
};

export default Dashboard;