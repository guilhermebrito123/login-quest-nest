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

interface OrdemServicoFormProps {
  os?: any;
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export function OrdemServicoForm({ os, open, onClose, onSuccess }: OrdemServicoFormProps) {
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    numero: "",
    titulo: "",
    descricao: "",
    tipo: "corretiva",
    prioridade: "media",
    status: "aberta",
    unidade_id: "",
    ativo_id: "",
    responsavel_id: "",
    data_prevista: "",
    observacoes: "",
  });

  const { data: unidades } = useQuery({
    queryKey: ["unidades"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("unidades")
        .select("id, nome")
        .eq("status", "ativo")
        .order("nome");
      if (error) throw error;
      return data;
    },
  });

  const { data: usuarios } = useQuery({
    queryKey: ["usuarios"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("profiles")
        .select("id, full_name")
        .order("full_name");
      if (error) throw error;
      return data;
    },
  });

  const { data: ativos } = useQuery({
    queryKey: ["ativos"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("ativos")
        .select("id, tag_patrimonio, categoria, modelo")
        .eq("status", "operacional")
        .order("tag_patrimonio");
      if (error) throw error;
      return data;
    },
  });

  useEffect(() => {
    if (os) {
      setFormData({
        numero: os.numero || "",
        titulo: os.titulo || "",
        descricao: os.descricao || "",
        tipo: os.tipo || "corretiva",
        prioridade: os.prioridade || "media",
        status: os.status || "aberta",
        unidade_id: os.unidade_id || "",
        ativo_id: os.ativo_id || "",
        responsavel_id: os.responsavel_id || "",
        data_prevista: os.data_prevista || "",
        observacoes: os.observacoes || "",
      });
    } else {
      // Generate numero for new OS
      generateNumero();
    }
  }, [os]);

  const generateNumero = async () => {
    const { data } = await supabase
      .from("ordens_servico")
      .select("numero")
      .order("created_at", { ascending: false })
      .limit(1);

    let newNumero = "OS-0001";
    if (data && data.length > 0) {
      const lastNum = parseInt(data[0].numero.split("-")[1]);
      newNumero = `OS-${String(lastNum + 1).padStart(4, "0")}`;
    }
    setFormData((prev) => ({ ...prev, numero: newNumero }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error("Usuário não autenticado");

      const payload = {
        ...formData,
        solicitante_id: os?.solicitante_id || user.id,
        data_prevista: formData.data_prevista || null,
        responsavel_id: formData.responsavel_id || null,
        ativo_id: formData.ativo_id || null,
      };

      if (os) {
        const { error } = await supabase
          .from("ordens_servico")
          .update(payload)
          .eq("id", os.id);
        if (error) throw error;
        toast.success("OS atualizada com sucesso");
      } else {
        const { error } = await supabase
          .from("ordens_servico")
          .insert(payload);
        if (error) throw error;
        toast.success("OS criada com sucesso");
      }

      onSuccess();
    } catch (error: any) {
      toast.error("Erro ao salvar OS: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{os ? "Editar Ordem de Serviço" : "Nova Ordem de Serviço"}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="numero">Número *</Label>
              <Input
                id="numero"
                value={formData.numero}
                onChange={(e) => setFormData({ ...formData, numero: e.target.value })}
                required
                disabled
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="tipo">Tipo *</Label>
              <Select value={formData.tipo} onValueChange={(value) => setFormData({ ...formData, tipo: value })}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="preventiva">Preventiva</SelectItem>
                  <SelectItem value="corretiva">Corretiva</SelectItem>
                  <SelectItem value="emergencial">Emergencial</SelectItem>
                  <SelectItem value="melhoria">Melhoria</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="titulo">Título *</Label>
            <Input
              id="titulo"
              value={formData.titulo}
              onChange={(e) => setFormData({ ...formData, titulo: e.target.value })}
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="descricao">Descrição</Label>
            <Textarea
              id="descricao"
              value={formData.descricao}
              onChange={(e) => setFormData({ ...formData, descricao: e.target.value })}
              rows={3}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="prioridade">Prioridade *</Label>
              <Select value={formData.prioridade} onValueChange={(value) => setFormData({ ...formData, prioridade: value })}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="baixa">Baixa</SelectItem>
                  <SelectItem value="media">Média</SelectItem>
                  <SelectItem value="alta">Alta</SelectItem>
                  <SelectItem value="urgente">Urgente</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="status">Status *</Label>
              <Select value={formData.status} onValueChange={(value) => setFormData({ ...formData, status: value })}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="aberta">Aberta</SelectItem>
                  <SelectItem value="em_andamento">Em Andamento</SelectItem>
                  <SelectItem value="concluida">Concluída</SelectItem>
                  <SelectItem value="cancelada">Cancelada</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="unidade_id">Unidade</Label>
              <Select value={formData.unidade_id} onValueChange={(value) => setFormData({ ...formData, unidade_id: value })}>
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
              <Label htmlFor="ativo_id">Ativo</Label>
              <Select value={formData.ativo_id} onValueChange={(value) => setFormData({ ...formData, ativo_id: value })}>
                <SelectTrigger>
                  <SelectValue placeholder="Selecione..." />
                </SelectTrigger>
                <SelectContent>
                  {ativos?.map((ativo) => (
                    <SelectItem key={ativo.id} value={ativo.id}>
                      {ativo.tag_patrimonio} - {ativo.categoria} {ativo.modelo}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="responsavel_id">Responsável</Label>
            <Select value={formData.responsavel_id} onValueChange={(value) => setFormData({ ...formData, responsavel_id: value })}>
              <SelectTrigger>
                <SelectValue placeholder="Selecione..." />
              </SelectTrigger>
              <SelectContent>
                {usuarios?.map((usuario) => (
                  <SelectItem key={usuario.id} value={usuario.id}>
                    {usuario.full_name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor="data_prevista">Data Prevista</Label>
            <Input
              id="data_prevista"
              type="date"
              value={formData.data_prevista}
              onChange={(e) => setFormData({ ...formData, data_prevista: e.target.value })}
            />
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
              {loading ? "Salvando..." : os ? "Atualizar" : "Criar"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}