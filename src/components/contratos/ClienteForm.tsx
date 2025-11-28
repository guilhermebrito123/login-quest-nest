import { useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
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

interface ClienteFormProps {
  clienteId?: string;
  onClose: () => void;
  onSuccess: () => void;
}

const ClienteForm = ({ clienteId, onClose, onSuccess }: ClienteFormProps) => {
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    razao_social: "",
    nome_fantasia: "",
    cnpj: "",
    contato_nome: "",
    contato_email: "",
    contato_telefone: "",
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      if (clienteId) {
        const { error } = await supabase
          .from("clientes")
          .update(formData)
          .eq("id", clienteId);

        if (error) throw error;

        toast({
          title: "Cliente atualizado",
          description: "Cliente atualizado com sucesso",
        });
      } else {
        const { error } = await supabase
          .from("clientes")
          .insert([formData]);

        if (error) throw error;

        toast({
          title: "Cliente criado",
          description: "Cliente criado com sucesso",
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
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>{clienteId ? "Editar Cliente" : "Novo Cliente"}</DialogTitle>
          <DialogDescription>
            Preencha os dados do cliente
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="razao_social">Razão Social *</Label>
              <Input
                id="razao_social"
                value={formData.razao_social}
                onChange={(e) =>
                  setFormData({ ...formData, razao_social: e.target.value })
                }
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="nome_fantasia">Nome Fantasia</Label>
              <Input
                id="nome_fantasia"
                value={formData.nome_fantasia}
                onChange={(e) =>
                  setFormData({ ...formData, nome_fantasia: e.target.value })
                }
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="cnpj">CNPJ *</Label>
              <Input
                id="cnpj"
                value={formData.cnpj}
                onChange={(e) =>
                  setFormData({ ...formData, cnpj: e.target.value })
                }
                placeholder="00.000.000/0000-00"
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="contato_nome">Nome do Contato</Label>
              <Input
                id="contato_nome"
                value={formData.contato_nome}
                onChange={(e) =>
                  setFormData({ ...formData, contato_nome: e.target.value })
                }
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="contato_email">Email do Contato</Label>
              <Input
                id="contato_email"
                type="email"
                value={formData.contato_email}
                onChange={(e) =>
                  setFormData({ ...formData, contato_email: e.target.value })
                }
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="contato_telefone">Telefone do Contato</Label>
              <Input
                id="contato_telefone"
                value={formData.contato_telefone}
                onChange={(e) =>
                  setFormData({ ...formData, contato_telefone: e.target.value })
                }
                placeholder="(00) 00000-0000"
              />
            </div>
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit" disabled={loading}>
              {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {clienteId ? "Atualizar" : "Criar"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default ClienteForm;
