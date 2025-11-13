import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Calendar } from "lucide-react";
import { toast } from "sonner";

interface AtribuirEscalaDialogProps {
  colaborador: any;
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export function AtribuirEscalaDialog({ colaborador, open, onClose, onSuccess }: AtribuirEscalaDialogProps) {
  const [loading, setLoading] = useState(false);
  const [escalaId, setEscalaId] = useState(colaborador?.escala_id || "");

  const { data: escalas, isLoading: isLoadingEscalas } = useQuery({
    queryKey: ["escalas"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("escalas")
        .select("id, nome, tipo, descricao")
        .order("nome");
      if (error) throw error;
      return data;
    },
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!escalaId) {
      toast.error("Selecione uma escala");
      return;
    }

    setLoading(true);

    try {
      const { error } = await supabase
        .from("colaboradores")
        .update({ escala_id: escalaId })
        .eq("id", colaborador.id);

      if (error) throw error;
      
      toast.success("Escala atribuída com sucesso");
      onSuccess();
    } catch (error: any) {
      toast.error("Erro ao atribuir escala: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Calendar className="h-5 w-5" />
            Atribuir Escala
          </DialogTitle>
          <DialogDescription>
            Atribuir escala ao colaborador <strong>{colaborador?.nome_completo}</strong>
          </DialogDescription>
        </DialogHeader>
        
        {isLoadingEscalas ? (
          <div className="text-center py-8">
            <p className="text-muted-foreground">Carregando escalas...</p>
          </div>
        ) : !escalas || escalas.length === 0 ? (
          <div className="text-center py-8 space-y-4">
            <p className="text-muted-foreground">
              Nenhuma escala cadastrada. Crie uma escala primeiro no módulo de Escalas.
            </p>
            <Button variant="outline" onClick={onClose}>
              Fechar
            </Button>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="escala">Escala *</Label>
              <Select value={escalaId} onValueChange={setEscalaId}>
                <SelectTrigger>
                  <SelectValue placeholder="Selecione uma escala..." />
                </SelectTrigger>
                <SelectContent>
                  {escalas.map((escala) => (
                    <SelectItem key={escala.id} value={escala.id}>
                      {escala.nome} - {escala.tipo}
                      {escala.descricao && ` (${escala.descricao})`}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="flex justify-end gap-2">
              <Button type="button" variant="outline" onClick={onClose}>
                Cancelar
              </Button>
              <Button type="submit" disabled={loading}>
                {loading ? "Atribuindo..." : "Atribuir Escala"}
              </Button>
            </div>
          </form>
        )}
      </DialogContent>
    </Dialog>
  );
}
