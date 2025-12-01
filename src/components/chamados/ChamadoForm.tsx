import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useQuery } from "@tanstack/react-query";
import { Loader2 } from "lucide-react";

const chamadoSchema = z.object({
  titulo: z.string().min(3, "Título deve ter no mínimo 3 caracteres"),
  descricao: z.string().optional(),
  tipo: z.string().min(1, "Tipo é obrigatório"),
  categoria: z.enum(["manutencao", "rh", "suprimentos", "atendimento"]),
  subcategoria: z.string().optional(),
  prioridade: z.enum(["baixa", "media", "alta", "critica"]),
  status: z.enum(["aberto", "em_andamento", "pendente", "concluido"]),
  unidade_id: z.string().uuid("Unidade é obrigatória"),
  posto_servico_id: z.string().uuid().optional(),
  contrato_id: z.string().uuid().optional(),
  solicitante_id: z.string().uuid().optional(),
  sla_horas: z.coerce.number().min(1).default(24),
  canal: z.enum(["app", "webhook", "qr"]).default("app"),
});

type ChamadoFormValues = z.infer<typeof chamadoSchema>;

const subcategorias = {
  manutencao: ["Equipamento", "Veículo", "Infraestrutura"],
  rh: ["Benefícios", "Movimentação", "Dúvidas"],
  suprimentos: ["Material", "Uniforme", "EPI"],
  atendimento: ["Limpeza", "Organização", "Predial", "Outros"],
};

interface ChamadoFormProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  chamado?: any;
  onSuccess: () => void;
}

export function ChamadoForm({ open, onOpenChange, chamado, onSuccess }: ChamadoFormProps) {
  const { toast } = useToast();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const [userRole, setUserRole] = useState<string | null>(null);
  const [uploadedFiles, setUploadedFiles] = useState<File[]>([]);

  const form = useForm<ChamadoFormValues>({
    resolver: zodResolver(chamadoSchema),
    defaultValues: {
      titulo: "",
      descricao: "",
      tipo: "",
      categoria: "atendimento",
      subcategoria: "",
      prioridade: "media",
      status: "aberto",
      sla_horas: 24,
      canal: "app",
    },
  });

  useEffect(() => {
    const fetchUserData = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        setCurrentUserId(user.id);
        
        const { data: roleData } = await supabase
          .from("user_roles")
          .select("role")
          .eq("user_id", user.id)
          .single();
        
        if (roleData) {
          setUserRole(roleData.role);
        }
      }
    };
    fetchUserData();
  }, []);

  const { data: unidades } = useQuery({
    queryKey: ["unidades"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("unidades")
        .select("id, nome")
        .order("nome");
      if (error) throw error;
      return data;
    },
  });

  const { data: contratos } = useQuery({
    queryKey: ["contratos"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("contratos")
        .select("id, negocio, conq_perd")
        .order("negocio");
      if (error) throw error;
      return data;
    },
  });

  const selectedUnidadeId = form.watch("unidade_id");
  
  const { data: postos } = useQuery({
    queryKey: ["postos", selectedUnidadeId],
    queryFn: async () => {
      if (!selectedUnidadeId) return [];
      const { data, error } = await supabase
        .from("postos_servico")
        .select("id, nome, codigo")
        .eq("unidade_id", selectedUnidadeId)
        .in("status", ["ocupado", "ocupado_temporariamente"])
        .order("nome");
      if (error) throw error;
      return data;
    },
    enabled: !!selectedUnidadeId,
  });

  const { data: colaboradores } = useQuery({
    queryKey: ["colaboradores"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("colaboradores")
        .select("id, nome_completo, cpf")
        .eq("status_colaborador", "ativo")
        .order("nome_completo");
      if (error) throw error;
      return data;
    },
  });

  const selectedCategoria = form.watch("categoria");

  useEffect(() => {
    if (chamado) {
      form.reset({
        titulo: chamado.titulo || "",
        descricao: chamado.descricao || "",
        tipo: chamado.tipo || "",
        categoria: chamado.categoria || "atendimento",
        subcategoria: chamado.subcategoria || "",
        prioridade: chamado.prioridade || "media",
        status: chamado.status || "aberto",
        unidade_id: chamado.unidade_id || "",
        posto_servico_id: chamado.posto_servico_id || "",
        contrato_id: chamado.contrato_id || "",
        solicitante_id: chamado.solicitante_id || "",
        sla_horas: chamado.sla_horas || 24,
        canal: chamado.canal || "app",
      });
    }
  }, [chamado, form]);

  const onSubmit = async (data: ChamadoFormValues) => {
    setIsSubmitting(true);
    try {
      const chamadoData: any = {
        titulo: data.titulo,
        descricao: data.descricao || null,
        tipo: data.tipo,
        categoria: data.categoria,
        subcategoria: data.subcategoria || null,
        prioridade: data.prioridade,
        status: data.status,
        unidade_id: data.unidade_id,
        posto_servico_id: data.posto_servico_id || null,
        contrato_id: data.contrato_id || null,
        sla_horas: data.sla_horas,
        canal: data.canal,
        numero: chamado?.numero || `CH-${Date.now()}`,
      };

      let chamadoId = chamado?.id;

      if (chamado) {
        const { error } = await supabase
          .from("chamados")
          .update(chamadoData)
          .eq("id", chamado.id);

        if (error) throw error;
        toast({ title: "Chamado atualizado com sucesso!" });
      } else {
        const { data: newChamado, error } = await supabase
          .from("chamados")
          .insert([chamadoData])
          .select()
          .single();

        if (error) throw error;
        chamadoId = newChamado.id;
        toast({ title: "Chamado criado com sucesso!" });
      }

      // Upload de arquivos se houver
      if (uploadedFiles.length > 0 && chamadoId) {
        const { data: { user } } = await supabase.auth.getUser();
        if (user) {
          for (const file of uploadedFiles) {
            const fileExt = file.name.split('.').pop();
            const fileName = `${chamadoId}/${Date.now()}.${fileExt}`;
            
            const { error: uploadError } = await supabase.storage
              .from('chamados-anexos')
              .upload(fileName, file);

            if (uploadError) {
              console.error('Erro ao fazer upload:', uploadError);
              continue;
            }

            // Registrar anexo na tabela
            await supabase.from('chamados_anexos').insert({
              chamado_id: chamadoId,
              usuario_id: user.id,
              nome_arquivo: file.name,
              caminho_storage: fileName,
              tipo_arquivo: file.type,
              tamanho_bytes: file.size,
            });
          }
        }
      }

      onSuccess();
      form.reset();
      setUploadedFiles([]);
    } catch (error: any) {
      toast({
        title: "Erro ao salvar chamado",
        description: error.message,
        variant: "destructive",
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const isAdmin = userRole === "admin";

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{chamado ? "Editar Chamado" : "Novo Chamado"}</DialogTitle>
        </DialogHeader>

        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid gap-4 md:grid-cols-2">
              <FormField
                control={form.control}
                name="titulo"
                render={({ field }) => (
                  <FormItem className="md:col-span-2">
                    <FormLabel>Título *</FormLabel>
                    <FormControl>
                      <Input {...field} placeholder="Digite o título do chamado" />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="tipo"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Tipo *</FormLabel>
                    <FormControl>
                      <Input {...field} placeholder="Ex: Corretiva, Preventiva" />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="categoria"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Categoria *</FormLabel>
                    <Select onValueChange={field.onChange} value={field.value}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        <SelectItem value="manutencao">Manutenção</SelectItem>
                        <SelectItem value="rh">RH</SelectItem>
                        <SelectItem value="suprimentos">Suprimentos</SelectItem>
                        <SelectItem value="atendimento">Atendimento</SelectItem>
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="subcategoria"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Subcategoria</FormLabel>
                    <Select onValueChange={field.onChange} value={field.value}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder="Selecione..." />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {subcategorias[selectedCategoria]?.map((sub) => (
                          <SelectItem key={sub} value={sub.toLowerCase()}>
                            {sub}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="prioridade"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Prioridade *</FormLabel>
                    <Select onValueChange={field.onChange} value={field.value}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        <SelectItem value="baixa">Baixa</SelectItem>
                        <SelectItem value="media">Média</SelectItem>
                        <SelectItem value="alta">Alta</SelectItem>
                        <SelectItem value="critica">Crítica</SelectItem>
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="status"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Status *</FormLabel>
                    <Select onValueChange={field.onChange} value={field.value}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        <SelectItem value="aberto">Aberto</SelectItem>
                        <SelectItem value="em_andamento">Em Andamento</SelectItem>
                        <SelectItem value="pendente">Pendente</SelectItem>
                        <SelectItem value="concluido">Concluído</SelectItem>
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="sla_horas"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>SLA (horas) *</FormLabel>
                    <FormControl>
                      <Input type="number" {...field} min={1} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="contrato_id"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Contrato</FormLabel>
                    <Select onValueChange={field.onChange} value={field.value}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder="Selecione o contrato" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {contratos?.map((contrato) => (
                          <SelectItem key={contrato.id} value={contrato.id}>
                            {contrato.negocio}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="unidade_id"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Unidade *</FormLabel>
                    <Select onValueChange={field.onChange} value={field.value}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder="Selecione a unidade" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {unidades?.map((unidade) => (
                          <SelectItem key={unidade.id} value={unidade.id}>
                            {unidade.nome}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="posto_servico_id"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Posto de Serviço</FormLabel>
                    <Select onValueChange={field.onChange} value={field.value} disabled={!selectedUnidadeId}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder={!selectedUnidadeId ? "Selecione a unidade primeiro" : "Selecione o posto"} />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {postos?.map((posto) => (
                          <SelectItem key={posto.id} value={posto.id}>
                            {posto.codigo} - {posto.nome}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />

              {isAdmin && (
                <FormField
                  control={form.control}
                  name="solicitante_id"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Solicitante</FormLabel>
                      <Select onValueChange={field.onChange} value={field.value}>
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Selecione o solicitante" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          {colaboradores?.map((colab) => (
                            <SelectItem key={colab.id} value={colab.id}>
                              {colab.nome_completo}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              )}

              <FormField
                control={form.control}
                name="descricao"
                render={({ field }) => (
                  <FormItem className="md:col-span-2">
                    <FormLabel>Descrição</FormLabel>
                    <FormControl>
                      <Textarea {...field} placeholder="Descreva os detalhes do chamado" rows={4} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormItem className="md:col-span-2">
                <FormLabel>Anexos</FormLabel>
                <FormControl>
                  <Input
                    type="file"
                    multiple
                    accept="image/*,application/pdf,.doc,.docx"
                    onChange={(e) => {
                      const files = Array.from(e.target.files || []);
                      setUploadedFiles(files);
                    }}
                  />
                </FormControl>
                {uploadedFiles.length > 0 && (
                  <p className="text-sm text-muted-foreground">
                    {uploadedFiles.length} arquivo(s) selecionado(s)
                  </p>
                )}
              </FormItem>
            </div>

            <div className="flex justify-end gap-2">
              <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
                Cancelar
              </Button>
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                {chamado ? "Atualizar" : "Criar"} Chamado
              </Button>
            </div>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}
