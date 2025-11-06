import { useState, useRef } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Upload, Download, Trash2, File, FileText, Image as ImageIcon } from "lucide-react";
import { toast } from "sonner";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

interface OSAnexosProps {
  osId: string;
}

export function OSAnexos({ osId }: OSAnexosProps) {
  const [uploading, setUploading] = useState(false);
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const { data: anexos, refetch } = useQuery({
    queryKey: ["os-anexos", osId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("os_anexos")
        .select("*")
        .eq("os_id", osId)
        .order("created_at", { ascending: false });
      if (error) throw error;
      
      // Fetch uploader details separately
      const anexosWithUploader = await Promise.all(
        (data || []).map(async (anexo) => {
          const { data: profile } = await supabase
            .from("profiles")
            .select("full_name")
            .eq("id", anexo.uploaded_by)
            .single();
          return { ...anexo, uploader: profile };
        })
      );
      
      return anexosWithUploader;
    },
  });

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploading(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error("Usuário não autenticado");

      const fileExt = file.name.split(".").pop();
      const fileName = `${osId}/${Date.now()}.${fileExt}`;

      const { error: uploadError } = await supabase.storage
        .from("os-anexos")
        .upload(fileName, file);

      if (uploadError) throw uploadError;

      const { error: dbError } = await supabase
        .from("os_anexos")
        .insert({
          os_id: osId,
          nome_arquivo: file.name,
          caminho_storage: fileName,
          tamanho_bytes: file.size,
          tipo_arquivo: file.type,
          uploaded_by: user.id,
        });

      if (dbError) throw dbError;

      toast.success("Arquivo enviado com sucesso");
      refetch();
    } catch (error: any) {
      toast.error("Erro ao enviar arquivo: " + error.message);
    } finally {
      setUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  };

  const handleDownload = async (anexo: any) => {
    try {
      const { data, error } = await supabase.storage
        .from("os-anexos")
        .download(anexo.caminho_storage);

      if (error) throw error;

      const url = URL.createObjectURL(data);
      const a = document.createElement("a");
      a.href = url;
      a.download = anexo.nome_arquivo;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch (error: any) {
      toast.error("Erro ao baixar arquivo: " + error.message);
    }
  };

  const handleDelete = async () => {
    if (!deleteId) return;

    try {
      const anexo = anexos?.find((a) => a.id === deleteId);
      if (!anexo) return;

      const { error: storageError } = await supabase.storage
        .from("os-anexos")
        .remove([anexo.caminho_storage]);

      if (storageError) throw storageError;

      const { error: dbError } = await supabase
        .from("os_anexos")
        .delete()
        .eq("id", deleteId);

      if (dbError) throw dbError;

      toast.success("Arquivo excluído com sucesso");
      refetch();
    } catch (error: any) {
      toast.error("Erro ao excluir arquivo: " + error.message);
    } finally {
      setDeleteId(null);
    }
  };

  const getFileIcon = (tipo: string) => {
    if (tipo.startsWith("image/")) return <ImageIcon className="h-5 w-5" />;
    if (tipo.includes("pdf")) return <FileText className="h-5 w-5" />;
    return <File className="h-5 w-5" />;
  };

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return bytes + " B";
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB";
    return (bytes / (1024 * 1024)).toFixed(1) + " MB";
  };

  return (
    <div className="space-y-4">
      <div>
        <input
          ref={fileInputRef}
          type="file"
          onChange={handleFileSelect}
          className="hidden"
        />
        <Button
          onClick={() => fileInputRef.current?.click()}
          disabled={uploading}
        >
          <Upload className="mr-2 h-4 w-4" />
          {uploading ? "Enviando..." : "Adicionar Anexo"}
        </Button>
      </div>

      {anexos && anexos.length > 0 ? (
        <div className="space-y-2">
          {anexos.map((anexo) => (
            <Card key={anexo.id}>
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3 flex-1 min-w-0">
                    {getFileIcon(anexo.tipo_arquivo || "")}
                    <div className="flex-1 min-w-0">
                      <p className="font-medium truncate">{anexo.nome_arquivo}</p>
                      <p className="text-sm text-muted-foreground">
                        {formatFileSize(anexo.tamanho_bytes || 0)} • {anexo.uploader?.full_name} •{" "}
                        {new Date(anexo.created_at).toLocaleDateString("pt-BR")}
                      </p>
                    </div>
                  </div>
                  <div className="flex gap-1">
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => handleDownload(anexo)}
                    >
                      <Download className="h-4 w-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => setDeleteId(anexo.id)}
                    >
                      <Trash2 className="h-4 w-4 text-destructive" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <Card>
          <CardContent className="py-8 text-center text-muted-foreground">
            Nenhum anexo adicionado
          </CardContent>
        </Card>
      )}

      <AlertDialog open={!!deleteId} onOpenChange={() => setDeleteId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Confirmar exclusão</AlertDialogTitle>
            <AlertDialogDescription>
              Tem certeza que deseja excluir este arquivo? Esta ação não pode ser desfeita.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction onClick={handleDelete} className="bg-destructive text-destructive-foreground">
              Excluir
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}