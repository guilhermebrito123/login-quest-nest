import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { ProtectedRoute } from "@/components/ProtectedRoute";
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
import Ativos from "./pages/Ativos";
import Estoque from "./pages/Estoque";
import Diaristas from "./pages/Diaristas";
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
          <Route path="/dashboard" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
          <Route path="/dashboard-24h" element={<ProtectedRoute><Dashboard24h /></ProtectedRoute>} />
          <Route path="/users" element={<ProtectedRoute><UserManagement /></ProtectedRoute>} />
          <Route path="/contratos" element={<ProtectedRoute><Contratos /></ProtectedRoute>} />
          <Route path="/mesa-operacoes" element={<ProtectedRoute><MesaOperacoes /></ProtectedRoute>} />
          <Route path="/chamados" element={<ProtectedRoute><Chamados /></ProtectedRoute>} />
          <Route path="/ordens-servico" element={<ProtectedRoute><OrdensServico /></ProtectedRoute>} />
          <Route path="/colaboradores" element={<ProtectedRoute><Colaboradores /></ProtectedRoute>} />
          <Route path="/escalas" element={<ProtectedRoute><Escalas /></ProtectedRoute>} />
          <Route path="/ativos" element={<ProtectedRoute><Ativos /></ProtectedRoute>} />
          <Route path="/estoque" element={<ProtectedRoute><Estoque /></ProtectedRoute>} />
          <Route path="/diaristas" element={<ProtectedRoute><Diaristas /></ProtectedRoute>} />
          {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
