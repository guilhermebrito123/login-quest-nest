import { useState, useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { toast } from "sonner";

interface ColaboradorFormProps {
  colaborador?: any;
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export function ColaboradorForm({ colaborador, open, onClose, onSuccess }: ColaboradorFormProps) {
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    nome_completo: "",
    cpf: "",
    telefone: "",
    email: "",
    data_admissao: "",
    data_desligamento: "",
    cargo_id: "",
    unidade_id: "",
    escala_id: "",
    posto_servico_id: "",
    status: "ativo",
    observacoes: "",
  });

  const { data: cargos } = useQuery({
    queryKey: ["cargos"],
    queryFn: async () => {
      const { data, error } = await supabase.from("cargos").select("id, nome").order("nome");
      if (error) throw error;
      return data;
    },
  });

  const { data: unidades } = useQuery({
    queryKey: ["unidades"],
    queryFn: async () => {
      const { data, error } = await supabase.from("unidades").select("id, nome").eq("status", "ativo").order("nome");
      if (error) throw error;
      return data;
    },
  });

  const { data: escalas } = useQuery({
    queryKey: ["escalas"],
    queryFn: async () => {
      const { data, error } = await supabase.from("escalas").select("id, nome, tipo").order("nome");
      if (error) throw error;
      return data;
    },
  });

  const { data: postos } = useQuery({
    queryKey: ["postos", formData.unidade_id],
    queryFn: async () => {
      if (!formData.unidade_id) return [];
      const { data, error } = await supabase
        .from("postos_servico")
        .select("id, nome, codigo")
        .eq("unidade_id", formData.unidade_id)
        .eq("status", "ativo")
        .order("nome");
      if (error) throw error;
      return data;
    },
    enabled: !!formData.unidade_id,
  });

  useEffect(() => {
    if (colaborador) {
      setFormData({
        nome_completo: colaborador.nome_completo || "",
        cpf: colaborador.cpf || "",
        telefone: colaborador.telefone || "",
        email: colaborador.email || "",
        data_admissao: colaborador.data_admissao || "",
        data_desligamento: colaborador.data_desligamento || "",
        cargo_id: colaborador.cargo_id || "",
        unidade_id: colaborador.unidade_id || "",
        escala_id: colaborador.escala_id || "",
        posto_servico_id: colaborador.posto_servico_id || "",
        status: colaborador.status || "ativo",
        observacoes: colaborador.observacoes || "",
      });
    }
  }, [colaborador]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const payload = {
        ...formData,
        cargo_id: formData.cargo_id || null,
        unidade_id: formData.unidade_id || null,
        escala_id: formData.escala_id || null,
        posto_servico_id: formData.posto_servico_id || null,
        data_desligamento: formData.data_desligamento || null,
      };

      if (colaborador) {
        const { error } = await supabase
          .from("colaboradores")
          .update(payload)
          .eq("id", colaborador.id);
        if (error) throw error;
        toast.success("Colaborador atualizado com sucesso");
      } else {
        const { error } = await supabase.from("colaboradores").insert(payload);
        if (error) throw error;
        toast.success("Colaborador cadastrado com sucesso");
      }

      onSuccess();
    } catch (error: any) {
      toast.error("Erro ao salvar colaborador: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{colaborador ? "Editar Colaborador" : "Novo Colaborador"}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="nome_completo">Nome Completo *</Label>
            <Input
              id="nome_completo"
              value={formData.nome_completo}
              onChange={(e) => setFormData({ ...formData, nome_completo: e.target.value })}
              required
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="cpf">CPF *</Label>
              <Input
                id="cpf"
                value={formData.cpf}
                onChange={(e) => setFormData({ ...formData, cpf: e.target.value })}
                placeholder="000.000.000-00"
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="telefone">Telefone</Label>
              <Input
                id="telefone"
                value={formData.telefone}
                onChange={(e) => setFormData({ ...formData, telefone: e.target.value })}
                placeholder="(00) 00000-0000"
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="email">Email</Label>
            <Input
              id="email"
              type="email"
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="data_admissao">Data de Admissão</Label>
              <Input
                id="data_admissao"
                type="date"
                value={formData.data_admissao}
                onChange={(e) => setFormData({ ...formData, data_admissao: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="status">Status *</Label>
              <Select value={formData.status} onValueChange={(value) => setFormData({ ...formData, status: value })}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ativo">Ativo</SelectItem>
                  <SelectItem value="inativo">Inativo</SelectItem>
                  <SelectItem value="ferias">Férias</SelectItem>
                  <SelectItem value="afastado">Afastado</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          {formData.status === "inativo" && (
            <div className="space-y-2">
              <Label htmlFor="data_desligamento">Data de Desligamento</Label>
              <Input
                id="data_desligamento"
                type="date"
                value={formData.data_desligamento}
                onChange={(e) => setFormData({ ...formData, data_desligamento: e.target.value })}
              />
            </div>
          )}

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="cargo_id">Cargo</Label>
              <Select value={formData.cargo_id} onValueChange={(value) => setFormData({ ...formData, cargo_id: value })}>
                <SelectTrigger>
                  <SelectValue placeholder="Selecione..." />
                </SelectTrigger>
                <SelectContent>
                  {cargos?.map((cargo) => (
                    <SelectItem key={cargo.id} value={cargo.id}>
                      {cargo.nome}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="escala_id">Escala</Label>
              <Select value={formData.escala_id} onValueChange={(value) => setFormData({ ...formData, escala_id: value })}>
                <SelectTrigger>
                  <SelectValue placeholder="Selecione..." />
                </SelectTrigger>
                <SelectContent>
                  {escalas?.map((escala) => (
                    <SelectItem key={escala.id} value={escala.id}>
                      {escala.nome} ({escala.tipo})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="unidade_id">Unidade</Label>
              <Select 
                value={formData.unidade_id} 
                onValueChange={(value) => setFormData({ ...formData, unidade_id: value, posto_servico_id: "" })}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Selecione..." />
                </SelectTrigger>
                <SelectContent>
                  {unidades?.map((unidade) => (
                    <SelectItem key={unidade.id} value={unidade.id}>
                      {unidade.nome}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="posto_servico_id">Posto de Serviço</Label>
              <Select 
                value={formData.posto_servico_id} 
                onValueChange={(value) => setFormData({ ...formData, posto_servico_id: value })}
                disabled={!formData.unidade_id}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Selecione unidade primeiro..." />
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
          </div>

          <div className="space-y-2">
            <Label htmlFor="observacoes">Observações</Label>
            <Textarea
              id="observacoes"
              value={formData.observacoes}
              onChange={(e) => setFormData({ ...formData, observacoes: e.target.value })}
              rows={3}
            />
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit" disabled={loading}>
              {loading ? "Salvando..." : colaborador ? "Atualizar" : "Cadastrar"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}