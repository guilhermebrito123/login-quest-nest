import { useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { toast } from "sonner";

interface PresencaDialogProps {
  colaborador: any;
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export function PresencaDialog({ colaborador, open, onClose, onSuccess }: PresencaDialogProps) {
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    data: new Date().toISOString().split("T")[0],
    tipo: "presente",
    horario_entrada: "",
    horario_saida: "",
    observacao: "",
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error("Usuário não autenticado");

      const payload = {
        colaborador_id: colaborador.id,
        data: formData.data,
        tipo: formData.tipo,
        horario_entrada: formData.horario_entrada ? new Date(`${formData.data}T${formData.horario_entrada}`).toISOString() : null,
        horario_saida: formData.horario_saida ? new Date(`${formData.data}T${formData.horario_saida}`).toISOString() : null,
        observacao: formData.observacao || null,
        registrado_por: user.id,
      };

      const { error } = await supabase.from("presencas").insert(payload);
      if (error) throw error;

      toast.success("Presença registrada com sucesso");
      onSuccess();
    } catch (error: any) {
      if (error.message.includes("duplicate key")) {
        toast.error("Já existe um registro de presença para este colaborador nesta data");
      } else {
        toast.error("Erro ao registrar presença: " + error.message);
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Registrar Presença</DialogTitle>
          <p className="text-sm text-muted-foreground">{colaborador.nome_completo}</p>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="data">Data *</Label>
            <Input
              id="data"
              type="date"
              value={formData.data}
              onChange={(e) => setFormData({ ...formData, data: e.target.value })}
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
                <SelectItem value="presente">Presente</SelectItem>
                <SelectItem value="falta">Falta</SelectItem>
                <SelectItem value="falta_justificada">Falta Justificada</SelectItem>
                <SelectItem value="ferias">Férias</SelectItem>
                <SelectItem value="atestado">Atestado</SelectItem>
                <SelectItem value="folga">Folga</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {formData.tipo === "presente" && (
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="horario_entrada">Horário Entrada</Label>
                <Input
                  id="horario_entrada"
                  type="time"
                  value={formData.horario_entrada}
                  onChange={(e) => setFormData({ ...formData, horario_entrada: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="horario_saida">Horário Saída</Label>
                <Input
                  id="horario_saida"
                  type="time"
                  value={formData.horario_saida}
                  onChange={(e) => setFormData({ ...formData, horario_saida: e.target.value })}
                />
              </div>
            </div>
          )}

          <div className="space-y-2">
            <Label htmlFor="observacao">Observação</Label>
            <Textarea
              id="observacao"
              value={formData.observacao}
              onChange={(e) => setFormData({ ...formData, observacao: e.target.value })}
              rows={3}
              placeholder="Informações adicionais..."
            />
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit" disabled={loading}>
              {loading ? "Registrando..." : "Registrar"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}