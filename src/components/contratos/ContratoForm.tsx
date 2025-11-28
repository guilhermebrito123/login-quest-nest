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

interface ContratoFormProps {
  contratoId?: string;
  clienteId?: string | null;
  onClose: () => void;
  onSuccess: () => void;
}

const ContratoForm = ({ contratoId, clienteId, onClose, onSuccess }: ContratoFormProps) => {
  const [loading, setLoading] = useState(false);
  const [clientes, setClientes] = useState<any[]>([]);
  const [formData, setFormData] = useState({
    cliente_id: clienteId || "",
    nome: "",
    codigo: "",
    data_inicio: "",
    data_fim: "",
    sla_alvo_pct: "95",
    nps_meta: "",
    status: "ativo",
  });

  useEffect(() => {
    loadClientes();
  }, []);

  const loadClientes = async () => {
    const { data } = await supabase
      .from("clientes")
      .select("id, razao_social")
      .order("razao_social");
    setClientes(data || []);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const dataToSave = {
        ...formData,
        sla_alvo_pct: parseFloat(formData.sla_alvo_pct),
        nps_meta: formData.nps_meta ? parseFloat(formData.nps_meta) : null,
        data_fim: formData.data_fim || null,
      };

      if (contratoId) {
        const { error } = await supabase
          .from("contratos")
          .update(dataToSave)
          .eq("id", contratoId);

        if (error) throw error;

        toast({
          title: "Contrato atualizado",
          description: "Contrato atualizado com sucesso",
        });
      } else {
        const { error } = await supabase
          .from("contratos")
          .insert([dataToSave]);

        if (error) throw error;

        toast({
          title: "Contrato criado",
          description: "Contrato criado com sucesso",
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
          <DialogTitle>{contratoId ? "Editar Contrato" : "Novo Contrato"}</DialogTitle>
          <DialogDescription>
            Preencha os dados do contrato
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2 col-span-2">
              <Label htmlFor="cliente_id">Cliente *</Label>
              <Select
                value={formData.cliente_id}
                onValueChange={(value) =>
                  setFormData({ ...formData, cliente_id: value })
                }
                disabled={!!clienteId}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Selecione um cliente" />
                </SelectTrigger>
                <SelectContent>
                  {clientes.map((cliente) => (
                    <SelectItem key={cliente.id} value={cliente.id}>
                      {cliente.razao_social}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="nome">Nome do Contrato *</Label>
              <Input
                id="nome"
                value={formData.nome}
                onChange={(e) =>
                  setFormData({ ...formData, nome: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="codigo">Código *</Label>
              <Input
                id="codigo"
                value={formData.codigo}
                onChange={(e) =>
                  setFormData({ ...formData, codigo: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="data_inicio">Data Início *</Label>
              <Input
                id="data_inicio"
                type="date"
                value={formData.data_inicio}
                onChange={(e) =>
                  setFormData({ ...formData, data_inicio: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="data_fim">Data Fim</Label>
              <Input
                id="data_fim"
                type="date"
                value={formData.data_fim}
                onChange={(e) =>
                  setFormData({ ...formData, data_fim: e.target.value })
                }
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="sla_alvo_pct">SLA Alvo (%)</Label>
              <Input
                id="sla_alvo_pct"
                type="number"
                step="0.01"
                value={formData.sla_alvo_pct}
                onChange={(e) =>
                  setFormData({ ...formData, sla_alvo_pct: e.target.value })
                }
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="nps_meta">NPS Meta</Label>
              <Input
                id="nps_meta"
                type="number"
                step="0.01"
                value={formData.nps_meta}
                onChange={(e) =>
                  setFormData({ ...formData, nps_meta: e.target.value })
                }
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="status">Status</Label>
              <Select
                value={formData.status}
                onValueChange={(value) =>
                  setFormData({ ...formData, status: value })
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ativo">Ativo</SelectItem>
                  <SelectItem value="inativo">Inativo</SelectItem>
                  <SelectItem value="suspenso">Suspenso</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit" disabled={loading}>
              {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {contratoId ? "Atualizar" : "Criar"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default ContratoForm;
