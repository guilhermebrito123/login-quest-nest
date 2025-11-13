import { useState, useEffect } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { toast } from "sonner";

interface EscalaFormProps {
  escala?: any;
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export function EscalaForm({ escala, open, onClose, onSuccess }: EscalaFormProps) {
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    nome: "",
    tipo: "fixa",
    descricao: "",
    dias_trabalhados: "",
    dias_folga: "",
  });

  useEffect(() => {
    if (escala) {
      setFormData({
        nome: escala.nome || "",
        tipo: escala.tipo || "fixa",
        descricao: escala.descricao || "",
        dias_trabalhados: escala.dias_trabalhados?.toString() || "",
        dias_folga: escala.dias_folga?.toString() || "",
      });
    }
  }, [escala]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const payload = {
        nome: formData.nome,
        tipo: formData.tipo,
        descricao: formData.descricao || null,
        dias_trabalhados: formData.dias_trabalhados ? parseInt(formData.dias_trabalhados) : null,
        dias_folga: formData.dias_folga ? parseInt(formData.dias_folga) : null,
      };

      if (escala) {
        const { error } = await supabase
          .from("escalas")
          .update(payload)
          .eq("id", escala.id);
        if (error) throw error;
        toast.success("Escala atualizada com sucesso");
      } else {
        const { error } = await supabase
          .from("escalas")
          .insert(payload);
        if (error) throw error;
        toast.success("Escala cadastrada com sucesso");
      }

      onSuccess();
    } catch (error: any) {
      toast.error("Erro ao salvar escala: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>{escala ? "Editar Escala Modelo" : "Nova Escala Modelo"}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="nome">Nome *</Label>
            <Input
              id="nome"
              value={formData.nome}
              onChange={(e) => setFormData({ ...formData, nome: e.target.value })}
              placeholder="Ex: 12x36, 5x2"
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="tipo">Tipo *</Label>
            <Select value={formData.tipo} onValueChange={(value) => setFormData({ ...formData, tipo: value })}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="fixa">Fixa</SelectItem>
                <SelectItem value="alternada">Alternada</SelectItem>
                <SelectItem value="flexivel">Flexível</SelectItem>
                <SelectItem value="plantao">Plantão</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="dias_trabalhados">Dias Trabalhados</Label>
              <Input
                id="dias_trabalhados"
                type="number"
                min="1"
                value={formData.dias_trabalhados}
                onChange={(e) => setFormData({ ...formData, dias_trabalhados: e.target.value })}
                placeholder="Ex: 12"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="dias_folga">Dias de Folga</Label>
              <Input
                id="dias_folga"
                type="number"
                min="1"
                value={formData.dias_folga}
                onChange={(e) => setFormData({ ...formData, dias_folga: e.target.value })}
                placeholder="Ex: 36"
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="descricao">Descrição</Label>
            <Textarea
              id="descricao"
              value={formData.descricao}
              onChange={(e) => setFormData({ ...formData, descricao: e.target.value })}
              rows={3}
              placeholder="Descreva os detalhes da escala..."
            />
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit" disabled={loading}>
              {loading ? "Salvando..." : escala ? "Atualizar" : "Cadastrar"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
