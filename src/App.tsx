import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Index from "./pages/Index";
import Auth from "./pages/Auth";
import Dashboard from "./pages/Dashboard";
import Dashboard24h from "./pages/Dashboard24h";
import UserManagement from "./pages/UserManagement";
import ResetPassword from "./pages/ResetPassword";
import Chamados from "./pages/Chamados";
import Contratos from "./pages/Contratos";
import MesaOperacoes from "./pages/MesaOperacoes";
import OrdensServico from "./pages/OrdensServico";
import Colaboradores from "./pages/Colaboradores";
import Escalas from "./pages/Escalas";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Index />} />
          <Route path="/auth" element={<Auth />} />
          <Route path="/reset-password" element={<ResetPassword />} />
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/dashboard-24h" element={<Dashboard24h />} />
          <Route path="/users" element={<UserManagement />} />
          <Route path="/contratos" element={<Contratos />} />
          <Route path="/mesa-operacoes" element={<MesaOperacoes />} />
          <Route path="/chamados" element={<Chamados />} />
          <Route path="/ordens-servico" element={<OrdensServico />} />
            <Route path="/colaboradores" element={<Colaboradores />} />
            <Route path="/escalas" element={<Escalas />} />
          {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
