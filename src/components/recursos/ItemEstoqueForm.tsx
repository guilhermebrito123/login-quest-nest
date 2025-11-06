import { useState, useEffect } from "react";
import { useForm } from "react-hook-form";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";

interface ItemEstoqueFormProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  item?: any;
  onSuccess: () => void;
}

export function ItemEstoqueForm({ open, onOpenChange, item, onSuccess }: ItemEstoqueFormProps) {
  const [loading, setLoading] = useState(false);
  const [unidades, setUnidades] = useState<any[]>([]);
  const { register, handleSubmit, setValue, watch, reset } = useForm({
    defaultValues: {
      unidade_id: item?.unidade_id || "",
      sku: item?.sku || "",
      descricao: item?.descricao || "",
      unidade_medida: item?.unidade_medida || "",
      quantidade_minima: item?.quantidade_minima || 0,
      quantidade_atual: item?.quantidade_atual || 0,
    },
  });

  useEffect(() => {
    fetchUnidades();
  }, []);

  useEffect(() => {
    if (item) {
      reset({
        unidade_id: item.unidade_id || "",
        sku: item.sku || "",
        descricao: item.descricao || "",
        unidade_medida: item.unidade_medida || "",
        quantidade_minima: item.quantidade_minima || 0,
        quantidade_atual: item.quantidade_atual || 0,
      });
    }
  }, [item, reset]);

  const fetchUnidades = async () => {
    const { data } = await supabase.from("unidades").select("*").order("nome");
    setUnidades(data || []);
  };

  const onSubmit = async (data: any) => {
    setLoading(true);
    try {
      if (item) {
        const { error } = await supabase
          .from("itens_estoque")
          .update(data)
          .eq("id", item.id);
        if (error) throw error;
        toast.success("Item atualizado com sucesso!");
      } else {
        const { error } = await supabase.from("itens_estoque").insert([data]);
        if (error) throw error;
        toast.success("Item cadastrado com sucesso!");
      }
      onSuccess();
      onOpenChange(false);
      reset();
    } catch (error: any) {
      toast.error(error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>
            {item ? "Editar Item" : "Cadastrar Novo Item"}
          </DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="unidade_id">Unidade *</Label>
            <Select
              value={watch("unidade_id")}
              onValueChange={(value) => setValue("unidade_id", value)}
            >
              <SelectTrigger>
                <SelectValue placeholder="Selecione" />
              </SelectTrigger>
              <SelectContent>
                {unidades.map((unidade) => (
                  <SelectItem key={unidade.id} value={unidade.id}>
                    {unidade.nome}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor="sku">SKU *</Label>
            <Input {...register("sku", { required: true })} />
          </div>

          <div className="space-y-2">
            <Label htmlFor="descricao">Descrição *</Label>
            <Input {...register("descricao", { required: true })} />
          </div>

          <div className="space-y-2">
            <Label htmlFor="unidade_medida">Unidade de Medida *</Label>
            <Input
              placeholder="Ex: UN, KG, L"
              {...register("unidade_medida", { required: true })}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="quantidade_minima">Quantidade Mínima *</Label>
              <Input
                type="number"
                {...register("quantidade_minima", { required: true })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="quantidade_atual">Quantidade Atual *</Label>
              <Input
                type="number"
                {...register("quantidade_atual", { required: true })}
              />
            </div>
          </div>

          <div className="flex justify-end gap-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
            >
              Cancelar
            </Button>
            <Button type="submit" disabled={loading}>
              {loading ? "Salvando..." : "Cadastrar"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
