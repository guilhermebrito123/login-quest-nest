import { 
  LayoutDashboard, 
  Users, 
  FileText, 
  Headphones, 
  ClipboardList, 
  UserCheck,
  LogOut,
  Calendar,
  MessageSquare,
  Package,
  UserCircle
} from "lucide-react";
import { NavLink } from "@/components/NavLink";
import { useLocation, useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";

import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  useSidebar,
} from "@/components/ui/sidebar";

const menuItems = [
  { title: "Dashboard 24/7", url: "/dashboard-24h", icon: LayoutDashboard },
  { title: "Dashboard", url: "/dashboard", icon: LayoutDashboard },
  { title: "Contratos", url: "/contratos", icon: FileText },
  { title: "Mesa de Operações", url: "/mesa-operacoes", icon: Headphones },
  { title: "Chamados", url: "/chamados", icon: MessageSquare },
  { title: "Ordens de Serviço", url: "/ordens-servico", icon: ClipboardList },
  { title: "Colaboradores", url: "/colaboradores", icon: UserCheck },
  { title: "Diaristas", url: "/diaristas", icon: UserCircle },
  { title: "Escalas", url: "/escalas", icon: Calendar },
  { title: "Ativos", url: "/ativos", icon: Package },
  { title: "Estoque", url: "/estoque", icon: Package },
  { title: "Gestão de Usuários", url: "/users", icon: Users },
];

export function AppSidebar() {
  const { open } = useSidebar();
  const location = useLocation();
  const navigate = useNavigate();
  const currentPath = location.pathname;

  const isActive = (path: string) => currentPath === path;

  const handleLogout = async () => {
    await supabase.auth.signOut();
    toast.success("Logout realizado com sucesso");
    navigate("/auth");
  };

  return (
    <Sidebar className={open ? "w-64" : "w-16"} collapsible="icon">
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel className={!open ? "hidden" : ""}>
            Facilities Center
          </SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {menuItems.map((item) => (
                <SidebarMenuItem key={item.title}>
                  <SidebarMenuButton asChild isActive={isActive(item.url)}>
                    <NavLink 
                      to={item.url} 
                      end
                      className="flex items-center gap-3 hover:bg-accent"
                      activeClassName="bg-accent text-accent-foreground font-medium"
                    >
                      <item.icon className="h-5 w-5" />
                      {open && <span>{item.title}</span>}
                    </NavLink>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
              
              {/* Botão de Sair */}
              <SidebarMenuItem>
                <SidebarMenuButton onClick={handleLogout}>
                  <LogOut className="h-5 w-5" />
                  {open && <span>Sair</span>}
                </SidebarMenuButton>
              </SidebarMenuItem>
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
    </Sidebar>
  );
}
