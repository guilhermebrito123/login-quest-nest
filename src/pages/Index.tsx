import { useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Building2, CheckCircle2, Users, Shield, BarChart3, FileText, Activity } from "lucide-react";

const Index = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check if user is already logged in
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) {
        navigate("/dashboard");
      } else {
        setLoading(false);
      }
    });

    // Subscribe to auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      if (session) {
        navigate("/dashboard");
      }
    });

    return () => subscription.unsubscribe();
  }, [navigate]);

  if (loading) {
    return null; // or a loading spinner
  }

  const features = [
    {
      icon: Activity,
      title: "Monitoramento 24/7",
      description: "Centro de controle operacional em tempo real",
    },
    {
      icon: Building2,
      title: "Gestão de Contratos",
      description: "Hierarquia Cliente → Contrato → Unidade → Posto",
    },
    {
      icon: Users,
      title: "Gestão de Colaboradores",
      description: "Controle de escalas, presença e performance",
    },
    {
      icon: FileText,
      title: "Ordens de Serviço",
      description: "Preventivas, corretivas e emergenciais",
    },
    {
      icon: CheckCircle2,
      title: "Checklists Inteligentes",
      description: "Inspeções programadas e auditoria completa",
    },
    {
      icon: BarChart3,
      title: "Dashboard Executivo",
      description: "KPIs, SLA e NPS em tempo real",
    },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 via-background to-accent/5">
      {/* Hero Section */}
      <div className="container mx-auto px-4 py-16">
        <div className="text-center max-w-4xl mx-auto mb-16">
          <div className="inline-flex p-4 bg-gradient-to-br from-primary to-accent rounded-2xl mb-6 shadow-lg">
            <Building2 className="h-16 w-16 text-primary-foreground" />
          </div>
          <h1 className="text-5xl md:text-6xl font-bold mb-6 bg-gradient-to-r from-primary via-accent to-primary bg-clip-text text-transparent">
            Facilities Center
          </h1>
          <p className="text-xl text-muted-foreground mb-4">
            Plataforma de gestão de operações de serviço que atua como núcleo de inteligência operacional 24/7
          </p>
          <p className="text-lg text-muted-foreground mb-8">
            Monitoramento contínuo e preditivo com precisão e inteligência para garantir estabilidade operacional
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button
              size="lg"
              onClick={() => navigate("/auth")}
              className="text-lg px-8 shadow-lg hover:shadow-xl transition-shadow"
            >
              Acessar Plataforma
            </Button>
            <Button
              size="lg"
              variant="outline"
              onClick={() => navigate("/auth")}
              className="text-lg px-8"
            >
              Criar Conta
            </Button>
          </div>
        </div>

        {/* Features Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-16">
          {features.map((feature, index) => (
            <div
              key={index}
              className="bg-card p-6 rounded-xl shadow-md hover:shadow-lg transition-all duration-300 hover:-translate-y-1 border"
            >
              <div className="inline-flex p-3 bg-primary/10 rounded-lg mb-4">
                <feature.icon className="h-6 w-6 text-primary" />
              </div>
              <h3 className="text-lg font-semibold mb-2">{feature.title}</h3>
              <p className="text-sm text-muted-foreground">{feature.description}</p>
            </div>
          ))}
        </div>

        {/* Roles Section */}
        <div className="bg-card rounded-2xl p-8 shadow-lg border max-w-4xl mx-auto">
          <h2 className="text-3xl font-bold mb-6 text-center">
            Controle de Acesso por Perfil (RBAC)
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {[
              { role: "Administrador", description: "Acesso total ao sistema" },
              { role: "Gestor de Operações", description: "Tudo exceto gestão de usuários" },
              { role: "Supervisor", description: "CRUD de OS, incidentes, checklists e presença" },
              { role: "Analista Centro Controle", description: "Leitura total + abertura de OS e incidentes" },
              { role: "Técnico", description: "Visualizar OS atribuídas e executar checklists" },
              { role: "Cliente View", description: "Somente leitura e comentários" },
            ].map((item, index) => (
              <div key={index} className="flex items-start gap-3 p-4 bg-muted/50 rounded-lg">
                <Shield className="h-5 w-5 text-primary flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-semibold">{item.role}</p>
                  <p className="text-sm text-muted-foreground">{item.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="border-t bg-card/50 py-8">
        <div className="container mx-auto px-4 text-center text-muted-foreground">
          <p>© 2025 Facilities Center - Delta Facilities. Todos os direitos reservados.</p>
        </div>
      </footer>
    </div>
  );
};

export default Index;