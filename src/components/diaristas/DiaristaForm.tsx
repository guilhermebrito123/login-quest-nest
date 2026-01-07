import { useState, useEffect } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
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
import { toast } from "sonner";

interface DiaristaFormProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
  diarista?: any;
}

export function DiaristaForm({ open, onClose, onSuccess, diarista }: DiaristaFormProps) {
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState<{
    nome_completo: string;
    cpf: string;
    endereco: string;
    cep: string;
    cidade: string;
    telefone: string;
    email: string;
    possui_antecedente: boolean;
    status: "ativo" | "inativo" | "desligado" | "restrito";
    motivo_restricao: string;
    agencia: string;
    banco: string;
    tipo_conta: "conta corrente" | "conta poupança" | "conta salário";
    numero_conta: string;
    pix: string;
  }>({
    nome_completo: "",
    cpf: "",
    endereco: "",
    cep: "",
    cidade: "",
    telefone: "",
    email: "",
    possui_antecedente: false,
    status: "ativo",
    motivo_restricao: "",
    agencia: "",
    banco: "",
    tipo_conta: "conta corrente",
    numero_conta: "",
    pix: "",
  });
  
  const [anexos, setAnexos] = useState({
    anexo_dados_bancarios: null as File | null,
    anexo_cpf: null as File | null,
    anexo_comprovante_endereco: null as File | null,
    anexo_possui_antecedente: null as File | null,
  });

  useEffect(() => {
    if (diarista) {
      setFormData({
        nome_completo: diarista.nome_completo || "",
        cpf: diarista.cpf || "",
        endereco: diarista.endereco || "",
        cep: diarista.cep || "",
        cidade: diarista.cidade || "",
        telefone: diarista.telefone || "",
        email: diarista.email || "",
        possui_antecedente: diarista.possui_antecedente || false,
        status: (diarista.status || "ativo") as "ativo" | "inativo" | "desligado" | "restrito",
        motivo_restricao: diarista.motivo_restricao || "",
        agencia: diarista.agencia || "",
        banco: diarista.banco || "",
        tipo_conta: (diarista.tipo_conta || "conta corrente") as "conta corrente" | "conta poupança" | "conta salário",
        numero_conta: diarista.numero_conta || "",
        pix: diarista.pix || "",
      });
    } else {
      setFormData({
        nome_completo: "",
        cpf: "",
        endereco: "",
        cep: "",
        cidade: "",
        telefone: "",
        email: "",
        possui_antecedente: false,
        status: "ativo",
        motivo_restricao: "",
        agencia: "",
        banco: "",
        tipo_conta: "conta corrente",
        numero_conta: "",
        pix: "",
      });
    }
  }, [diarista, open]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (formData.possui_antecedente) {
      toast.error("Não é permitido cadastrar diaristas com antecedentes criminais");
      return;
    }

    if (formData.status === "restrito" && !formData.motivo_restricao.trim()) {
      toast.error("O motivo da restrição é obrigatório quando o status é 'restrito'");
      return;
    }

    // Validar anexos obrigatórios para novos cadastros
    if (!diarista) {
      if (!anexos.anexo_dados_bancarios || !anexos.anexo_cpf || 
          !anexos.anexo_comprovante_endereco || !anexos.anexo_possui_antecedente) {
        toast.error("Todos os anexos são obrigatórios");
        return;
      }
    }

    setLoading(true);

    try {
      let diaristaId = diarista?.id;
      
      // Preparar dados para salvar
      const dataToSave = {
        ...formData,
        // Se for novo cadastro, adicionar valores temporários para anexos
        ...((!diarista) && {
          anexo_dados_bancarios: "pending",
          anexo_cpf: "pending",
          anexo_comprovante_endereco: "pending",
          anexo_possui_antecedente: "pending",
        }),
      };
      
      // Salvar dados básicos
      if (diarista) {
        const { error } = await supabase
          .from("diaristas")
          .update(formData)
          .eq("id", diarista.id);

        if (error) throw error;
      } else {
        const { data, error } = await supabase
          .from("diaristas")
          .insert([dataToSave])
          .select()
          .single();

        if (error) throw error;
        diaristaId = data.id;
      }

      // Upload de anexos se houver
      const anexoFields = ['anexo_dados_bancarios', 'anexo_cpf', 'anexo_comprovante_endereco', 'anexo_possui_antecedente'];
      
      for (const field of anexoFields) {
        const file = anexos[field as keyof typeof anexos];
        if (file) {
          const filePath = `${diaristaId}/${field}_${Date.now()}_${file.name}`;
          
          const { error: uploadError } = await supabase.storage
            .from('diaristas-anexos')
            .upload(filePath, file);

          if (uploadError) {
            console.error(`Erro ao fazer upload de ${field}:`, uploadError);
          } else {
            // Atualizar referência do arquivo na tabela
            await supabase
              .from("diaristas")
              .update({ [field]: filePath })
              .eq("id", diaristaId);
          }
        }
      }

      toast.success(diarista ? "Diarista atualizado com sucesso" : "Diarista cadastrado com sucesso");
      onSuccess();
    } catch (error: any) {
      toast.error("Erro ao salvar diarista: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>
            {diarista ? "Editar Diarista" : "Novo Diarista"}
          </DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2 col-span-2">
              <Label htmlFor="nome_completo">Nome Completo *</Label>
              <Input
                id="nome_completo"
                value={formData.nome_completo}
                onChange={(e) =>
                  setFormData({ ...formData, nome_completo: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="cpf">CPF *</Label>
              <Input
                id="cpf"
                value={formData.cpf}
                onChange={(e) =>
                  setFormData({ ...formData, cpf: e.target.value })
                }
                placeholder="000.000.000-00"
                required
              />
            </div>

            <div className="space-y-2 col-span-2">
              <Label htmlFor="endereco">Endereço *</Label>
              <Input
                id="endereco"
                value={formData.endereco}
                onChange={(e) =>
                  setFormData({ ...formData, endereco: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="cep">CEP *</Label>
              <Input
                id="cep"
                value={formData.cep}
                onChange={(e) =>
                  setFormData({ ...formData, cep: e.target.value })
                }
                placeholder="00000-000"
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="cidade">Cidade *</Label>
              <Input
                id="cidade"
                value={formData.cidade}
                onChange={(e) =>
                  setFormData({ ...formData, cidade: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="telefone">Telefone *</Label>
              <Input
                id="telefone"
                type="tel"
                value={formData.telefone}
                onChange={(e) =>
                  setFormData({ ...formData, telefone: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="email">Email *</Label>
              <Input
                id="email"
                type="email"
                value={formData.email}
                onChange={(e) =>
                  setFormData({ ...formData, email: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="possui_antecedente">Possui Antecedente Criminal? *</Label>
              <Select
                value={formData.possui_antecedente ? "true" : "false"}
                onValueChange={(value) =>
                  setFormData({ ...formData, possui_antecedente: value === "true" })
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="false">Não</SelectItem>
                  <SelectItem value="true">Sim</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="status">Status</Label>
              <Select
                value={formData.status}
                onValueChange={(value) =>
                  setFormData({ 
                    ...formData, 
                    status: value as "ativo" | "inativo" | "desligado" | "restrito",
                    motivo_restricao: value !== "restrito" ? "" : formData.motivo_restricao
                  })
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ativo">Ativo</SelectItem>
                  <SelectItem value="inativo">Inativo</SelectItem>
                  <SelectItem value="desligado">Desligado</SelectItem>
                  <SelectItem value="restrito">Restrito</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {formData.status === "restrito" && (
              <div className="space-y-2">
                <Label htmlFor="motivo_restricao">Motivo da Restrição *</Label>
                <Input
                  id="motivo_restricao"
                  value={formData.motivo_restricao}
                  onChange={(e) =>
                    setFormData({ ...formData, motivo_restricao: e.target.value })
                  }
                  placeholder="Informe o motivo da restrição"
                  required
                />
              </div>
            )}

            <div className="space-y-2 col-span-2">
              <h3 className="text-lg font-semibold">Dados Bancários</h3>
            </div>

            <div className="space-y-2">
              <Label htmlFor="banco">Banco *</Label>
              <Input
                id="banco"
                value={formData.banco}
                onChange={(e) =>
                  setFormData({ ...formData, banco: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="agencia">Agência *</Label>
              <Input
                id="agencia"
                value={formData.agencia}
                onChange={(e) =>
                  setFormData({ ...formData, agencia: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="tipo_conta">Tipo de Conta *</Label>
              <Select
                value={formData.tipo_conta}
                onValueChange={(value) =>
                  setFormData({ ...formData, tipo_conta: value as "conta corrente" | "conta poupança" | "conta salário" })
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="conta corrente">Conta Corrente</SelectItem>
                  <SelectItem value="conta poupança">Conta Poupança</SelectItem>
                  <SelectItem value="conta salário">Conta Salário</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="numero_conta">Número da Conta *</Label>
              <Input
                id="numero_conta"
                value={formData.numero_conta}
                onChange={(e) =>
                  setFormData({ ...formData, numero_conta: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="pix">Chave PIX *</Label>
              <Input
                id="pix"
                value={formData.pix}
                onChange={(e) =>
                  setFormData({ ...formData, pix: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2 col-span-2">
              <h3 className="text-lg font-semibold">Anexos</h3>
            </div>

            <div className="space-y-2">
              <Label htmlFor="anexo_dados_bancarios">Dados Bancários *</Label>
              <Input
                id="anexo_dados_bancarios"
                type="file"
                onChange={(e) =>
                  setAnexos({ ...anexos, anexo_dados_bancarios: e.target.files?.[0] || null })
                }
                accept=".pdf,.jpg,.jpeg,.png"
                required={!diarista}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="anexo_cpf">CPF *</Label>
              <Input
                id="anexo_cpf"
                type="file"
                onChange={(e) =>
                  setAnexos({ ...anexos, anexo_cpf: e.target.files?.[0] || null })
                }
                accept=".pdf,.jpg,.jpeg,.png"
                required={!diarista}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="anexo_comprovante_endereco">Comprovante de Endereço *</Label>
              <Input
                id="anexo_comprovante_endereco"
                type="file"
                onChange={(e) =>
                  setAnexos({ ...anexos, anexo_comprovante_endereco: e.target.files?.[0] || null })
                }
                accept=".pdf,.jpg,.jpeg,.png"
                required={!diarista}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="anexo_possui_antecedente">Certidão de Antecedentes *</Label>
              <Input
                id="anexo_possui_antecedente"
                type="file"
                onChange={(e) =>
                  setAnexos({ ...anexos, anexo_possui_antecedente: e.target.files?.[0] || null })
                }
                accept=".pdf,.jpg,.jpeg,.png"
                required={!diarista}
              />
            </div>
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit" disabled={loading}>
              {loading ? "Salvando..." : diarista ? "Atualizar" : "Cadastrar"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
