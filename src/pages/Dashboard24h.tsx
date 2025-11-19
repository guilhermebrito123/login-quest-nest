import { useEffect, useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { DashboardLayout } from "@/components/DashboardLayout";
import { 
  TrendingUp, 
  AlertTriangle, 
  MessageSquare, 
  Users, 
  ClipboardCheck, 
  Star,
  MapPin,
  Calendar
} from "lucide-react";
import { toast } from "sonner";
import mapboxgl from "mapbox-gl";
import "mapbox-gl/dist/mapbox-gl.css";

interface UnidadeComDados {
  id: string;
  nome: string;
  codigo: string;
  latitude: number;
  longitude: number;
  cidade: string;
  uf: string;
  criticidade: string;
  contrato: {
    nome: string;
    cliente: {
      razao_social: string;
    };
  };
  sla_atual: number;
  chamados_abertos: number;
  nps_atual: number;
  postos_vagos: number;
  total_postos: number;
}

interface Alerta {
  id: string;
  timestamp: string;
  tipo: string;
  cliente: string;
  unidade: string;
  status: string;
  severidade: string;
  descricao: string;
}

export default function Dashboard24h() {
  const navigate = useNavigate();
  const mapContainer = useRef<HTMLDivElement>(null);
  const map = useRef<mapboxgl.Map | null>(null);
  
  const [unidades, setUnidades] = useState<UnidadeComDados[]>([]);
  const [alertas, setAlertas] = useState<Alerta[]>([]);
  const [loading, setLoading] = useState(true);
  const [userRole, setUserRole] = useState<string | null>(null);
  
  // Filters
  const [selectedCliente, setSelectedCliente] = useState<string>("all");
  const [selectedContrato, setSelectedContrato] = useState<string>("all");
  const [selectedUnidade, setSelectedUnidade] = useState<string>("all");
  const [selectedSeveridade, setSelectedSeveridade] = useState<string>("all");
  
  // Stats
  const [stats, setStats] = useState({
    sla_dia: 0,
    incidentes_critico: 0,
    incidentes_alto: 0,
    incidentes_medio: 0,
    chamados_urgente: 0,
    chamados_alto: 0,
    chamados_medio: 0,
    postos_cobertos: 0,
    postos_total: 0,
    variacao_presenca: 0,
    preventivas_prazo: 0,
    nps_7d: 0,
    nps_30d: 0
  });

  useEffect(() => {
    checkUserAndLoadData();
  }, []);

  useEffect(() => {
    if (unidades.length > 0) {
      initializeMap();
    }
  }, [unidades]);

  const checkUserAndLoadData = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        navigate("/auth");
        return;
      }

      // Get user role
      const { data: roleData } = await supabase
        .from("user_roles")
        .select("role")
        .eq("user_id", user.id)
        .single();

      setUserRole(roleData?.role || null);
      
      await Promise.all([
        loadUnidades(roleData?.role),
        loadStats(roleData?.role),
        loadAlertas(roleData?.role)
      ]);
    } catch (error) {
      console.error("Error:", error);
      toast.error("Erro ao carregar dados");
    } finally {
      setLoading(false);
    }
  };

  const loadUnidades = async (role: string | null) => {
    try {
      let query = supabase
        .from("unidades")
        .select(`
          id,
          nome,
          codigo,
          latitude,
          longitude,
          cidade,
          uf,
          criticidade,
          contrato_id,
          contratos (
            nome,
            cliente_id,
            clientes (
              razao_social
            )
          )
        `)
        .eq("status", "ativo")
        .not("latitude", "is", null)
        .not("longitude", "is", null);

      const { data: unidadesData, error } = await query;
      if (error) throw error;

      // Calculate data for each unit
      const unidadesComDados = await Promise.all(
        (unidadesData || []).map(async (unidade: any) => {
          const [sla, chamados, nps, postosData] = await Promise.all([
            calculateSLA(unidade.id),
            countChamadosAbertos(unidade.id),
            calculateNPS(unidade.id),
            getPostosInfo(unidade.id)
          ]);

          return {
            id: unidade.id,
            nome: unidade.nome,
            codigo: unidade.codigo,
            latitude: Number(unidade.latitude),
            longitude: Number(unidade.longitude),
            cidade: unidade.cidade || "",
            uf: unidade.uf || "",
            criticidade: unidade.criticidade,
            contrato: {
              nome: unidade.contratos?.nome || "Sem contrato",
              cliente: {
                razao_social: unidade.contratos?.clientes?.razao_social || "Sem cliente"
              }
            },
            sla_atual: sla,
            chamados_abertos: chamados,
            nps_atual: nps,
            postos_vagos: postosData.vagos,
            total_postos: postosData.total
          };
        })
      );

      setUnidades(unidadesComDados);
    } catch (error: any) {
      console.error("Error loading unidades:", error);
      toast.error("Erro ao carregar unidades");
    }
  };

  const getPostosInfo = async (unidadeId: string) => {
    try {
      // Get all postos for this unit
      const { data: postos, error: postosError } = await supabase
        .from("postos_servico")
        .select("id, escala")
        .eq("unidade_id", unidadeId)
        .eq("status", "ativo");

      if (postosError) throw postosError;

      if (!postos || postos.length === 0) {
        return { total: 0, vagos: 0, cobertos: 0 };
      }

      let totalVagos = 0;
      let totalPostos = 0;

      // For each posto, check how many colaboradores are assigned
      for (const posto of postos) {
        const efetivoNecessario = posto.escala === '12x36' ? 4 : 1;
        totalPostos += efetivoNecessario;

        const { count: colaboradoresCount } = await supabase
          .from("colaboradores")
          .select("id", { count: "exact", head: true })
          .eq("posto_servico_id", posto.id)
          .eq("status", "ativo");

        const vagos = Math.max(0, efetivoNecessario - (colaboradoresCount || 0));
        totalVagos += vagos;
      }

      return { 
        total: totalPostos, 
        vagos: totalVagos,
        cobertos: totalPostos - totalVagos
      };
    } catch (error) {
      console.error("Error getting postos info:", error);
      return { total: 0, vagos: 0, cobertos: 0 };
    }
  };

  const calculateSLA = async (unidadeId: string): Promise<number> => {
    const { data } = await supabase
      .from("ordens_servico")
      .select("status")
      .eq("unidade_id", unidadeId);

    if (!data || data.length === 0) return 100;

    const concluidas = data.filter((os) => os.status === "concluida").length;
    return Math.round((concluidas / data.length) * 100);
  };

  const countChamadosAbertos = async (unidadeId: string): Promise<number> => {
    const { count } = await supabase
      .from("chamados")
      .select("*", { count: "exact", head: true })
      .eq("unidade_id", unidadeId)
      .in("status", ["aberto", "em_andamento"]);

    return count || 0;
  };

  const calculateNPS = async (unidadeId: string): Promise<number> => {
    const { data } = await supabase
      .from("chamados")
      .select("avaliacao")
      .eq("unidade_id", unidadeId)
      .not("avaliacao", "is", null)
      .gte("created_at", new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString());

    if (!data || data.length === 0) return 0;

    const promotores = data.filter(c => c.avaliacao >= 9).length;
    const detratores = data.filter(c => c.avaliacao <= 6).length;
    
    return Math.round(((promotores - detratores) / data.length) * 100);
  };

  const loadStats = async (role: string | null) => {
    try {
      // SLA do dia
      const { data: osHoje } = await supabase
        .from("ordens_servico")
        .select("status")
        .gte("data_abertura", new Date().toISOString().split("T")[0]);

      const slaDia = osHoje && osHoje.length > 0
        ? Math.round((osHoje.filter(os => os.status === "concluida").length / osHoje.length) * 100)
        : 100;

      // Incidentes por severidade
      const { data: incidentes } = await supabase
        .from("incidentes")
        .select("severidade")
        .in("status", ["aberto", "em_investigacao"]);

      // Chamados por prioridade
      const { data: chamados } = await supabase
        .from("chamados")
        .select("prioridade")
        .in("status", ["aberto", "em_andamento"]);

      // Postos cobertos
      const { data: postos } = await supabase
        .from("postos_servico")
        .select("id, escala")
        .eq("status", "ativo");

      let totalPostos = 0;
      let postosCobertos = 0;

      if (postos) {
        for (const posto of postos) {
          const efetivo = posto.escala === '12x36' ? 4 : 1;
          totalPostos += efetivo;

          const { count } = await supabase
            .from("colaboradores")
            .select("*", { count: "exact", head: true })
            .eq("posto_servico_id", posto.id)
            .eq("status", "ativo");

          postosCobertos += Math.min(efetivo, count || 0);
        }
      }

      // Preventivas no prazo
      const { data: preventivas } = await supabase
        .from("ordens_servico")
        .select("data_prevista, data_conclusao")
        .eq("tipo", "preventiva")
        .eq("status", "concluida")
        .gte("created_at", new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString());

      const preventivasNoPrazo = preventivas
        ? preventivas.filter(p => 
            p.data_conclusao && p.data_prevista && 
            new Date(p.data_conclusao) <= new Date(p.data_prevista)
          ).length
        : 0;

      const preventivasPrazo = preventivas && preventivas.length > 0
        ? Math.round((preventivasNoPrazo / preventivas.length) * 100)
        : 100;

      // NPS 7d e 30d
      const { data: avaliacoes7d } = await supabase
        .from("chamados")
        .select("avaliacao")
        .not("avaliacao", "is", null)
        .gte("created_at", new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString());

      const { data: avaliacoes30d } = await supabase
        .from("chamados")
        .select("avaliacao")
        .not("avaliacao", "is", null)
        .gte("created_at", new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString());

      const calcNPS = (data: any[]) => {
        if (!data || data.length === 0) return 0;
        const promotores = data.filter(c => c.avaliacao >= 9).length;
        const detratores = data.filter(c => c.avaliacao <= 6).length;
        return Math.round(((promotores - detratores) / data.length) * 100);
      };

      setStats({
        sla_dia: slaDia,
        incidentes_critico: incidentes?.filter(i => i.severidade === "critica").length || 0,
        incidentes_alto: incidentes?.filter(i => i.severidade === "alta").length || 0,
        incidentes_medio: incidentes?.filter(i => i.severidade === "media").length || 0,
        chamados_urgente: chamados?.filter(c => c.prioridade === "urgente").length || 0,
        chamados_alto: chamados?.filter(c => c.prioridade === "alta").length || 0,
        chamados_medio: chamados?.filter(c => c.prioridade === "media").length || 0,
        postos_cobertos: postosCobertos,
        postos_total: totalPostos,
        variacao_presenca: 95, // TODO: Calculate real value
        preventivas_prazo: preventivasPrazo,
        nps_7d: calcNPS(avaliacoes7d || []),
        nps_30d: calcNPS(avaliacoes30d || [])
      });
    } catch (error) {
      console.error("Error loading stats:", error);
    }
  };

  const loadAlertas = async (role: string | null) => {
    try {
      // Get recent incidents and chamados
      const { data: incidentes } = await supabase
        .from("incidentes")
        .select(`
          id,
          numero,
          titulo,
          severidade,
          status,
          created_at,
          unidade:unidades(nome),
          cliente:unidades(contratos(clientes(razao_social)))
        `)
        .in("status", ["aberto", "em_investigacao"])
        .order("created_at", { ascending: false })
        .limit(10);

      const { data: chamados } = await supabase
        .from("chamados")
        .select(`
          id,
          numero,
          titulo,
          prioridade,
          status,
          created_at,
          unidade:unidades(nome),
          cliente:unidades(contratos(clientes(razao_social)))
        `)
        .in("status", ["aberto", "em_andamento"])
        .order("created_at", { ascending: false })
        .limit(10);

      const alertasFormatados: Alerta[] = [
        ...(incidentes || []).map(inc => ({
          id: inc.id,
          timestamp: inc.created_at,
          tipo: "Incidente",
          cliente: inc.cliente?.contratos?.clientes?.razao_social || "N/A",
          unidade: inc.unidade?.nome || "N/A",
          status: inc.status,
          severidade: inc.severidade,
          descricao: inc.titulo
        })),
        ...(chamados || []).map(ch => ({
          id: ch.id,
          timestamp: ch.created_at,
          tipo: "Chamado",
          cliente: ch.cliente?.contratos?.clientes?.razao_social || "N/A",
          unidade: ch.unidade?.nome || "N/A",
          status: ch.status,
          severidade: ch.prioridade,
          descricao: ch.titulo
        }))
      ].sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

      setAlertas(alertasFormatados);
    } catch (error) {
      console.error("Error loading alertas:", error);
    }
  };

  const initializeMap = async () => {
    if (!mapContainer.current || map.current) return;

    try {
      // Get Mapbox token from edge function
      const { data: tokenData, error: tokenError } = await supabase.functions.invoke("get-mapbox-token");
      
      if (tokenError || !tokenData?.token) {
        toast.error("Erro ao carregar token do Mapbox");
        return;
      }

      mapboxgl.accessToken = tokenData.token;

      map.current = new mapboxgl.Map({
        container: mapContainer.current,
        style: "mapbox://styles/mapbox/light-v11",
        center: [-47.9292, -15.7801], // Brasília center
        zoom: 4,
      });

      map.current.addControl(new mapboxgl.NavigationControl(), "top-right");

      // Add markers for each unit
      unidades.forEach((unidade) => {
        if (!map.current) return;

        const color = getSLAColor(unidade.sla_atual);
        
        const el = document.createElement("div");
        el.className = "marker";
        el.style.backgroundColor = color;
        el.style.width = "30px";
        el.style.height = "30px";
        el.style.borderRadius = "50%";
        el.style.border = "3px solid white";
        el.style.cursor = "pointer";
        el.style.boxShadow = "0 2px 6px rgba(0,0,0,0.3)";
        el.style.display = "flex";
        el.style.alignItems = "center";
        el.style.justifyContent = "center";
        el.style.fontSize = "12px";
        el.style.fontWeight = "bold";
        el.style.color = "white";
        el.textContent = unidade.postos_vagos > 0 ? String(unidade.postos_vagos) : "";

        const marker = new mapboxgl.Marker(el)
          .setLngLat([unidade.longitude, unidade.latitude])
          .addTo(map.current);

        const popup = new mapboxgl.Popup({ offset: 25 }).setHTML(
          `<div style="padding: 12px; min-width: 200px;">
            <h3 style="font-weight: bold; margin-bottom: 8px; font-size: 14px;">${unidade.nome}</h3>
            <p style="font-size: 12px; color: #666; margin-bottom: 8px;">${unidade.cidade}/${unidade.uf}</p>
            <div style="display: flex; flex-direction: column; gap: 4px; font-size: 12px;">
              <div><strong>Cliente:</strong> ${unidade.contrato.cliente.razao_social}</div>
              <div><strong>SLA:</strong> <span style="color: ${color}; font-weight: bold;">${unidade.sla_atual}%</span></div>
              <div><strong>Chamados Abertos:</strong> ${unidade.chamados_abertos}</div>
              <div><strong>NPS:</strong> ${unidade.nps_atual}</div>
              <div style="margin-top: 4px; padding-top: 4px; border-top: 1px solid #eee;">
                <strong>Postos Vagos:</strong> <span style="color: ${unidade.postos_vagos > 0 ? '#ef4444' : '#22c55e'}; font-weight: bold;">${unidade.postos_vagos}/${unidade.total_postos}</span>
              </div>
            </div>
          </div>`
        );

        marker.setPopup(popup);
      });
    } catch (error) {
      console.error("Error initializing map:", error);
      toast.error("Erro ao inicializar mapa");
    }
  };

  const getSLAColor = (sla: number): string => {
    if (sla >= 100) return "#22c55e";
    if (sla >= 90) return "#eab308";
    return "#ef4444";
  };

  const getSeveridadeColor = (severidade: string): string => {
    const colors: Record<string, string> = {
      critica: "destructive",
      urgente: "destructive",
      alta: "destructive",
      media: "secondary",
      baixa: "default"
    };
    return colors[severidade] || "default";
  };

  if (loading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center h-screen">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4"></div>
            <p className="text-muted-foreground">Carregando dashboard...</p>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="min-h-screen bg-background p-6 space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold">Dashboard 24/7 – Resumo Executivo</h1>
            <p className="text-muted-foreground">Monitoramento em tempo real</p>
          </div>
          <div className="flex items-center gap-2">
            <Calendar className="h-4 w-4 text-muted-foreground" />
            <span className="text-sm text-muted-foreground">
              {new Date().toLocaleDateString("pt-BR", { 
                weekday: "long", 
                year: "numeric", 
                month: "long", 
                day: "numeric" 
              })}
            </span>
          </div>
        </div>

        {/* Filters */}
        <Card>
          <CardContent className="pt-6">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <Select value={selectedCliente} onValueChange={setSelectedCliente}>
                <SelectTrigger>
                  <SelectValue placeholder="Cliente" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Todos os Clientes</SelectItem>
                </SelectContent>
              </Select>
              <Select value={selectedContrato} onValueChange={setSelectedContrato}>
                <SelectTrigger>
                  <SelectValue placeholder="Contrato" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Todos os Contratos</SelectItem>
                </SelectContent>
              </Select>
              <Select value={selectedUnidade} onValueChange={setSelectedUnidade}>
                <SelectTrigger>
                  <SelectValue placeholder="Unidade" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Todas as Unidades</SelectItem>
                </SelectContent>
              </Select>
              <Select value={selectedSeveridade} onValueChange={setSelectedSeveridade}>
                <SelectTrigger>
                  <SelectValue placeholder="Severidade" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Todas as Severidades</SelectItem>
                  <SelectItem value="critica">Crítica</SelectItem>
                  <SelectItem value="alta">Alta</SelectItem>
                  <SelectItem value="media">Média</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </CardContent>
        </Card>

        {/* Main Stats */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <Card>
            <CardHeader className="pb-3">
              <CardDescription>SLA do Dia</CardDescription>
              <div className="flex items-center justify-between">
                <CardTitle className="text-3xl" style={{ color: getSLAColor(stats.sla_dia) }}>
                  {stats.sla_dia}%
                </CardTitle>
                <TrendingUp className="h-5 w-5" style={{ color: getSLAColor(stats.sla_dia) }} />
              </div>
            </CardHeader>
          </Card>

          <Card>
            <CardHeader className="pb-3">
              <CardDescription>Postos Cobertos</CardDescription>
              <div className="flex items-center justify-between">
                <CardTitle className="text-3xl">
                  {stats.postos_cobertos}/{stats.postos_total}
                </CardTitle>
                <Users className="h-5 w-5 text-primary" />
              </div>
              <p className="text-xs text-muted-foreground">
                {stats.postos_total > 0 
                  ? Math.round((stats.postos_cobertos / stats.postos_total) * 100) 
                  : 0}% de cobertura
              </p>
            </CardHeader>
          </Card>

          <Card>
            <CardHeader className="pb-3">
              <CardDescription>Preventivas no Prazo</CardDescription>
              <div className="flex items-center justify-between">
                <CardTitle className="text-3xl text-green-600">
                  {stats.preventivas_prazo}%
                </CardTitle>
                <ClipboardCheck className="h-5 w-5 text-green-600" />
              </div>
            </CardHeader>
          </Card>

          <Card>
            <CardHeader className="pb-3">
              <CardDescription>NPS (7d / 30d)</CardDescription>
              <div className="flex items-center justify-between">
                <CardTitle className="text-3xl">
                  {stats.nps_7d} / {stats.nps_30d}
                </CardTitle>
                <Star className="h-5 w-5 text-yellow-500" />
              </div>
            </CardHeader>
          </Card>
        </div>

        {/* Incidentes e Chamados */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <AlertTriangle className="h-5 w-5 text-destructive" />
                Incidentes por Severidade
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-sm">Crítico</span>
                <Badge variant="destructive">{stats.incidentes_critico}</Badge>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm">Alto</span>
                <Badge variant="destructive">{stats.incidentes_alto}</Badge>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm">Médio</span>
                <Badge variant="secondary">{stats.incidentes_medio}</Badge>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <MessageSquare className="h-5 w-5 text-primary" />
                Chamados por Prioridade
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-sm">Urgente</span>
                <Badge variant="destructive">{stats.chamados_urgente}</Badge>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm">Alta</span>
                <Badge variant="destructive">{stats.chamados_alto}</Badge>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm">Média</span>
                <Badge variant="secondary">{stats.chamados_medio}</Badge>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Map and Alerts */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Map */}
          <Card className="h-[500px]">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <MapPin className="h-5 w-5" />
                Mapa de Unidades
              </CardTitle>
              <CardDescription>
                Verde = 100% | Amarelo = &lt;100% | Vermelho = &lt;90%
                <br />
                Números indicam postos vagos
              </CardDescription>
            </CardHeader>
            <CardContent className="h-[calc(100%-100px)]">
              <div ref={mapContainer} className="w-full h-full rounded-lg" />
            </CardContent>
          </Card>

          {/* Alerts Feed */}
          <Card className="h-[500px]">
            <CardHeader>
              <CardTitle>Feed de Alertas ao Vivo</CardTitle>
              <CardDescription>Atualizações em tempo real</CardDescription>
            </CardHeader>
            <CardContent className="h-[calc(100%-100px)] overflow-y-auto space-y-3">
              {alertas.map((alerta) => (
                <div
                  key={alerta.id}
                  className={`p-3 rounded-lg border ${
                    alerta.severidade === "critica" || alerta.severidade === "urgente"
                      ? "bg-red-50 border-red-200"
                      : alerta.severidade === "alta"
                      ? "bg-yellow-50 border-yellow-200"
                      : "bg-background border-border"
                  }`}
                >
                  <div className="flex items-start justify-between mb-2">
                    <Badge variant={getSeveridadeColor(alerta.severidade) as any}>
                      {alerta.tipo}
                    </Badge>
                    <span className="text-xs text-muted-foreground">
                      {new Date(alerta.timestamp).toLocaleTimeString("pt-BR")}
                    </span>
                  </div>
                  <p className="text-sm font-medium mb-1">{alerta.descricao}</p>
                  <div className="text-xs text-muted-foreground space-y-1">
                    <div><strong>Cliente:</strong> {alerta.cliente}</div>
                    <div><strong>Unidade:</strong> {alerta.unidade}</div>
                    <div><strong>Status:</strong> {alerta.status}</div>
                  </div>
                  <Button size="sm" variant="outline" className="w-full mt-2">
                    Ver Detalhes
                  </Button>
                </div>
              ))}
            </CardContent>
          </Card>
        </div>
      </div>
    </DashboardLayout>
  );
}
