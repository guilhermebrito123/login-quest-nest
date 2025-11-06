import { useState, useEffect } from "react";
import { useForm } from "react-hook-form";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";

interface AtivoFormProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  ativo?: any;
  onSuccess: () => void;
}

export function AtivoForm({ open, onOpenChange, ativo, onSuccess }: AtivoFormProps) {
  const [loading, setLoading] = useState(false);
  const [unidades, setUnidades] = useState<any[]>([]);
  const { register, handleSubmit, setValue, watch, reset } = useForm({
    defaultValues: {
      unidade_id: ativo?.unidade_id || "",
      categoria: ativo?.categoria || "",
      tag_patrimonio: ativo?.tag_patrimonio || "",
      fabricante: ativo?.fabricante || "",
      modelo: ativo?.modelo || "",
      numero_serie: ativo?.numero_serie || "",
      status: ativo?.status || "operacional",
      critico: ativo?.critico || false,
      data_instalacao: ativo?.data_instalacao || "",
      frequencia_preventiva_dias: ativo?.frequencia_preventiva_dias || 90,
    },
  });

  useEffect(() => {
    fetchUnidades();
  }, []);

  useEffect(() => {
    if (ativo) {
      reset({
        unidade_id: ativo.unidade_id || "",
        categoria: ativo.categoria || "",
        tag_patrimonio: ativo.tag_patrimonio || "",
        fabricante: ativo.fabricante || "",
        modelo: ativo.modelo || "",
        numero_serie: ativo.numero_serie || "",
        status: ativo.status || "operacional",
        critico: ativo.critico || false,
        data_instalacao: ativo.data_instalacao || "",
        frequencia_preventiva_dias: ativo.frequencia_preventiva_dias || 90,
      });
    }
  }, [ativo, reset]);

  const fetchUnidades = async () => {
    const { data } = await supabase.from("unidades").select("*").order("nome");
    setUnidades(data || []);
  };

  const onSubmit = async (data: any) => {
    setLoading(true);
    try {
      const payload = {
        ...data,
        critico: data.critico === "true" || data.critico === true,
      };

      if (ativo) {
        const { error } = await supabase
          .from("ativos")
          .update(payload)
          .eq("id", ativo.id);
        if (error) throw error;
        toast.success("Ativo atualizado com sucesso!");
      } else {
        const { error } = await supabase.from("ativos").insert([payload]);
        if (error) throw error;
        toast.success("Ativo cadastrado com sucesso!");
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
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>
            {ativo ? "Editar Ativo" : "Cadastrar Novo Ativo"}
          </DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
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
              <Label htmlFor="categoria">Categoria *</Label>
              <Input {...register("categoria", { required: true })} />
            </div>

            <div className="space-y-2">
              <Label htmlFor="tag_patrimonio">Tag Patrimônio *</Label>
              <Input {...register("tag_patrimonio", { required: true })} />
            </div>

            <div className="space-y-2">
              <Label htmlFor="fabricante">Fabricante</Label>
              <Input {...register("fabricante")} />
            </div>

            <div className="space-y-2">
              <Label htmlFor="modelo">Modelo</Label>
              <Input {...register("modelo")} />
            </div>

            <div className="space-y-2">
              <Label htmlFor="numero_serie">Número de Série</Label>
              <Input {...register("numero_serie")} />
            </div>

            <div className="space-y-2">
              <Label htmlFor="status">Status *</Label>
              <Select
                value={watch("status")}
                onValueChange={(value) => setValue("status", value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Operacional" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="operacional">Operacional</SelectItem>
                  <SelectItem value="manutencao">Manutenção</SelectItem>
                  <SelectItem value="inativo">Inativo</SelectItem>
                  <SelectItem value="descartado">Descartado</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="critico">Crítico *</Label>
              <Select
                value={watch("critico")?.toString()}
                onValueChange={(value) => setValue("critico", value === "true")}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Não" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="false">Não</SelectItem>
                  <SelectItem value="true">Sim</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="data_instalacao">Data Instalação</Label>
              <Input type="date" {...register("data_instalacao")} />
            </div>

            <div className="space-y-2">
              <Label htmlFor="frequencia_preventiva_dias">
                Frequência Preventiva (dias)
              </Label>
              <Input
                type="number"
                {...register("frequencia_preventiva_dias")}
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
