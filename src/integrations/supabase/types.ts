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
        ]
      }
      checklist_execucoes: {
        Row: {
          checklist_id: string | null
          colaborador_id: string | null
          created_at: string | null
          data_execucao: string | null
          id: string
          observacoes: string | null
          status: string | null
        }
        Insert: {
          checklist_id?: string | null
          colaborador_id?: string | null
          created_at?: string | null
          data_execucao?: string | null
          id?: string
          observacoes?: string | null
          status?: string | null
        }
        Update: {
          checklist_id?: string | null
          colaborador_id?: string | null
          created_at?: string | null
          data_execucao?: string | null
          id?: string
          observacoes?: string | null
          status?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "checklist_execucoes_checklist_id_fkey"
            columns: ["checklist_id"]
            isOneToOne: false
            referencedRelation: "checklists"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_execucoes_colaborador_id_fkey"
            columns: ["colaborador_id"]
            isOneToOne: false
            referencedRelation: "colaboradores"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist_itens: {
        Row: {
          checklist_id: string | null
          created_at: string | null
          descricao: string
          id: string
          obrigatorio: boolean | null
          ordem: number
          tipo_resposta: string | null
        }
        Insert: {
          checklist_id?: string | null
          created_at?: string | null
          descricao: string
          id?: string
          obrigatorio?: boolean | null
          ordem: number
          tipo_resposta?: string | null
        }
        Update: {
          checklist_id?: string | null
          created_at?: string | null
          descricao?: string
          id?: string
          obrigatorio?: boolean | null
          ordem?: number
          tipo_resposta?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "checklist_itens_checklist_id_fkey"
            columns: ["checklist_id"]
            isOneToOne: false
            referencedRelation: "checklists"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist_respostas: {
        Row: {
          conforme: boolean | null
          created_at: string | null
          execucao_id: string | null
          foto_url: string | null
          id: string
          item_id: string | null
          observacao: string | null
          resposta: string | null
        }
        Insert: {
          conforme?: boolean | null
          created_at?: string | null
          execucao_id?: string | null
          foto_url?: string | null
          id?: string
          item_id?: string | null
          observacao?: string | null
          resposta?: string | null
        }
        Update: {
          conforme?: boolean | null
          created_at?: string | null
          execucao_id?: string | null
          foto_url?: string | null
          id?: string
          item_id?: string | null
          observacao?: string | null
          resposta?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "checklist_respostas_execucao_id_fkey"
            columns: ["execucao_id"]
            isOneToOne: false
            referencedRelation: "checklist_execucoes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_respostas_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "checklist_itens"
            referencedColumns: ["id"]
          },
        ]
      }
      checklists: {
        Row: {
          created_at: string | null
          descricao: string | null
          id: string
          nome: string
          status: string | null
          tipo: string | null
          unidade_id: string | null
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          descricao?: string | null
          id?: string
          nome: string
          status?: string | null
          tipo?: string | null
          unidade_id?: string | null
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          descricao?: string | null
          id?: string
          nome?: string
          status?: string | null
          tipo?: string | null
          unidade_id?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "checklists_unidade_id_fkey"
            columns: ["unidade_id"]
            isOneToOne: false
            referencedRelation: "unidades"
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
          created_at: string | null
          id: string
          razao_social: string
          status: string | null
          updated_at: string | null
        }
        Insert: {
          cnpj: string
          contato_email?: string | null
          contato_nome?: string | null
          contato_telefone?: string | null
          created_at?: string | null
          id?: string
          razao_social: string
          status?: string | null
          updated_at?: string | null
        }
        Update: {
          cnpj?: string
          contato_email?: string | null
          contato_nome?: string | null
          contato_telefone?: string | null
          created_at?: string | null
          id?: string
          razao_social?: string
          status?: string | null
          updated_at?: string | null
        }
        Relationships: []
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
          status: string | null
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
          status?: string | null
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
          status?: string | null
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
          cliente_id: string | null
          codigo: string
          created_at: string | null
          data_fim: string | null
          data_inicio: string
          id: string
          nome: string
          nps_meta: number | null
          sla_alvo_pct: number | null
          status: string | null
          updated_at: string | null
        }
        Insert: {
          cliente_id?: string | null
          codigo: string
          created_at?: string | null
          data_fim?: string | null
          data_inicio: string
          id?: string
          nome: string
          nps_meta?: number | null
          sla_alvo_pct?: number | null
          status?: string | null
          updated_at?: string | null
        }
        Update: {
          cliente_id?: string | null
          codigo?: string
          created_at?: string | null
          data_fim?: string | null
          data_inicio?: string
          id?: string
          nome?: string
          nps_meta?: number | null
          sla_alvo_pct?: number | null
          status?: string | null
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
      diaristas: {
        Row: {
          cidade: string | null
          cnh: string
          created_at: string
          email: string
          endereco: string
          id: string
          nome_completo: string
          possui_antecedente: boolean
          rg: string
          status: string | null
          telefone: string
          updated_at: string
        }
        Insert: {
          cidade?: string | null
          cnh: string
          created_at?: string
          email: string
          endereco: string
          id?: string
          nome_completo: string
          possui_antecedente?: boolean
          rg: string
          status?: string | null
          telefone: string
          updated_at?: string
        }
        Update: {
          cidade?: string | null
          cnh?: string
          created_at?: string
          email?: string
          endereco?: string
          id?: string
          nome_completo?: string
          possui_antecedente?: boolean
          rg?: string
          status?: string | null
          telefone?: string
          updated_at?: string
        }
        Relationships: []
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
      itens_estoque: {
        Row: {
          created_at: string | null
          descricao: string
          id: string
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
            referencedRelation: "colaboradores"
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
          codigo: string
          created_at: string | null
          dias_semana: string[] | null
          efetivo_planejado: number | null
          escala: string | null
          funcao: string
          horario_fim: string | null
          horario_inicio: string | null
          id: string
          intervalo_refeicao: number | null
          jornada: string | null
          nome: string
          observacoes: string | null
          status: string | null
          turno: string | null
          unidade_id: string | null
          updated_at: string | null
        }
        Insert: {
          codigo: string
          created_at?: string | null
          dias_semana?: string[] | null
          efetivo_planejado?: number | null
          escala?: string | null
          funcao: string
          horario_fim?: string | null
          horario_inicio?: string | null
          id?: string
          intervalo_refeicao?: number | null
          jornada?: string | null
          nome: string
          observacoes?: string | null
          status?: string | null
          turno?: string | null
          unidade_id?: string | null
          updated_at?: string | null
        }
        Update: {
          codigo?: string
          created_at?: string | null
          dias_semana?: string[] | null
          efetivo_planejado?: number | null
          escala?: string | null
          funcao?: string
          horario_fim?: string | null
          horario_inicio?: string | null
          id?: string
          intervalo_refeicao?: number | null
          jornada?: string | null
          nome?: string
          observacoes?: string | null
          status?: string | null
          turno?: string | null
          unidade_id?: string | null
          updated_at?: string | null
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
      unidades: {
        Row: {
          cep: string | null
          cidade: string | null
          codigo: string
          contrato_id: string | null
          created_at: string | null
          criticidade: string | null
          endereco: string | null
          id: string
          latitude: number | null
          longitude: number | null
          nome: string
          status: string | null
          uf: string | null
          updated_at: string | null
        }
        Insert: {
          cep?: string | null
          cidade?: string | null
          codigo: string
          contrato_id?: string | null
          created_at?: string | null
          criticidade?: string | null
          endereco?: string | null
          id?: string
          latitude?: number | null
          longitude?: number | null
          nome: string
          status?: string | null
          uf?: string | null
          updated_at?: string | null
        }
        Update: {
          cep?: string | null
          cidade?: string | null
          codigo?: string
          contrato_id?: string | null
          created_at?: string | null
          criticidade?: string | null
          endereco?: string | null
          id?: string
          latitude?: number | null
          longitude?: number | null
          nome?: string
          status?: string | null
          uf?: string | null
          updated_at?: string | null
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
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      is_admin: { Args: { _user_id: string }; Returns: boolean }
    }
    Enums: {
      app_role:
        | "admin"
        | "gestor_operacoes"
        | "supervisor"
        | "analista_centro_controle"
        | "tecnico"
        | "cliente_view"
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
    },
  },
} as const
