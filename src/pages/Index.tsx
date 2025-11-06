import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Building2, CheckCircle2, Users, Shield } from "lucide-react";

const Index = () => {
  const navigate = useNavigate();

  const features = [
    {
      icon: Building2,
      title: "Gestão de Unidades",
      description: "Controle completo de unidades e postos de serviço",
    },
    {
      icon: Users,
      title: "Gestão de Pessoas",
      description: "Colaboradores, escalas e controle de presença",
    },
    {
      icon: CheckCircle2,
      title: "Ordens de Serviço",
      description: "Criação e acompanhamento de OS em tempo real",
    },
    {
      icon: Shield,
      title: "Controle de Acesso",
      description: "6 níveis de permissão para segurança total",
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
            Facilities Hub
          </h1>
          <p className="text-xl text-muted-foreground mb-8">
            Sistema completo de gestão de facilities com controle total sobre unidades,
            colaboradores, ordens de serviço e muito mais.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button
              size="lg"
              onClick={() => navigate("/auth")}
              className="text-lg px-8 shadow-lg hover:shadow-xl transition-shadow"
            >
              Começar Agora
            </Button>
            <Button
              size="lg"
              variant="outline"
              onClick={() => navigate("/auth")}
              className="text-lg px-8"
            >
              Já tenho conta
            </Button>
          </div>
        </div>

        {/* Features Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-16">
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
            Perfis de Acesso
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {[
              { role: "Administrador", description: "Acesso total ao sistema" },
              { role: "Gestor de Operações", description: "Tudo exceto gestão de usuários" },
              { role: "Supervisor", description: "CRUD de OS, incidentes e checklists" },
              { role: "Analista Centro Controle", description: "Leitura total + abertura de OS" },
              { role: "Técnico", description: "Visualizar OS e executar checklists" },
              { role: "Cliente", description: "Somente leitura e comentários" },
            ].map((item, index) => (
              <div key={index} className="flex items-start gap-3 p-4 bg-muted/50 rounded-lg">
                <CheckCircle2 className="h-5 w-5 text-primary flex-shrink-0 mt-0.5" />
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
          <p>© 2025 Facilities Hub. Todos os direitos reservados.</p>
        </div>
      </footer>
    </div>
  );
};

export default Index;