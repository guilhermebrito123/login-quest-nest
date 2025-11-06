import { useEffect, useState, useRef } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { MapPin, AlertCircle, TrendingUp, Activity } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { toast } from "@/hooks/use-toast";
import { DashboardLayout } from "@/components/DashboardLayout";
import mapboxgl from "mapbox-gl";
import "mapbox-gl/dist/mapbox-gl.css";

interface UnidadeComSLA {
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
    sla_alvo_pct: number;
  };
  sla_atual: number;
}

const MesaOperacoes = () => {
  const navigate = useNavigate();
  const mapContainer = useRef<HTMLDivElement>(null);
  const map = useRef<mapboxgl.Map | null>(null);
  const [unidades, setUnidades] = useState<UnidadeComSLA[]>([]);
  const [selectedUnidade, setSelectedUnidade] = useState<UnidadeComSLA | null>(null);
  const [loading, setLoading] = useState(true);
  const [mapboxToken, setMapboxToken] = useState("");

  useEffect(() => {
    fetchUnidades();
    fetchMapboxToken();
  }, []);

  const fetchMapboxToken = async () => {
    try {
      const { data, error } = await supabase.functions.invoke('get-mapbox-token');
      
      if (error) throw error;
      
      if (data?.token) {
        setMapboxToken(data.token);
      } else {
        toast({
          title: "Token do Mapbox não configurado",
          description: "Configure o token MAPBOX_PUBLIC_TOKEN nos secrets do projeto",
          variant: "destructive",
        });
      }
    } catch (error: any) {
      console.error('Erro ao buscar token do Mapbox:', error);
      toast({
        title: "Erro ao carregar token do Mapbox",
        description: "Usando formulário manual",
        variant: "destructive",
      });
    }
  };

  useEffect(() => {
    if (mapboxToken && unidades.length > 0 && mapContainer.current && !map.current) {
      initializeMap();
    }
  }, [mapboxToken, unidades]);

  const fetchUnidades = async () => {
    try {
      // Fetch unidades com contratos
      const { data: unidadesData, error: unidadesError } = await supabase
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
          status,
          contrato_id,
          contratos (
            nome,
            sla_alvo_pct
          )
        `)
        .eq("status", "ativo")
        .not("latitude", "is", null)
        .not("longitude", "is", null);

      if (unidadesError) throw unidadesError;

      // Calculate SLA for each unidade
      const unidadesComSLA = await Promise.all(
        (unidadesData || []).map(async (unidade) => {
          const sla = await calculateSLA(unidade.id);
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
              sla_alvo_pct: Number(unidade.contratos?.sla_alvo_pct || 95),
            },
            sla_atual: sla,
          };
        })
      );

      setUnidades(unidadesComSLA);
    } catch (error: any) {
      toast({
        title: "Erro ao carregar unidades",
        description: error.message,
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const calculateSLA = async (unidadeId: string): Promise<number> => {
    // Simplified SLA calculation based on OS completion rate
    const { data: osData } = await supabase
      .from("ordens_servico")
      .select("status")
      .eq("unidade_id", unidadeId);

    if (!osData || osData.length === 0) return 100;

    const concluidas = osData.filter((os) => os.status === "concluida").length;
    return Math.round((concluidas / osData.length) * 100);
  };

  const getSLAColor = (sla: number): string => {
    if (sla >= 100) return "#22c55e"; // green
    if (sla >= 90) return "#eab308"; // yellow
    return "#ef4444"; // red
  };

  const getSLABadgeVariant = (sla: number): "default" | "secondary" | "destructive" => {
    if (sla >= 100) return "default";
    if (sla >= 90) return "secondary";
    return "destructive";
  };

  const initializeMap = () => {
    if (!mapContainer.current) return;

    mapboxgl.accessToken = mapboxToken;

    map.current = new mapboxgl.Map({
      container: mapContainer.current,
      style: "mapbox://styles/mapbox/light-v11",
      center: [-47.9292, -15.7801], // Brasília, Brasil
      zoom: 4,
    });

    map.current.addControl(new mapboxgl.NavigationControl(), "top-right");

    // Add markers for each unidade
    unidades.forEach((unidade) => {
      if (!map.current) return;

      const el = document.createElement("div");
      el.className = "marker";
      el.style.backgroundColor = getSLAColor(unidade.sla_atual);
      el.style.width = "24px";
      el.style.height = "24px";
      el.style.borderRadius = "50%";
      el.style.border = "3px solid white";
      el.style.cursor = "pointer";
      el.style.boxShadow = "0 2px 4px rgba(0,0,0,0.3)";

      const marker = new mapboxgl.Marker(el)
        .setLngLat([unidade.longitude, unidade.latitude])
        .addTo(map.current);

      el.addEventListener("click", () => {
        setSelectedUnidade(unidade);
      });

      // Add popup
      const popup = new mapboxgl.Popup({ offset: 25 }).setHTML(
        `<div style="padding: 8px;">
          <h3 style="font-weight: bold; margin-bottom: 4px;">${unidade.nome}</h3>
          <p style="font-size: 12px; color: #666;">${unidade.cidade}/${unidade.uf}</p>
          <p style="font-size: 12px; margin-top: 4px;">SLA: <strong>${unidade.sla_atual}%</strong></p>
        </div>`
      );

      marker.setPopup(popup);
    });
  };

  const handleTokenSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    const token = formData.get("token") as string;
    if (token) {
      setMapboxToken(token);
      toast({
        title: "Token configurado",
        description: "Carregando mapa...",
      });
    }
  };

  const statsData = {
    total: unidades.length,
    slaVerde: unidades.filter((u) => u.sla_atual >= 100).length,
    slaAmarelo: unidades.filter((u) => u.sla_atual >= 90 && u.sla_atual < 100).length,
    slaVermelho: unidades.filter((u) => u.sla_atual < 90).length,
    criticas: unidades.filter((u) => u.criticidade === "critica").length,
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="text-center">
          <Activity className="h-8 w-8 animate-spin mx-auto mb-2" />
          <p className="text-muted-foreground">Carregando dados...</p>
        </div>
      </div>
    );
  }

  if (!mapboxToken) {
    return (
      <DashboardLayout>
        <div className="container mx-auto p-6">
          <Card className="max-w-md mx-auto mt-20">
            <CardHeader>
              <CardTitle>Carregando Mapa</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-center py-8">
                <Activity className="h-8 w-8 animate-spin mx-auto mb-4" />
                <p className="text-sm text-muted-foreground">
                  Carregando token do Mapbox...
                </p>
              </div>
              
              <div className="mt-6 border-t pt-6">
                <p className="text-sm text-muted-foreground mb-4">
                  Ou insira manualmente seu token público do Mapbox:
                </p>
                <form onSubmit={handleTokenSubmit} className="space-y-4">
                  <input
                    name="token"
                    type="text"
                    placeholder="pk.eyJ1..."
                    className="w-full px-3 py-2 border rounded-md"
                  />
                  <Button type="submit" className="w-full">
                    Usar Token Manual
                  </Button>
                </form>
              </div>
            </CardContent>
          </Card>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="h-screen flex flex-col">
      {/* Header */}
      <div className="border-b bg-background p-4">
        <div className="container mx-auto">
          <div className="mb-4">
            <h1 className="text-3xl font-bold">Mesa de Operações 24/7</h1>
            <p className="text-muted-foreground">Monitoramento em tempo real de todas as unidades</p>
          </div>

          {/* Stats Cards */}
          <div className="grid grid-cols-5 gap-4">
            <Card>
              <CardContent className="p-4">
                <div className="flex items-center gap-2">
                  <MapPin className="h-4 w-4 text-primary" />
                  <div>
                    <p className="text-2xl font-bold">{statsData.total}</p>
                    <p className="text-xs text-muted-foreground">Total Unidades</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="border-green-500/50">
              <CardContent className="p-4">
                <div className="flex items-center gap-2">
                  <TrendingUp className="h-4 w-4 text-green-500" />
                  <div>
                    <p className="text-2xl font-bold text-green-500">{statsData.slaVerde}</p>
                    <p className="text-xs text-muted-foreground">SLA 100%</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="border-yellow-500/50">
              <CardContent className="p-4">
                <div className="flex items-center gap-2">
                  <Activity className="h-4 w-4 text-yellow-500" />
                  <div>
                    <p className="text-2xl font-bold text-yellow-500">{statsData.slaAmarelo}</p>
                    <p className="text-xs text-muted-foreground">SLA 90-99%</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="border-red-500/50">
              <CardContent className="p-4">
                <div className="flex items-center gap-2">
                  <AlertCircle className="h-4 w-4 text-red-500" />
                  <div>
                    <p className="text-2xl font-bold text-red-500">{statsData.slaVermelho}</p>
                    <p className="text-xs text-muted-foreground">SLA &lt;90%</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="border-orange-500/50">
              <CardContent className="p-4">
                <div className="flex items-center gap-2">
                  <AlertCircle className="h-4 w-4 text-orange-500" />
                  <div>
                    <p className="text-2xl font-bold text-orange-500">{statsData.criticas}</p>
                    <p className="text-xs text-muted-foreground">Unidades Críticas</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>

      {/* Map and Details */}
      <div className="flex-1 flex overflow-hidden">
        {/* Map */}
        <div className="flex-1 relative">
          <div ref={mapContainer} className="absolute inset-0" />
        </div>

        {/* Sidebar with selected unidade details */}
        {selectedUnidade && (
          <div className="w-96 border-l bg-background p-6 overflow-y-auto">
            <div className="flex items-start justify-between mb-4">
              <div>
                <h2 className="text-xl font-bold">{selectedUnidade.nome}</h2>
                <p className="text-sm text-muted-foreground">{selectedUnidade.codigo}</p>
              </div>
              <Button variant="ghost" size="sm" onClick={() => setSelectedUnidade(null)}>
                ✕
              </Button>
            </div>

            <div className="space-y-4">
              <div>
                <p className="text-sm font-medium mb-1">Localização</p>
                <p className="text-sm text-muted-foreground">
                  {selectedUnidade.cidade}/{selectedUnidade.uf}
                </p>
              </div>

              <div>
                <p className="text-sm font-medium mb-1">Contrato</p>
                <p className="text-sm text-muted-foreground">{selectedUnidade.contrato.nome}</p>
              </div>

              <div>
                <p className="text-sm font-medium mb-2">SLA Atual</p>
                <div className="flex items-center gap-2">
                  <div className="flex-1 bg-secondary rounded-full h-2">
                    <div
                      className="h-2 rounded-full transition-all"
                      style={{
                        width: `${selectedUnidade.sla_atual}%`,
                        backgroundColor: getSLAColor(selectedUnidade.sla_atual),
                      }}
                    />
                  </div>
                  <Badge variant={getSLABadgeVariant(selectedUnidade.sla_atual)}>
                    {selectedUnidade.sla_atual}%
                  </Badge>
                </div>
                <p className="text-xs text-muted-foreground mt-1">
                  Meta: {selectedUnidade.contrato.sla_alvo_pct}%
                </p>
              </div>

              <div>
                <p className="text-sm font-medium mb-1">Criticidade</p>
                <Badge variant={selectedUnidade.criticidade === "critica" ? "destructive" : "default"}>
                  {selectedUnidade.criticidade}
                </Badge>
              </div>

              <Button className="w-full" onClick={() => navigate("/contratos")}>
                Ver Detalhes Completos
              </Button>
            </div>
          </div>
        )}
      </div>
    </div>
    </DashboardLayout>
  );
};

export default MesaOperacoes;
