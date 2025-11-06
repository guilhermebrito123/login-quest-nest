import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";

interface CargoFormProps {
  open: boolean;
  cargo?: any;
  onClose: () => void;
  onSuccess: () => void;
}

export function CargoForm({ open, cargo, onClose, onSuccess }: CargoFormProps) {
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    nome: "",
    descricao: "",
    is_lideranca: false,
  });

  useEffect(() => {
    if (cargo) {
      setFormData({
        nome: cargo.nome || "",
        descricao: cargo.descricao || "",
        is_lideranca: cargo.is_lideranca || false,
      });
    } else {
      setFormData({
        nome: "",
        descricao: "",
        is_lideranca: false,
      });
    }
  }, [cargo, open]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      if (cargo) {
        const { error } = await supabase
          .from("cargos")
          .update(formData)
          .eq("id", cargo.id);

        if (error) throw error;
        toast.success("Cargo atualizado com sucesso");
      } else {
        const { error } = await supabase
          .from("cargos")
          .insert([formData]);

        if (error) throw error;
        toast.success("Cargo criado com sucesso");
      }

      onSuccess();
    } catch (error: any) {
      toast.error(error.message || "Erro ao salvar cargo");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>{cargo ? "Editar Cargo" : "Novo Cargo"}</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="nome">Nome *</Label>
            <Input
              id="nome"
              value={formData.nome}
              onChange={(e) => setFormData({ ...formData, nome: e.target.value })}
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="descricao">Descrição</Label>
            <Textarea
              id="descricao"
              value={formData.descricao}
              onChange={(e) => setFormData({ ...formData, descricao: e.target.value })}
              rows={4}
            />
          </div>

          <div className="flex items-center justify-between space-x-2">
            <div className="space-y-0.5">
              <Label htmlFor="is_lideranca">Cargo de Liderança</Label>
              <p className="text-sm text-muted-foreground">
                Marque se este é um cargo de liderança (supervisor, gerente, coordenador, diretor, etc.)
              </p>
            </div>
            <Switch
              id="is_lideranca"
              checked={formData.is_lideranca}
              onCheckedChange={(checked) => setFormData({ ...formData, is_lideranca: checked })}
            />
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit" disabled={loading}>
              {loading ? "Salvando..." : cargo ? "Atualizar" : "Criar"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
