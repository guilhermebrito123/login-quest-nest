import { useState, useEffect } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Dialog,
  DialogContent,
  DialogDescription,
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
import { toast } from "@/hooks/use-toast";
import { Loader2 } from "lucide-react";

interface PostoFormProps {
  postoId?: string;
  unidadeId?: string | null;
  onClose: () => void;
  onSuccess: () => void;
}

const PostoForm = ({ postoId, unidadeId, onClose, onSuccess }: PostoFormProps) => {
  const [loading, setLoading] = useState(false);
  const [unidades, setUnidades] = useState<any[]>([]);
  const [formData, setFormData] = useState({
    unidade_id: unidadeId || "",
    nome: "",
    funcao: "",
    escala: "",
    dias_semana: [] as number[],
    primeiro_dia_atividade: "",
    ultimo_dia_atividade: "",
    jornada: "",
    horario_inicio: "",
    horario_fim: "",
    intervalo_refeicao: "",
    beneficios: [] as string[],
    status: "vago",
    observacoes: "",
  });

  useEffect(() => {
    loadUnidades();
    if (postoId) {
      loadPosto();
    }
  }, [postoId]);

  const loadPosto = async () => {
    if (!postoId) return;
    
    const { data: posto, error } = await supabase
      .from("postos_servico")
      .select("*")
      .eq("id", postoId)
      .single();

    if (error) {
      toast({
        title: "Erro ao carregar posto",
        description: error.message,
        variant: "destructive",
      });
      return;
    }

    if (posto) {
      setFormData({
        unidade_id: posto.unidade_id || "",
        nome: posto.nome || "",
        funcao: posto.funcao || "",
        escala: posto.escala || "",
        dias_semana: posto.dias_semana || [],
        primeiro_dia_atividade: posto.primeiro_dia_atividade || "",
        ultimo_dia_atividade: posto.ultimo_dia_atividade || "",
        jornada: posto.jornada?.toString() || "",
        horario_inicio: posto.horario_inicio || "",
        horario_fim: posto.horario_fim || "",
        intervalo_refeicao: posto.intervalo_refeicao?.toString() || "",
        beneficios: posto.beneficios || [],
        status: posto.status || "vago",
        observacoes: posto.observacoes || "",
      });
    }
  };

  const loadUnidades = async () => {
    const { data } = await supabase
      .from("unidades")
      .select("id, nome")
      .order("nome");
    setUnidades(data || []);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const dataToSave = {
        ...formData,
        dias_semana: formData.dias_semana.length > 0 ? formData.dias_semana : null,
        primeiro_dia_atividade: formData.primeiro_dia_atividade || null,
        ultimo_dia_atividade: formData.ultimo_dia_atividade || null,
        jornada: formData.jornada ? parseInt(formData.jornada) : null,
        intervalo_refeicao: formData.intervalo_refeicao ? parseInt(formData.intervalo_refeicao) : null,
        beneficios: formData.beneficios.length > 0 ? formData.beneficios : null,
        observacoes: formData.observacoes || null,
        status: formData.status as "vago" | "ocupado" | "vago_temporariamente" | "ocupado_temporariamente" | "inativo",
      };

      if (postoId) {
        const { error } = await supabase
          .from("postos_servico")
          .update(dataToSave)
          .eq("id", postoId);

        if (error) throw error;

        toast({
          title: "Posto atualizado",
          description: "Posto de serviço atualizado com sucesso",
        });
      } else {
        const { error } = await supabase
          .from("postos_servico")
          .insert([dataToSave]);

        if (error) throw error;

        toast({
          title: "Posto criado",
          description: "Posto de serviço criado com sucesso",
        });
      }

      onSuccess();
    } catch (error: any) {
      toast({
        title: "Erro",
        description: error.message,
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{postoId ? "Editar Posto" : "Novo Posto de Serviço"}</DialogTitle>
          <DialogDescription>
            Preencha os dados do posto de serviço
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2 col-span-2">
              <Label htmlFor="unidade_id">Unidade *</Label>
              <Select
                value={formData.unidade_id}
                onValueChange={(value) =>
                  setFormData({ ...formData, unidade_id: value })
                }
                disabled={!!unidadeId}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Selecione uma unidade" />
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
              <Label htmlFor="nome">Nome do Posto *</Label>
              <Input
                id="nome"
                value={formData.nome}
                onChange={(e) =>
                  setFormData({ ...formData, nome: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="funcao">Função *</Label>
              <Input
                id="funcao"
                value={formData.funcao}
                onChange={(e) =>
                  setFormData({ ...formData, funcao: e.target.value })
                }
                placeholder="Ex: Técnico de Limpeza"
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="escala">Escala</Label>
              <Select
                value={formData.escala}
                onValueChange={(value) =>
                  setFormData({ ...formData, escala: value })
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="Selecione a escala" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="5x1">5x1</SelectItem>
                  <SelectItem value="5x2">5x2</SelectItem>
                  <SelectItem value="4x2">4x2</SelectItem>
                  <SelectItem value="6x1">6x1</SelectItem>
                  <SelectItem value="12x36">12x36</SelectItem>
                  <SelectItem value="18x36">18x36</SelectItem>
                  <SelectItem value="24x48">24x48</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="jornada">Jornada (horas)</Label>
              <Input
                id="jornada"
                type="number"
                value={formData.jornada}
                onChange={(e) =>
                  setFormData({ ...formData, jornada: e.target.value })
                }
                placeholder="Ex: 44"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="horario_inicio">Horário Início</Label>
              <Input
                id="horario_inicio"
                type="time"
                value={formData.horario_inicio}
                onChange={(e) =>
                  setFormData({ ...formData, horario_inicio: e.target.value })
                }
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="horario_fim">Horário Fim</Label>
              <Input
                id="horario_fim"
                type="time"
                value={formData.horario_fim}
                onChange={(e) =>
                  setFormData({ ...formData, horario_fim: e.target.value })
                }
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="intervalo_refeicao">Intervalo Refeição (min)</Label>
              <Input
                id="intervalo_refeicao"
                type="number"
                value={formData.intervalo_refeicao}
                onChange={(e) =>
                  setFormData({ ...formData, intervalo_refeicao: e.target.value })
                }
                placeholder="60"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="primeiro_dia_atividade">Primeiro Dia de Atividade</Label>
              <Input
                id="primeiro_dia_atividade"
                type="date"
                value={formData.primeiro_dia_atividade}
                onChange={(e) =>
                  setFormData({ ...formData, primeiro_dia_atividade: e.target.value })
                }
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="ultimo_dia_atividade">Último Dia de Atividade (Opcional)</Label>
              <Input
                id="ultimo_dia_atividade"
                type="date"
                value={formData.ultimo_dia_atividade}
                onChange={(e) =>
                  setFormData({ ...formData, ultimo_dia_atividade: e.target.value })
                }
              />
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
                  <SelectItem value="vago">Vago</SelectItem>
                  <SelectItem value="ocupado">Ocupado</SelectItem>
                  <SelectItem value="vago_temporariamente">Vago Temporariamente</SelectItem>
                  <SelectItem value="ocupado_temporariamente">Ocupado Temporariamente</SelectItem>
                  <SelectItem value="inativo">Inativo</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2 col-span-2">
              <Label htmlFor="observacoes">Observações</Label>
              <Textarea
                id="observacoes"
                value={formData.observacoes}
                onChange={(e) =>
                  setFormData({ ...formData, observacoes: e.target.value })
                }
                rows={3}
              />
            </div>
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit" disabled={loading}>
              {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {postoId ? "Atualizar" : "Criar"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default PostoForm;
