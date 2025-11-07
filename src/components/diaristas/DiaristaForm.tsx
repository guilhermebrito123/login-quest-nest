import { useState, useEffect } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
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
import { toast } from "sonner";

interface DiaristaFormProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
  diarista?: any;
}

export function DiaristaForm({ open, onClose, onSuccess, diarista }: DiaristaFormProps) {
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    nome_completo: "",
    rg: "",
    cnh: "",
    endereco: "",
    cidade: "",
    telefone: "",
    email: "",
    possui_antecedente: false,
    status: "ativo",
  });

  useEffect(() => {
    if (diarista) {
      setFormData({
        nome_completo: diarista.nome_completo || "",
        rg: diarista.rg || "",
        cnh: diarista.cnh || "",
        endereco: diarista.endereco || "",
        cidade: diarista.cidade || "",
        telefone: diarista.telefone || "",
        email: diarista.email || "",
        possui_antecedente: diarista.possui_antecedente || false,
        status: diarista.status || "ativo",
      });
    } else {
      setFormData({
        nome_completo: "",
        rg: "",
        cnh: "",
        endereco: "",
        cidade: "",
        telefone: "",
        email: "",
        possui_antecedente: false,
        status: "ativo",
      });
    }
  }, [diarista, open]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (formData.possui_antecedente) {
      toast.error("Não é permitido cadastrar diaristas com antecedentes criminais");
      return;
    }

    setLoading(true);

    try {
      if (diarista) {
        const { error } = await supabase
          .from("diaristas")
          .update(formData)
          .eq("id", diarista.id);

        if (error) throw error;
        toast.success("Diarista atualizado com sucesso");
      } else {
        const { error } = await supabase
          .from("diaristas")
          .insert([formData]);

        if (error) throw error;
        toast.success("Diarista cadastrado com sucesso");
      }

      onSuccess();
    } catch (error: any) {
      toast.error("Erro ao salvar diarista: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>
            {diarista ? "Editar Diarista" : "Novo Diarista"}
          </DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2 col-span-2">
              <Label htmlFor="nome_completo">Nome Completo *</Label>
              <Input
                id="nome_completo"
                value={formData.nome_completo}
                onChange={(e) =>
                  setFormData({ ...formData, nome_completo: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="rg">RG *</Label>
              <Input
                id="rg"
                value={formData.rg}
                onChange={(e) =>
                  setFormData({ ...formData, rg: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="cnh">CNH *</Label>
              <Input
                id="cnh"
                value={formData.cnh}
                onChange={(e) =>
                  setFormData({ ...formData, cnh: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2 col-span-2">
              <Label htmlFor="endereco">Endereço *</Label>
              <Input
                id="endereco"
                value={formData.endereco}
                onChange={(e) =>
                  setFormData({ ...formData, endereco: e.target.value })
                }
                required
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
              <Label htmlFor="telefone">Telefone *</Label>
              <Input
                id="telefone"
                type="tel"
                value={formData.telefone}
                onChange={(e) =>
                  setFormData({ ...formData, telefone: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="email">Email *</Label>
              <Input
                id="email"
                type="email"
                value={formData.email}
                onChange={(e) =>
                  setFormData({ ...formData, email: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="possui_antecedente">Possui Antecedente Criminal? *</Label>
              <Select
                value={formData.possui_antecedente ? "true" : "false"}
                onValueChange={(value) =>
                  setFormData({ ...formData, possui_antecedente: value === "true" })
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="false">Não</SelectItem>
                  <SelectItem value="true">Sim</SelectItem>
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
              {loading ? "Salvando..." : diarista ? "Atualizar" : "Cadastrar"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
