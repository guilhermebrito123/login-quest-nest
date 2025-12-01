import { useState, useEffect } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { toast } from "@/hooks/use-toast";
import { Loader2 } from "lucide-react";

interface UnidadeFormProps {
  unidadeId?: string;
  contratoId?: string | null;
  onClose: () => void;
  onSuccess: () => void;
}

const UnidadeForm = ({ unidadeId, contratoId, onClose, onSuccess }: UnidadeFormProps) => {
  const [loading, setLoading] = useState(false);
  const [contratos, setContratos] = useState<any[]>([]);
  const [formData, setFormData] = useState({
    contrato_id: contratoId || "",
    nome: "",
    endereco: "",
    cidade: "",
    uf: "",
    cep: "",
    latitude: "",
    longitude: "",
  });

  useEffect(() => {
    loadContratos();
    if (unidadeId) {
      loadUnidade();
    }
  }, [unidadeId]);

  const loadContratos = async () => {
    const { data } = await supabase
      .from("contratos")
      .select("id, negocio")
      .order("negocio");
    setContratos(data || []);
  };

  const loadUnidade = async () => {
    if (!unidadeId) return;
    
    const { data, error } = await supabase
      .from("unidades")
      .select("*")
      .eq("id", unidadeId)
      .single();

    if (error) {
      toast({
        title: "Erro ao carregar unidade",
        description: error.message,
        variant: "destructive",
      });
      return;
    }

    if (data) {
      setFormData({
        contrato_id: data.contrato_id || "",
        nome: data.nome,
        endereco: data.endereco || "",
        cidade: data.cidade || "",
        uf: data.uf || "",
        cep: data.cep || "",
        latitude: data.latitude ? String(data.latitude) : "",
        longitude: data.longitude ? String(data.longitude) : "",
      });
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Convert latitude and longitude to numbers or null
      const payload = {
        ...formData,
        latitude: formData.latitude ? parseFloat(formData.latitude) : null,
        longitude: formData.longitude ? parseFloat(formData.longitude) : null,
      };

      if (unidadeId) {
        const { error } = await supabase
          .from("unidades")
          .update(payload)
          .eq("id", unidadeId);

        if (error) throw error;

        toast({
          title: "Unidade atualizada",
          description: "Unidade atualizada com sucesso",
        });
      } else {
        const { error } = await supabase
          .from("unidades")
          .insert([payload]);

        if (error) throw error;

        toast({
          title: "Unidade criada",
          description: "Unidade criada com sucesso",
        });
      }

      onSuccess();
    } catch (error: any) {
      toast({
        title: "Erro",
        description: error.message,
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open onOpenChange={onClose}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>{unidadeId ? "Editar Unidade" : "Nova Unidade"}</DialogTitle>
          <DialogDescription>
            Preencha os dados da unidade
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2 col-span-2">
              <Label htmlFor="contrato_id">Contrato *</Label>
              <Select
                value={formData.contrato_id}
                onValueChange={(value) =>
                  setFormData({ ...formData, contrato_id: value })
                }
                disabled={!!contratoId}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Selecione um contrato" />
                </SelectTrigger>
                <SelectContent>
                  {contratos.map((contrato) => (
                    <SelectItem key={contrato.id} value={contrato.id}>
                      {contrato.nome}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2 col-span-2">
              <Label htmlFor="nome">Nome da Unidade *</Label>
              <Input
                id="nome"
                value={formData.nome}
                onChange={(e) =>
                  setFormData({ ...formData, nome: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2 col-span-2">
              <Label htmlFor="endereco">Endereço</Label>
              <Input
                id="endereco"
                value={formData.endereco}
                onChange={(e) =>
                  setFormData({ ...formData, endereco: e.target.value })
                }
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="cidade">Cidade</Label>
              <Input
                id="cidade"
                value={formData.cidade}
                onChange={(e) =>
                  setFormData({ ...formData, cidade: e.target.value })
                }
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="uf">UF</Label>
              <Input
                id="uf"
                value={formData.uf}
                onChange={(e) =>
                  setFormData({ ...formData, uf: e.target.value.toUpperCase() })
                }
                maxLength={2}
                placeholder="SP"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="cep">CEP</Label>
              <Input
                id="cep"
                value={formData.cep}
                onChange={(e) =>
                  setFormData({ ...formData, cep: e.target.value })
                }
                placeholder="00000-000"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="latitude">Latitude</Label>
              <Input
                id="latitude"
                type="number"
                step="any"
                value={formData.latitude}
                onChange={(e) =>
                  setFormData({ ...formData, latitude: e.target.value })
                }
                placeholder="-15.7801"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="longitude">Longitude</Label>
              <Input
                id="longitude"
                type="number"
                step="any"
                value={formData.longitude}
                onChange={(e) =>
                  setFormData({ ...formData, longitude: e.target.value })
                }
                placeholder="-47.9292"
              />
            </div>

          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit" disabled={loading}>
              {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {unidadeId ? "Atualizar" : "Criar"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default UnidadeForm;
