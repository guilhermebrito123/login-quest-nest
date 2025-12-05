export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "13.0.5"
  }
  public: {
    Tables: {
      ativos: {
        Row: {
          categoria: string | null
          created_at: string | null
          critico: boolean | null
          data_instalacao: string | null
          fabricante: string | null
          frequencia_preventiva_dias: number | null
          id: string
          modelo: string | null
          numero_serie: string | null
          status: string | null
          tag_patrimonio: string
          unidade_id: string | null
          updated_at: string | null
        }
        Insert: {
          categoria?: string | null
          created_at?: string | null
          critico?: boolean | null
          data_instalacao?: string | null
          fabricante?: string | null
          frequencia_preventiva_dias?: number | null
          id?: string
          modelo?: string | null
          numero_serie?: string | null
          status?: string | null
          tag_patrimonio: string
          unidade_id?: string | null
          updated_at?: string | null
        }
        Update: {
          categoria?: string | null
          created_at?: string | null
          critico?: boolean | null
          data_instalacao?: string | null
          fabricante?: string | null
          frequencia_preventiva_dias?: number | null
          id?: string
          modelo?: string | null
          numero_serie?: string | null
          status?: string | null
          tag_patrimonio?: string
          unidade_id?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "ativos_unidade_id_fkey"
            columns: ["unidade_id"]
            isOneToOne: false
            referencedRelation: "unidades"
            referencedColumns: ["id"]
          },
        ]
      }
      chamados: {
        Row: {
          atribuido_para_id: string | null
          avaliacao: number | null
          canal: string | null
          categoria: string | null
          comentario_avaliacao: string | null
          contrato_id: string | null
          created_at: string | null
          data_abertura: string | null
          data_conclusao: string | null
          descricao: string | null
          id: string
          numero: string
          posto_servico_id: string | null
          prioridade: string | null
          responsavel_id: string | null
          sla_horas: number | null
          solicitante_id: string | null
          status: string | null
          subcategoria: string | null
          tipo: string
          titulo: string
          unidade_id: string | null
          updated_at: string | null
        }
        Insert: {
          atribuido_para_id?: string | null
          avaliacao?: number | null
          canal?: string | null
          categoria?: string | null
          comentario_avaliacao?: string | null
          contrato_id?: string | null
          created_at?: string | null
          data_abertura?: string | null
          data_conclusao?: string | null
          descricao?: string | null
          id?: string
          numero: string
          posto_servico_id?: string | null
          prioridade?: string | null
          responsavel_id?: string | null
          sla_horas?: number | null
          solicitante_id?: string | null
          status?: string | null
          subcategoria?: string | null
          tipo: string
          titulo: string
          unidade_id?: string | null
          updated_at?: string | null
        }
        Update: {
          atribuido_para_id?: string | null
          avaliacao?: number | null
          canal?: string | null
          categoria?: string | null
          comentario_avaliacao?: string | null
          contrato_id?: string | null
          created_at?: string | null
          data_abertura?: string | null
          data_conclusao?: string | null
          descricao?: string | null
          id?: string
          numero?: string
          posto_servico_id?: string | null
          prioridade?: string | null
          responsavel_id?: string | null
          sla_horas?: number | null
          solicitante_id?: string | null
          status?: string | null
          subcategoria?: string | null
          tipo?: string
          titulo?: string
          unidade_id?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "chamados_atribuido_para_id_fkey"
            columns: ["atribuido_para_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chamados_contrato_id_fkey"
            columns: ["contrato_id"]
            isOneToOne: false
            referencedRelation: "contratos"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chamados_posto_servico_id_fkey"
            columns: ["posto_servico_id"]
            isOneToOne: false
            referencedRelation: "postos_servico"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chamados_responsavel_id_fkey"
            columns: ["responsavel_id"]
            isOneToOne: false
            referencedRelation: "colaboradores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chamados_unidade_id_fkey"
            columns: ["unidade_id"]
            isOneToOne: false
            referencedRelation: "unidades"
            referencedColumns: ["id"]
          },
        ]
      }
      chamados_anexos: {
        Row: {
          caminho_storage: string
          chamado_id: string
          created_at: string | null
          id: string
          nome_arquivo: string
          tamanho_bytes: number | null
          tipo_arquivo: string | null
          usuario_id: string
        }
        Insert: {
          caminho_storage: string
          chamado_id: string
          created_at?: string | null
          id?: string
          nome_arquivo: string
          tamanho_bytes?: number | null
          tipo_arquivo?: string | null
          usuario_id: string
        }
        Update: {
          caminho_storage?: string
          chamado_id?: string
          created_at?: string | null
          id?: string
          nome_arquivo?: string
          tamanho_bytes?: number | null
          tipo_arquivo?: string | null
          usuario_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "chamados_anexos_chamado_id_fkey"
            columns: ["chamado_id"]
            isOneToOne: false
            referencedRelation: "chamados"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chamados_anexos_usuario_id_fkey"
            columns: ["usuario_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      chamados_comentarios: {
        Row: {
          chamado_id: string
          comentario: string
          created_at: string | null
          id: string
          updated_at: string | null
          usuario_id: string
        }
        Insert: {
          chamado_id: string
          comentario: string
          created_at?: string | null
          id?: string
          updated_at?: string | null
          usuario_id: string
        }
        Update: {
          chamado_id?: string
          comentario?: string
          created_at?: string | null
          id?: string
          updated_at?: string | null
          usuario_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "chamados_comentarios_chamado_id_fkey"
            columns: ["chamado_id"]
            isOneToOne: false
            referencedRelation: "chamados"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chamados_comentarios_usuario_id_fkey"
            columns: ["usuario_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist: {
        Row: {
          created_at: string
          id: string
          nome: string
          periodicidade: Database["public"]["Enums"]["periodicidade_type"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          nome: string
          periodicidade: Database["public"]["Enums"]["periodicidade_type"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          nome?: string
          periodicidade?: Database["public"]["Enums"]["periodicidade_type"]
          updated_at?: string
        }
        Relationships: []
      }
      checklist_item: {
        Row: {
          checklist_id: string
          created_at: string
          descricao: string
          id: string
          item_id: string | null
          periodicidade: Database["public"]["Enums"]["periodicidade_type"]
        }
        Insert: {
          checklist_id: string
          created_at?: string
          descricao: string
          id?: string
          item_id?: string | null
          periodicidade: Database["public"]["Enums"]["periodicidade_type"]
        }
        Update: {
          checklist_id?: string
          created_at?: string
          descricao?: string
          id?: string
          item_id?: string | null
          periodicidade?: Database["public"]["Enums"]["periodicidade_type"]
        }
        Relationships: [
          {
            foreignKeyName: "checklist_item_checklist_id_fkey"
            columns: ["checklist_id"]
            isOneToOne: false
            referencedRelation: "checklist"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_item_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "itens_estoque"
            referencedColumns: ["id"]
          },
        ]
      }
      clientes: {
        Row: {
          cnpj: string
          contato_email: string | null
          contato_nome: string | null
          contato_telefone: string | null
          created_at: string
          id: string
          nome_fantasia: string
          razao_social: string
          updated_at: string
        }
        Insert: {
          cnpj: string
          contato_email?: string | null
          contato_nome?: string | null
          contato_telefone?: string | null
          created_at?: string
          id: string
          nome_fantasia?: string
          razao_social: string
          updated_at?: string
        }
        Update: {
          cnpj?: string
          contato_email?: string | null
          contato_nome?: string | null
          contato_telefone?: string | null
          created_at?: string
          id?: string
          nome_fantasia?: string
          razao_social?: string
          updated_at?: string
        }
        Relationships: []
      }
      colaborador_movimentacoes_posto: {
        Row: {
          colaborador_id: string
          created_at: string
          created_by: string
          data_desvinculacao: string | null
          data_vinculacao: string | null
          id: string
          motivo: string | null
          posto_servico_id_destino: string | null
          posto_servico_id_origem: string | null
          status: string
          updated_at: string
        }
        Insert: {
          colaborador_id: string
          created_at?: string
          created_by: string
          data_desvinculacao?: string | null
          data_vinculacao?: string | null
          id?: string
          motivo?: string | null
          posto_servico_id_destino?: string | null
          posto_servico_id_origem?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          colaborador_id?: string
          created_at?: string
          created_by?: string
          data_desvinculacao?: string | null
          data_vinculacao?: string | null
          id?: string
          motivo?: string | null
          posto_servico_id_destino?: string | null
          posto_servico_id_origem?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "colaborador_movimentacoes_posto_colaborador_id_fkey"
            columns: ["colaborador_id"]
            isOneToOne: false
            referencedRelation: "colaboradores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "colaborador_movimentacoes_posto_posto_servico_id_destino_fkey"
            columns: ["posto_servico_id_destino"]
            isOneToOne: false
            referencedRelation: "postos_servico"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "colaborador_movimentacoes_posto_posto_servico_id_origem_fkey"
            columns: ["posto_servico_id_origem"]
            isOneToOne: false
            referencedRelation: "postos_servico"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_movimentacoes_colaborador"
            columns: ["colaborador_id"]
            isOneToOne: false
            referencedRelation: "colaboradores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_movimentacoes_posto_destino"
            columns: ["posto_servico_id_destino"]
            isOneToOne: false
            referencedRelation: "postos_servico"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_movimentacoes_posto_origem"
            columns: ["posto_servico_id_origem"]
            isOneToOne: false
            referencedRelation: "postos_servico"
            referencedColumns: ["id"]
          },
        ]
      }
      colaboradores: {
        Row: {
          cargo: string | null
          cpf: string
          created_at: string | null
          data_admissao: string | null
          data_desligamento: string | null
          email: string | null
          escala_id: string | null
          id: string
          nome_completo: string
          observacoes: string | null
          posto_servico_id: string | null
          status_colaborador: Database["public"]["Enums"]["status_colaborador"]
          telefone: string | null
          unidade_id: string | null
          updated_at: string | null
        }
        Insert: {
          cargo?: string | null
          cpf: string
          created_at?: string | null
          data_admissao?: string | null
          data_desligamento?: string | null
          email?: string | null
          escala_id?: string | null
          id?: string
          nome_completo: string
          observacoes?: string | null
          posto_servico_id?: string | null
          status_colaborador?: Database["public"]["Enums"]["status_colaborador"]
          telefone?: string | null
          unidade_id?: string | null
          updated_at?: string | null
        }
        Update: {
          cargo?: string | null
          cpf?: string
          created_at?: string | null
          data_admissao?: string | null
          data_desligamento?: string | null
          email?: string | null
          escala_id?: string | null
          id?: string
          nome_completo?: string
          observacoes?: string | null
          posto_servico_id?: string | null
          status_colaborador?: Database["public"]["Enums"]["status_colaborador"]
          telefone?: string | null
          unidade_id?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "colaboradores_escala_id_fkey"
            columns: ["escala_id"]
            isOneToOne: false
            referencedRelation: "escalas"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "colaboradores_posto_servico_id_fkey"
            columns: ["posto_servico_id"]
            isOneToOne: false
            referencedRelation: "postos_servico"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "colaboradores_unidade_id_fkey"
            columns: ["unidade_id"]
            isOneToOne: false
            referencedRelation: "unidades"
            referencedColumns: ["id"]
          },
        ]
      }
      contratos: {
        Row: {
          cliente_id: string
          conq_perd: number
          created_at: string | null
          data_fim: string | null
          data_inicio: string
          id: string
          negocio: string
          updated_at: string | null
        }
        Insert: {
          cliente_id: string
          conq_perd: number
          created_at?: string | null
          data_fim?: string | null
          data_inicio: string
          id?: string
          negocio: string
          updated_at?: string | null
        }
        Update: {
          cliente_id?: string
          conq_perd?: number
          created_at?: string | null
          data_fim?: string | null
          data_inicio?: string
          id?: string
          negocio?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "contratos_cliente_id_fkey"
            columns: ["cliente_id"]
            isOneToOne: false
            referencedRelation: "clientes"
            referencedColumns: ["id"]
          },
        ]
      }
      diarias: {
        Row: {
          created_at: string
          diarista_id: string
          id: string
          motivo_cancelamento: string | null
          motivo_reprovacao: string | null
          posto_dia_vago_id: string
          status: Database["public"]["Enums"]["status_diaria"]
          updated_at: string
          valor: number
        }
        Insert: {
          created_at?: string
          diarista_id: string
          id?: string
          motivo_cancelamento?: string | null
          motivo_reprovacao?: string | null
          posto_dia_vago_id: string
          status?: Database["public"]["Enums"]["status_diaria"]
          updated_at?: string
          valor: number
        }
        Update: {
          created_at?: string
          diarista_id?: string
          id?: string
          motivo_cancelamento?: string | null
          motivo_reprovacao?: string | null
          posto_dia_vago_id?: string
          status?: Database["public"]["Enums"]["status_diaria"]
          updated_at?: string
          valor?: number
        }
        Relationships: [
          {
            foreignKeyName: "diarias_diarista_id_fkey"
            columns: ["diarista_id"]
            isOneToOne: false
            referencedRelation: "diaristas"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "diarias_posto_dia_vago_id_fkey"
            columns: ["posto_dia_vago_id"]
            isOneToOne: false
            referencedRelation: "posto_dias_vagos"
            referencedColumns: ["id"]
          },
        ]
      }
      diarias_temporarias: {
        Row: {
          colaborador_ausente: string | null
          colaborador_demitido: string | null
          created_at: string
          data_diaria: string
          demissao: boolean | null
          diarista_id: string
          horario_fim: string | null
          horario_inicio: string | null
          id: number
          intervalo: number | null
          jornada_diaria: number | null
          motivo_cancelamento: string | null
          motivo_reprovacao: string | null
          motivo_vago: Database["public"]["Enums"]["motivo_vago_type"]
          posto_servico_id: string
          status: Database["public"]["Enums"]["status_diaria"]
          updated_at: string
          valor_diaria: number
        }
        Insert: {
          colaborador_ausente?: string | null
          colaborador_demitido?: string | null
          created_at?: string
          data_diaria: string
          demissao?: boolean | null
          diarista_id: string
          horario_fim?: string | null
          horario_inicio?: string | null
          id?: number
          intervalo?: number | null
          jornada_diaria?: number | null
          motivo_cancelamento?: string | null
          motivo_reprovacao?: string | null
          motivo_vago?: Database["public"]["Enums"]["motivo_vago_type"]
          posto_servico_id: string
          status?: Database["public"]["Enums"]["status_diaria"]
          updated_at?: string
          valor_diaria: number
        }
        Update: {
          colaborador_ausente?: string | null
          colaborador_demitido?: string | null
          created_at?: string
          data_diaria?: string
          demissao?: boolean | null
          diarista_id?: string
          horario_fim?: string | null
          horario_inicio?: string | null
          id?: number
          intervalo?: number | null
          jornada_diaria?: number | null
          motivo_cancelamento?: string | null
          motivo_reprovacao?: string | null
          motivo_vago?: Database["public"]["Enums"]["motivo_vago_type"]
          posto_servico_id?: string
          status?: Database["public"]["Enums"]["status_diaria"]
          updated_at?: string
          valor_diaria?: number
        }
        Relationships: [
          {
            foreignKeyName: "diarias_temporarias_colaborador_ausente_fkey"
            columns: ["colaborador_ausente"]
            isOneToOne: false
            referencedRelation: "colaboradores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "diarias_temporarias_colaborador_demitido_fkey"
            columns: ["colaborador_demitido"]
            isOneToOne: false
            referencedRelation: "colaboradores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "diarias_temporarias_diarista_id_fkey"
            columns: ["diarista_id"]
            isOneToOne: false
            referencedRelation: "diaristas"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "diarias_temporarias_posto_servico_id_fkey"
            columns: ["posto_servico_id"]
            isOneToOne: false
            referencedRelation: "postos_servico"
            referencedColumns: ["id"]
          },
        ]
      }
      diaristas: {
        Row: {
          agencia: string | null
          anexo_comprovante_endereco: string | null
          anexo_cpf: string | null
          anexo_dados_bancarios: string | null
          anexo_possui_antecedente: string | null
          banco: string | null
          cep: string | null
          cidade: string | null
          cpf: string
          created_at: string
          email: string | null
          endereco: string | null
          id: string
          nome_completo: string
          numero_conta: string | null
          pix: string
          possui_antecedente: boolean | null
          status: Database["public"]["Enums"]["status_diarista"] | null
          telefone: string
          tipo_conta: Database["public"]["Enums"]["tipo_conta_bancaria"] | null
          updated_at: string
        }
        Insert: {
          agencia?: string | null
          anexo_comprovante_endereco?: string | null
          anexo_cpf?: string | null
          anexo_dados_bancarios?: string | null
          anexo_possui_antecedente?: string | null
          banco?: string | null
          cep?: string | null
          cidade?: string | null
          cpf?: string
          created_at?: string
          email?: string | null
          endereco?: string | null
          id?: string
          nome_completo: string
          numero_conta?: string | null
          pix?: string
          possui_antecedente?: boolean | null
          status?: Database["public"]["Enums"]["status_diarista"] | null
          telefone: string
          tipo_conta?: Database["public"]["Enums"]["tipo_conta_bancaria"] | null
          updated_at?: string
        }
        Update: {
          agencia?: string | null
          anexo_comprovante_endereco?: string | null
          anexo_cpf?: string | null
          anexo_dados_bancarios?: string | null
          anexo_possui_antecedente?: string | null
          banco?: string | null
          cep?: string | null
          cidade?: string | null
          cpf?: string
          created_at?: string
          email?: string | null
          endereco?: string | null
          id?: string
          nome_completo?: string
          numero_conta?: string | null
          pix?: string
          possui_antecedente?: boolean | null
          status?: Database["public"]["Enums"]["status_diarista"] | null
          telefone?: string
          tipo_conta?: Database["public"]["Enums"]["tipo_conta_bancaria"] | null
          updated_at?: string
        }
        Relationships: []
      }
      diaristas_anexos: {
        Row: {
          caminho_storage: string
          created_at: string
          diarista_id: string
          id: string
          nome_arquivo: string
          tamanho_bytes: number | null
          tipo_arquivo: string | null
          uploaded_by: string
        }
        Insert: {
          caminho_storage: string
          created_at?: string
          diarista_id: string
          id?: string
          nome_arquivo: string
          tamanho_bytes?: number | null
          tipo_arquivo?: string | null
          uploaded_by: string
        }
        Update: {
          caminho_storage?: string
          created_at?: string
          diarista_id?: string
          id?: string
          nome_arquivo?: string
          tamanho_bytes?: number | null
          tipo_arquivo?: string | null
          uploaded_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "diaristas_anexos_diarista_id_fkey"
            columns: ["diarista_id"]
            isOneToOne: false
            referencedRelation: "diaristas"
            referencedColumns: ["id"]
          },
        ]
      }
      dias_trabalho: {
        Row: {
          colaborador_id: string | null
          created_at: string | null
          data: string
          horario_fim: string | null
          horario_inicio: string | null
          id: string
          intervalo_refeicao: number | null
          motivo_vago: Database["public"]["Enums"]["motivo_vago_type"] | null
          posto_servico_id: string
          status: Database["public"]["Enums"]["status_posto"] | null
          updated_at: string | null
        }
        Insert: {
          colaborador_id?: string | null
          created_at?: string | null
          data: string
          horario_fim?: string | null
          horario_inicio?: string | null
          id?: string
          intervalo_refeicao?: number | null
          motivo_vago?: Database["public"]["Enums"]["motivo_vago_type"] | null
          posto_servico_id: string
          status?: Database["public"]["Enums"]["status_posto"] | null
          updated_at?: string | null
        }
        Update: {
          colaborador_id?: string | null
          created_at?: string | null
          data?: string
          horario_fim?: string | null
          horario_inicio?: string | null
          id?: string
          intervalo_refeicao?: number | null
          motivo_vago?: Database["public"]["Enums"]["motivo_vago_type"] | null
          posto_servico_id?: string
          status?: Database["public"]["Enums"]["status_posto"] | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "dias_trabalho_colaborador_id_fkey"
            columns: ["colaborador_id"]
            isOneToOne: false
            referencedRelation: "colaboradores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "dias_trabalho_posto_servico_id_fkey"
            columns: ["posto_servico_id"]
            isOneToOne: false
            referencedRelation: "postos_servico"
            referencedColumns: ["id"]
          },
        ]
      }
      escalas: {
        Row: {
          created_at: string | null
          descricao: string | null
          dias_folga: number | null
          dias_trabalhados: number | null
          id: string
          nome: string
          tipo: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          descricao?: string | null
          dias_folga?: number | null
          dias_trabalhados?: number | null
          id?: string
          nome: string
          tipo: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          descricao?: string | null
          dias_folga?: number | null
          dias_trabalhados?: number | null
          id?: string
          nome?: string
          tipo?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      execucao_checklist: {
        Row: {
          checklist_id: string
          contrato_id: string | null
          created_at: string
          data_prevista: string
          finalizado_em: string | null
          id: string
          status: Database["public"]["Enums"]["status_execucao"]
          supervisor_id: string | null
          unidade_id: string | null
          updated_at: string
        }
        Insert: {
          checklist_id: string
          contrato_id?: string | null
          created_at?: string
          data_prevista: string
          finalizado_em?: string | null
          id: string
          status?: Database["public"]["Enums"]["status_execucao"]
          supervisor_id?: string | null
          unidade_id?: string | null
          updated_at?: string
        }
        Update: {
          checklist_id?: string
          contrato_id?: string | null
          created_at?: string
          data_prevista?: string
          finalizado_em?: string | null
          id?: string
          status?: Database["public"]["Enums"]["status_execucao"]
          supervisor_id?: string | null
          unidade_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "execucao_checklist_checklist_id_fkey"
            columns: ["checklist_id"]
            isOneToOne: false
            referencedRelation: "checklist"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "execucao_checklist_contrato_id_fkey"
            columns: ["contrato_id"]
            isOneToOne: false
            referencedRelation: "contratos"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "execucao_checklist_supervisor_id_fkey"
            columns: ["supervisor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "execucao_checklist_unidade_id_fkey"
            columns: ["unidade_id"]
            isOneToOne: false
            referencedRelation: "unidades"
            referencedColumns: ["id"]
          },
        ]
      }
      execucao_checklist_item: {
        Row: {
          checklist_item_id: string
          contrato_id: string | null
          created_at: string
          data_prevista: string
          execucao_checklist_id: string
          finalizado_em: string | null
          foto: string | null
          id: string
          resposta: string | null
          status: Database["public"]["Enums"]["status_execucao"]
          supervisor_id: string | null
          unidade_id: string | null
          updated_at: string
        }
        Insert: {
          checklist_item_id: string
          contrato_id?: string | null
          created_at?: string
          data_prevista: string
          execucao_checklist_id: string
          finalizado_em?: string | null
          foto?: string | null
          id: string
          resposta?: string | null
          status?: Database["public"]["Enums"]["status_execucao"]
          supervisor_id?: string | null
          unidade_id?: string | null
          updated_at?: string
        }
        Update: {
          checklist_item_id?: string
          contrato_id?: string | null
          created_at?: string
          data_prevista?: string
          execucao_checklist_id?: string
          finalizado_em?: string | null
          foto?: string | null
          id?: string
          resposta?: string | null
          status?: Database["public"]["Enums"]["status_execucao"]
          supervisor_id?: string | null
          unidade_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "execucao_checklist_item_checklist_item_id_fkey"
            columns: ["checklist_item_id"]
            isOneToOne: false
            referencedRelation: "checklist_item"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "execucao_checklist_item_contrato_id_fkey"
            columns: ["contrato_id"]
            isOneToOne: false
            referencedRelation: "contratos"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "execucao_checklist_item_execucao_checklist_id_fkey"
            columns: ["execucao_checklist_id"]
            isOneToOne: false
            referencedRelation: "execucao_checklist"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "execucao_checklist_item_supervisor_id_fkey"
            columns: ["supervisor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "execucao_checklist_item_unidade_id_fkey"
            columns: ["unidade_id"]
            isOneToOne: false
            referencedRelation: "unidades"
            referencedColumns: ["id"]
          },
        ]
      }
      incidentes: {
        Row: {
          acao_tomada: string | null
          categoria: string | null
          created_at: string | null
          data_ocorrencia: string | null
          data_resolucao: string | null
          descricao: string | null
          id: string
          impacto: string | null
          numero: string
          reportado_por_id: string | null
          responsavel_id: string | null
          severidade: string
          status: string | null
          titulo: string
          unidade_id: string | null
          updated_at: string | null
        }
        Insert: {
          acao_tomada?: string | null
          categoria?: string | null
          created_at?: string | null
          data_ocorrencia?: string | null
          data_resolucao?: string | null
          descricao?: string | null
          id?: string
          impacto?: string | null
          numero: string
          reportado_por_id?: string | null
          responsavel_id?: string | null
          severidade: string
          status?: string | null
          titulo: string
          unidade_id?: string | null
          updated_at?: string | null
        }
        Update: {
          acao_tomada?: string | null
          categoria?: string | null
          created_at?: string | null
          data_ocorrencia?: string | null
          data_resolucao?: string | null
          descricao?: string | null
          id?: string
          impacto?: string | null
          numero?: string
          reportado_por_id?: string | null
          responsavel_id?: string | null
          severidade?: string
          status?: string | null
          titulo?: string
          unidade_id?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "incidentes_responsavel_id_fkey"
            columns: ["responsavel_id"]
            isOneToOne: false
            referencedRelation: "colaboradores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "incidentes_unidade_id_fkey"
            columns: ["unidade_id"]
            isOneToOne: false
            referencedRelation: "unidades"
            referencedColumns: ["id"]
          },
        ]
      }
      inspecoes: {
        Row: {
          acompanhamento_cliente: string | null
          apresentacao_pessoal: string | null
          colaborador_id: string | null
          created_at: string | null
          data_hora: string
          disponibilidade_equipamentos: string | null
          disponibilidade_recursos: string | null
          id: string
          inspetor: string
          observacoes: string | null
          outras_observacoes: string | null
          posto_servico_id: string | null
          problemas_po: string | null
          status_inspecao: string | null
          updated_at: string | null
          uso_uniforme: string | null
        }
        Insert: {
          acompanhamento_cliente?: string | null
          apresentacao_pessoal?: string | null
          colaborador_id?: string | null
          created_at?: string | null
          data_hora?: string
          disponibilidade_equipamentos?: string | null
          disponibilidade_recursos?: string | null
          id?: string
          inspetor: string
          observacoes?: string | null
          outras_observacoes?: string | null
          posto_servico_id?: string | null
          problemas_po?: string | null
          status_inspecao?: string | null
          updated_at?: string | null
          uso_uniforme?: string | null
        }
        Update: {
          acompanhamento_cliente?: string | null
          apresentacao_pessoal?: string | null
          colaborador_id?: string | null
          created_at?: string | null
          data_hora?: string
          disponibilidade_equipamentos?: string | null
          disponibilidade_recursos?: string | null
          id?: string
          inspetor?: string
          observacoes?: string | null
          outras_observacoes?: string | null
          posto_servico_id?: string | null
          problemas_po?: string | null
          status_inspecao?: string | null
          updated_at?: string | null
          uso_uniforme?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "inspecoes_colaborador_id_fkey"
            columns: ["colaborador_id"]
            isOneToOne: false
            referencedRelation: "colaboradores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inspecoes_posto_servico_id_fkey"
            columns: ["posto_servico_id"]
            isOneToOne: false
            referencedRelation: "postos_servico"
            referencedColumns: ["id"]
          },
        ]
      }
      itens_estoque: {
        Row: {
          created_at: string | null
          descricao: string
          id: string
          nome: string
          quantidade_atual: number
          quantidade_minima: number
          sku: string
          unidade_id: string | null
          unidade_medida: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          descricao: string
          id?: string
          nome?: string
          quantidade_atual: number
          quantidade_minima: number
          sku: string
          unidade_id?: string | null
          unidade_medida: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          descricao?: string
          id?: string
          nome?: string
          quantidade_atual?: number
          quantidade_minima?: number
          sku?: string
          unidade_id?: string | null
          unidade_medida?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "itens_estoque_unidade_id_fkey"
            columns: ["unidade_id"]
            isOneToOne: false
            referencedRelation: "unidades"
            referencedColumns: ["id"]
          },
        ]
      }
      notificacoes: {
        Row: {
          created_at: string
          id: string
          lida: boolean
          link: string | null
          mensagem: string
          tipo: string
          titulo: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          lida?: boolean
          link?: string | null
          mensagem: string
          tipo?: string
          titulo: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          lida?: boolean
          link?: string | null
          mensagem?: string
          tipo?: string
          titulo?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      ordens_servico: {
        Row: {
          ativo_id: string | null
          created_at: string | null
          data_abertura: string | null
          data_conclusao: string | null
          data_prevista: string | null
          descricao: string | null
          id: string
          numero: string
          observacoes: string | null
          prioridade: string | null
          responsavel_id: string | null
          solicitante_id: string | null
          status: string | null
          tipo: string
          titulo: string
          unidade_id: string | null
          updated_at: string | null
        }
        Insert: {
          ativo_id?: string | null
          created_at?: string | null
          data_abertura?: string | null
          data_conclusao?: string | null
          data_prevista?: string | null
          descricao?: string | null
          id?: string
          numero: string
          observacoes?: string | null
          prioridade?: string | null
          responsavel_id?: string | null
          solicitante_id?: string | null
          status?: string | null
          tipo: string
          titulo: string
          unidade_id?: string | null
          updated_at?: string | null
        }
        Update: {
          ativo_id?: string | null
          created_at?: string | null
          data_abertura?: string | null
          data_conclusao?: string | null
          data_prevista?: string | null
          descricao?: string | null
          id?: string
          numero?: string
          observacoes?: string | null
          prioridade?: string | null
          responsavel_id?: string | null
          solicitante_id?: string | null
          status?: string | null
          tipo?: string
          titulo?: string
          unidade_id?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "ordens_servico_ativo_id_fkey"
            columns: ["ativo_id"]
            isOneToOne: false
            referencedRelation: "ativos"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ordens_servico_responsavel_id_fkey"
            columns: ["responsavel_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ordens_servico_solicitante_id_fkey"
            columns: ["solicitante_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ordens_servico_unidade_id_fkey"
            columns: ["unidade_id"]
            isOneToOne: false
            referencedRelation: "unidades"
            referencedColumns: ["id"]
          },
        ]
      }
      os_anexos: {
        Row: {
          caminho_storage: string
          created_at: string
          id: string
          nome_arquivo: string
          os_id: string
          tamanho_bytes: number | null
          tipo_arquivo: string | null
          uploaded_by: string
        }
        Insert: {
          caminho_storage: string
          created_at?: string
          id?: string
          nome_arquivo: string
          os_id: string
          tamanho_bytes?: number | null
          tipo_arquivo?: string | null
          uploaded_by: string
        }
        Update: {
          caminho_storage?: string
          created_at?: string
          id?: string
          nome_arquivo?: string
          os_id?: string
          tamanho_bytes?: number | null
          tipo_arquivo?: string | null
          uploaded_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "os_anexos_os_id_fkey"
            columns: ["os_id"]
            isOneToOne: false
            referencedRelation: "ordens_servico"
            referencedColumns: ["id"]
          },
        ]
      }
      os_historico: {
        Row: {
          acao: string
          campo_alterado: string | null
          created_at: string
          id: string
          observacao: string | null
          os_id: string
          usuario_id: string
          valor_anterior: string | null
          valor_novo: string | null
        }
        Insert: {
          acao: string
          campo_alterado?: string | null
          created_at?: string
          id?: string
          observacao?: string | null
          os_id: string
          usuario_id: string
          valor_anterior?: string | null
          valor_novo?: string | null
        }
        Update: {
          acao?: string
          campo_alterado?: string | null
          created_at?: string
          id?: string
          observacao?: string | null
          os_id?: string
          usuario_id?: string
          valor_anterior?: string | null
          valor_novo?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "os_historico_os_id_fkey"
            columns: ["os_id"]
            isOneToOne: false
            referencedRelation: "ordens_servico"
            referencedColumns: ["id"]
          },
        ]
      }
      posto_dias_vagos: {
        Row: {
          colaborador_id: string | null
          created_at: string
          created_by: string
          data: string
          id: string
          motivo: string | null
          posto_servico_id: string
        }
        Insert: {
          colaborador_id?: string | null
          created_at?: string
          created_by: string
          data: string
          id?: string
          motivo?: string | null
          posto_servico_id: string
        }
        Update: {
          colaborador_id?: string | null
          created_at?: string
          created_by?: string
          data?: string
          id?: string
          motivo?: string | null
          posto_servico_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "posto_dias_vagos_colaborador_id_fkey"
            columns: ["colaborador_id"]
            isOneToOne: false
            referencedRelation: "colaboradores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "posto_dias_vagos_posto_servico_id_fkey"
            columns: ["posto_servico_id"]
            isOneToOne: false
            referencedRelation: "postos_servico"
            referencedColumns: ["id"]
          },
        ]
      }
      posto_jornadas: {
        Row: {
          ano: number
          created_at: string
          created_by: string
          dias_trabalho: string[]
          id: string
          mes: number
          posto_servico_id: string
        }
        Insert: {
          ano: number
          created_at?: string
          created_by: string
          dias_trabalho: string[]
          id?: string
          mes: number
          posto_servico_id: string
        }
        Update: {
          ano?: number
          created_at?: string
          created_by?: string
          dias_trabalho?: string[]
          id?: string
          mes?: number
          posto_servico_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "posto_jornadas_posto_servico_id_fkey"
            columns: ["posto_servico_id"]
            isOneToOne: false
            referencedRelation: "postos_servico"
            referencedColumns: ["id"]
          },
        ]
      }
      postos_servico: {
        Row: {
          beneficios: string[] | null
          created_at: string | null
          dias_semana: number[] | null
          escala: string | null
          funcao: string
          horario_fim: string | null
          horario_inicio: string | null
          id: string
          intervalo_refeicao: number | null
          jornada: number | null
          nome: string
          observacoes: string | null
          primeiro_dia_atividade: string | null
          status: Database["public"]["Enums"]["status_posto"] | null
          ultimo_dia_atividade: string | null
          unidade_id: string | null
          updated_at: string | null
          valor_diaria: number
        }
        Insert: {
          beneficios?: string[] | null
          created_at?: string | null
          dias_semana?: number[] | null
          escala?: string | null
          funcao: string
          horario_fim?: string | null
          horario_inicio?: string | null
          id?: string
          intervalo_refeicao?: number | null
          jornada?: number | null
          nome: string
          observacoes?: string | null
          primeiro_dia_atividade?: string | null
          status?: Database["public"]["Enums"]["status_posto"] | null
          ultimo_dia_atividade?: string | null
          unidade_id?: string | null
          updated_at?: string | null
          valor_diaria?: number
        }
        Update: {
          beneficios?: string[] | null
          created_at?: string | null
          dias_semana?: number[] | null
          escala?: string | null
          funcao?: string
          horario_fim?: string | null
          horario_inicio?: string | null
          id?: string
          intervalo_refeicao?: number | null
          jornada?: number | null
          nome?: string
          observacoes?: string | null
          primeiro_dia_atividade?: string | null
          status?: Database["public"]["Enums"]["status_posto"] | null
          ultimo_dia_atividade?: string | null
          unidade_id?: string | null
          updated_at?: string | null
          valor_diaria?: number
        }
        Relationships: [
          {
            foreignKeyName: "postos_servico_unidade_id_fkey"
            columns: ["unidade_id"]
            isOneToOne: false
            referencedRelation: "unidades"
            referencedColumns: ["id"]
          },
        ]
      }
      presencas: {
        Row: {
          colaborador_id: string
          created_at: string
          data: string
          horario_entrada: string | null
          horario_saida: string | null
          id: string
          observacao: string | null
          posto_servico_id: string | null
          registrado_por: string
          tipo: string
          updated_at: string
        }
        Insert: {
          colaborador_id: string
          created_at?: string
          data: string
          horario_entrada?: string | null
          horario_saida?: string | null
          id?: string
          observacao?: string | null
          posto_servico_id?: string | null
          registrado_por: string
          tipo: string
          updated_at?: string
        }
        Update: {
          colaborador_id?: string
          created_at?: string
          data?: string
          horario_entrada?: string | null
          horario_saida?: string | null
          id?: string
          observacao?: string | null
          posto_servico_id?: string | null
          registrado_por?: string
          tipo?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "presencas_colaborador_id_fkey"
            columns: ["colaborador_id"]
            isOneToOne: false
            referencedRelation: "colaboradores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "presencas_posto_servico_id_fkey"
            columns: ["posto_servico_id"]
            isOneToOne: false
            referencedRelation: "postos_servico"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          created_at: string
          email: string
          full_name: string | null
          id: string
          phone: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          email: string
          full_name?: string | null
          id: string
          phone?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          email?: string
          full_name?: string | null
          id?: string
          phone?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      recursos_materiais: {
        Row: {
          created_at: string | null
          id: string
          nome: string
          observacoes: string | null
          quantidade: number | null
          quantidade_minima: number | null
          status: string | null
          tipo: string | null
          unidade_id: string | null
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          nome: string
          observacoes?: string | null
          quantidade?: number | null
          quantidade_minima?: number | null
          status?: string | null
          tipo?: string | null
          unidade_id?: string | null
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          nome?: string
          observacoes?: string | null
          quantidade?: number | null
          quantidade_minima?: number | null
          status?: string | null
          tipo?: string | null
          unidade_id?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "recursos_materiais_unidade_id_fkey"
            columns: ["unidade_id"]
            isOneToOne: false
            referencedRelation: "unidades"
            referencedColumns: ["id"]
          },
        ]
      }
      resposta_execucao_checklist: {
        Row: {
          conforme: boolean
          execucao_checklist_id: string
          foto: string | null
          id: string
          observacoes: string | null
          registrado_em: string
          resposta: string
        }
        Insert: {
          conforme: boolean
          execucao_checklist_id: string
          foto?: string | null
          id?: string
          observacoes?: string | null
          registrado_em?: string
          resposta: string
        }
        Update: {
          conforme?: boolean
          execucao_checklist_id?: string
          foto?: string | null
          id?: string
          observacoes?: string | null
          registrado_em?: string
          resposta?: string
        }
        Relationships: [
          {
            foreignKeyName: "resposta_execucao_checklist_execucao_checklist_id_fkey"
            columns: ["execucao_checklist_id"]
            isOneToOne: false
            referencedRelation: "execucao_checklist"
            referencedColumns: ["id"]
          },
        ]
      }
      resposta_execucao_checklist_item: {
        Row: {
          conforme: boolean
          execucao_checklist_item_id: string
          foto: string | null
          id: string
          observacoes: string | null
          registrado_em: string
          resposta: string
        }
        Insert: {
          conforme: boolean
          execucao_checklist_item_id: string
          foto?: string | null
          id?: string
          observacoes?: string | null
          registrado_em?: string
          resposta: string
        }
        Update: {
          conforme?: boolean
          execucao_checklist_item_id?: string
          foto?: string | null
          id?: string
          observacoes?: string | null
          registrado_em?: string
          resposta?: string
        }
        Relationships: [
          {
            foreignKeyName: "resposta_execucao_checklist_ite_execucao_checklist_item_id_fkey"
            columns: ["execucao_checklist_item_id"]
            isOneToOne: false
            referencedRelation: "execucao_checklist_item"
            referencedColumns: ["id"]
          },
        ]
      }
      unidades: {
        Row: {
          cep: string | null
          cidade: string
          contrato_id: string
          created_at: string
          endereco: string
          faturamento_vendido: number
          id: string
          latitude: number
          longitude: number
          nome: string
          uf: string
          updated_at: string
        }
        Insert: {
          cep?: string | null
          cidade: string
          contrato_id: string
          created_at?: string
          endereco: string
          faturamento_vendido: number
          id?: string
          latitude: number
          longitude: number
          nome: string
          uf: string
          updated_at?: string
        }
        Update: {
          cep?: string | null
          cidade?: string
          contrato_id?: string
          created_at?: string
          endereco?: string
          faturamento_vendido?: number
          id?: string
          latitude?: number
          longitude?: number
          nome?: string
          uf?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "unidades_contrato_id_fkey"
            columns: ["contrato_id"]
            isOneToOne: false
            referencedRelation: "contratos"
            referencedColumns: ["id"]
          },
        ]
      }
      user_roles: {
        Row: {
          created_at: string
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      agendar_ocupacao_posto: {
        Args: {
          p_colaborador_id: string
          p_data: string
          p_posto_servico_id: string
          p_usuario_id?: string
        }
        Returns: undefined
      }
      arquivar_dias_trabalho_em_presencas: { Args: never; Returns: undefined }
      calcular_dias_escala: {
        Args: {
          p_data_fim: string
          p_data_inicio: string
          p_dias_semana: number[]
          p_escala: string
          p_primeiro_dia_atividade: string
        }
        Returns: {
          data_trabalho: string
        }[]
      }
      cancelar_execucao_checklist: {
        Args: { execucao_id: string }
        Returns: undefined
      }
      cancelar_execucao_checklist_item: {
        Args: { execucao_item_id: string }
        Returns: undefined
      }
      cancelar_ocupacao_posto: {
        Args: { p_data: string; p_posto_servico_id: string }
        Returns: {
          colaborador_id: string | null
          created_at: string | null
          data: string
          horario_fim: string | null
          horario_inicio: string | null
          id: string
          intervalo_refeicao: number | null
          motivo_vago: Database["public"]["Enums"]["motivo_vago_type"] | null
          posto_servico_id: string
          status: Database["public"]["Enums"]["status_posto"] | null
          updated_at: string | null
        }
        SetofOptions: {
          from: "*"
          to: "dias_trabalho"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      confirmar_presenca: {
        Args: {
          p_dia_trabalho_id: string
          p_novo_status: Database["public"]["Enums"]["status_posto"]
        }
        Returns: undefined
      }
      gerar_dias_trabalho_proximo_mes: { Args: never; Returns: undefined }
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      is_admin: { Args: { _user_id: string }; Returns: boolean }
      limpar_diarias_antigas: { Args: never; Returns: undefined }
      limpar_diarias_temporarias_antigas: { Args: never; Returns: undefined }
      limpar_posto_dias_vagos_antigos: { Args: never; Returns: undefined }
      limpar_presencas_antigas: { Args: never; Returns: undefined }
      processar_movimentacoes_agendadas: { Args: never; Returns: undefined }
    }
    Enums: {
      app_role:
        | "admin"
        | "gestor_operacoes"
        | "supervisor"
        | "analista_centro_controle"
        | "tecnico"
        | "cliente_view"
      motivo_vago_type:
        | "FALTA JUSTIFICADA"
        | "FALTA INJUSTIFICADA"
        | "AFASTAMENTO INSS"
        | "FÉRIAS"
        | "SUSPENSÃO"
        | "VAGA EM ABERTO (COBERTURA SALÁRIO)"
        | "LICENÇA MATERNIDADE"
        | "LICENÇA PATERNIDADE"
        | "LICENÇA CASAMENTO"
        | "LICENÇA NOJO (FALECIMENTO)"
      periodicidade_type:
        | "diaria"
        | "semanal"
        | "quinzenal"
        | "mensal"
        | "trimestral"
        | "semestral"
        | "anual"
      status_colaborador: "ativo" | "inativo"
      status_diaria:
        | "Aguardando confirmacao"
        | "Confirmada"
        | "Aprovada"
        | "Lançada para pagamento"
        | "Aprovada para pagamento"
        | "Cancelada"
        | "Reprovada"
        | "Paga"
      status_diarista: "ativo" | "inativo" | "desligado"
      status_execucao: "ativo" | "concluido" | "atrasado" | "cancelado"
      status_posto:
        | "vago"
        | "ocupado"
        | "vago_temporariamente"
        | "ocupado_temporariamente"
        | "presenca_confirmada"
        | "ocupacao_agendada"
        | "inativo"
      tipo_conta_bancaria: "conta corrente" | "conta poupança" | "conta salário"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: [
        "admin",
        "gestor_operacoes",
        "supervisor",
        "analista_centro_controle",
        "tecnico",
        "cliente_view",
      ],
      motivo_vago_type: [
        "FALTA JUSTIFICADA",
        "FALTA INJUSTIFICADA",
        "AFASTAMENTO INSS",
        "FÉRIAS",
        "SUSPENSÃO",
        "VAGA EM ABERTO (COBERTURA SALÁRIO)",
        "LICENÇA MATERNIDADE",
        "LICENÇA PATERNIDADE",
        "LICENÇA CASAMENTO",
        "LICENÇA NOJO (FALECIMENTO)",
      ],
      periodicidade_type: [
        "diaria",
        "semanal",
        "quinzenal",
        "mensal",
        "trimestral",
        "semestral",
        "anual",
      ],
      status_colaborador: ["ativo", "inativo"],
      status_diaria: [
        "Aguardando confirmacao",
        "Confirmada",
        "Aprovada",
        "Lançada para pagamento",
        "Aprovada para pagamento",
        "Cancelada",
        "Reprovada",
        "Paga",
      ],
      status_diarista: ["ativo", "inativo", "desligado"],
      status_execucao: ["ativo", "concluido", "atrasado", "cancelado"],
      status_posto: [
        "vago",
        "ocupado",
        "vago_temporariamente",
        "ocupado_temporariamente",
        "presenca_confirmada",
        "ocupacao_agendada",
        "inativo",
      ],
      tipo_conta_bancaria: [
        "conta corrente",
        "conta poupança",
        "conta salário",
      ],
    },
  },
} as const
