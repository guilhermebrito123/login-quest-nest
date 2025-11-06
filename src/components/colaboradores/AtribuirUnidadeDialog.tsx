import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { toast } from "sonner";

interface AtribuirUnidadeDialogProps {
  colaborador: any;
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export function AtribuirUnidadeDialog({ colaborador, open, onClose, onSuccess }: AtribuirUnidadeDialogProps) {
  const [loading, setLoading] = useState(false);
  const [unidadeId, setUnidadeId] = useState(colaborador?.unidade_id || "");
  const [postoServicoId, setPostoServicoId] = useState(colaborador?.posto_servico_id || "");

  const { data: unidades, isLoading: loadingUnidades } = useQuery({
    queryKey: ["unidades-ativas"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("unidades")
        .select("id, nome, codigo")
        .eq("status", "ativo")
        .order("nome");
      if (error) throw error;
      return data;
    },
  });

  const { data: postos } = useQuery({
    queryKey: ["postos-unidade", unidadeId],
    queryFn: async () => {
      if (!unidadeId) return [];
      const { data, error } = await supabase
        .from("postos_servico")
        .select("id, nome, codigo")
        .eq("unidade_id", unidadeId)
        .eq("status", "ativo")
        .order("nome");
      if (error) throw error;
      return data;
    },
    enabled: !!unidadeId,
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!unidadeId) {
      toast.error("Selecione uma unidade");
      return;
    }

    setLoading(true);
    try {
      const { error } = await supabase
        .from("colaboradores")
        .update({ 
          unidade_id: unidadeId,
          posto_servico_id: postoServicoId || null
        })
        .eq("id", colaborador.id);

      if (error) throw error;

      toast.success("Unidade atribuída com sucesso");
      onSuccess();
      onClose();
    } catch (error: any) {
      toast.error("Erro ao atribuir unidade: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Atribuir Unidade - {colaborador?.nome_completo}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="unidade">Unidade *</Label>
            {loadingUnidades ? (
              <p className="text-sm text-muted-foreground">Carregando unidades...</p>
            ) : !unidades || unidades.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                Nenhuma unidade ativa encontrada. Cadastre unidades primeiro.
              </p>
            ) : (
              <Select value={unidadeId} onValueChange={(value) => {
                setUnidadeId(value);
                setPostoServicoId("");
              }}>
                <SelectTrigger>
                  <SelectValue placeholder="Selecione uma unidade..." />
                </SelectTrigger>
                <SelectContent>
                  {unidades.map((unidade) => (
                    <SelectItem key={unidade.id} value={unidade.id}>
                      {unidade.codigo} - {unidade.nome}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="posto">Posto de Serviço (Opcional)</Label>
            <Select 
              value={postoServicoId} 
              onValueChange={setPostoServicoId}
              disabled={!unidadeId}
            >
              <SelectTrigger>
                <SelectValue placeholder={!unidadeId ? "Selecione uma unidade primeiro..." : "Selecione um posto..."} />
              </SelectTrigger>
              <SelectContent>
                {postos?.map((posto) => (
                  <SelectItem key={posto.id} value={posto.id}>
                    {posto.codigo} - {posto.nome}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit" disabled={loading || !unidadeId}>
              {loading ? "Atribuindo..." : "Atribuir"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
