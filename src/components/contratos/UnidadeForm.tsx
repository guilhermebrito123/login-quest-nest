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
    codigo: "",
    endereco: "",
    cidade: "",
    uf: "",
    cep: "",
    criticidade: "media",
    status: "ativo",
  });

  useEffect(() => {
    loadContratos();
  }, []);

  const loadContratos = async () => {
    const { data } = await supabase
      .from("contratos")
      .select("id, nome")
      .eq("status", "ativo")
      .order("nome");
    setContratos(data || []);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      if (unidadeId) {
        const { error } = await supabase
          .from("unidades")
          .update(formData)
          .eq("id", unidadeId);

        if (error) throw error;

        toast({
          title: "Unidade atualizada",
          description: "Unidade atualizada com sucesso",
        });
      } else {
        const { error } = await supabase
          .from("unidades")
          .insert([formData]);

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

            <div className="space-y-2">
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
              <Label htmlFor="criticidade">Criticidade</Label>
              <Select
                value={formData.criticidade}
                onValueChange={(value) =>
                  setFormData({ ...formData, criticidade: value })
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="baixa">Baixa</SelectItem>
                  <SelectItem value="media">Média</SelectItem>
                  <SelectItem value="alta">Alta</SelectItem>
                  <SelectItem value="critica">Crítica</SelectItem>
                </SelectContent>
              </Select>
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
              {unidadeId ? "Atualizar" : "Criar"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default UnidadeForm;
