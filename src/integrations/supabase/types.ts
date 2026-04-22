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
      account_recovery_audit: {
        Row: {
          action: string
          actor_user_id: string | null
          created_at: string
          id: string
          metadata: Json | null
          request_id: string | null
          user_id: string | null
        }
        Insert: {
          action: string
          actor_user_id?: string | null
          created_at?: string
          id?: string
          metadata?: Json | null
          request_id?: string | null
          user_id?: string | null
        }
        Update: {
          action?: string
          actor_user_id?: string | null
          created_at?: string
          id?: string
          metadata?: Json | null
          request_id?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "account_recovery_audit_actor_user_id_fkey"
            columns: ["actor_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "account_recovery_audit_request_id_fkey"
            columns: ["request_id"]
            isOneToOne: false
            referencedRelation: "account_recovery_requests"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "account_recovery_audit_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
      account_recovery_requests: {
        Row: {
          created_at: string
          id: string
          ip: string | null
          opened_at: string
          reason: string | null
          rejection_reason: string | null
          requested_identifier: string
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          updated_at: string
          user_agent: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          ip?: string | null
          opened_at?: string
          reason?: string | null
          rejection_reason?: string | null
          requested_identifier: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status: string
          updated_at?: string
          user_agent?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          ip?: string | null
          opened_at?: string
          reason?: string | null
          rejection_reason?: string | null
          requested_identifier?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          updated_at?: string
          user_agent?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "account_recovery_requests_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "account_recovery_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
      account_recovery_sessions: {
        Row: {
          consumed_at: string | null
          created_at: string
          expires_at: string
          id: string
          ip: string | null
          request_id: string
          token_hash: string
          user_agent: string | null
          user_id: string
        }
        Insert: {
          consumed_at?: string | null
          created_at?: string
          expires_at: string
          id?: string
          ip?: string | null
          request_id: string
          token_hash: string
          user_agent?: string | null
          user_id: string
        }
        Update: {
          consumed_at?: string | null
          created_at?: string
          expires_at?: string
          id?: string
          ip?: string | null
          request_id?: string
          token_hash?: string
          user_agent?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "account_recovery_sessions_request_id_fkey"
            columns: ["request_id"]
            isOneToOne: false
            referencedRelation: "account_recovery_requests"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "account_recovery_sessions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
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
      blacklist: {
        Row: {
          bloqueado_em: string | null
          bloqueado_por: string | null
          diarista_id: string
          id: string
          motivo: string
        }
        Insert: {
          bloqueado_em?: string | null
          bloqueado_por?: string | null
          diarista_id: string
          id?: string
          motivo: string
        }
        Update: {
          bloqueado_em?: string | null
          bloqueado_por?: string | null
          diarista_id?: string
          id?: string
          motivo?: string
        }
        Relationships: [
          {
            foreignKeyName: "blacklist_bloqueado_por_fkey"
            columns: ["bloqueado_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_blacklist_diarista"
            columns: ["diarista_id"]
            isOneToOne: false
            referencedRelation: "diaristas"
            referencedColumns: ["id"]
          },
        ]
      }
      candidatos: {
        Row: {
          celular: string | null
          cidade: string | null
          created_at: string
          curriculo_path: string | null
          email: string
          estado: string | null
          experiencia_relevante: string[] | null
          id: string
          nome_completo: string
          telefone: string | null
          updated_at: string
          user_id: string | null
        }
        Insert: {
          celular?: string | null
          cidade?: string | null
          created_at?: string
          curriculo_path?: string | null
          email: string
          estado?: string | null
          experiencia_relevante?: string[] | null
          id?: string
          nome_completo: string
          telefone?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          celular?: string | null
          cidade?: string | null
          created_at?: string
          curriculo_path?: string | null
          email?: string
          estado?: string | null
          experiencia_relevante?: string[] | null
          id?: string
          nome_completo?: string
          telefone?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Relationships: []
      }
      candidatos_anexos: {
        Row: {
          caminho_storage: string
          candidato_id: string
          created_at: string
          id: string
          nome_arquivo: string
          tamanho_bytes: number | null
          tipo_arquivo: string | null
          uploaded_by: string
        }
        Insert: {
          caminho_storage: string
          candidato_id: string
          created_at?: string
          id?: string
          nome_arquivo: string
          tamanho_bytes?: number | null
          tipo_arquivo?: string | null
          uploaded_by: string
        }
        Update: {
          caminho_storage?: string
          candidato_id?: string
          created_at?: string
          id?: string
          nome_arquivo?: string
          tamanho_bytes?: number | null
          tipo_arquivo?: string | null
          uploaded_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "candidatos_anexos_candidato_id_fkey"
            columns: ["candidato_id"]
            isOneToOne: false
            referencedRelation: "candidatos"
            referencedColumns: ["id"]
          },
        ]
      }
      chamado_anexos: {
        Row: {
          caminho_storage: string
          chamado_id: string
          created_at: string
          id: string
          nome_arquivo: string
          tamanho_bytes: number | null
          tipo_arquivo: string | null
          uploaded_by: string
        }
        Insert: {
          caminho_storage: string
          chamado_id: string
          created_at?: string
          id?: string
          nome_arquivo: string
          tamanho_bytes?: number | null
          tipo_arquivo?: string | null
          uploaded_by: string
        }
        Update: {
          caminho_storage?: string
          chamado_id?: string
          created_at?: string
          id?: string
          nome_arquivo?: string
          tamanho_bytes?: number | null
          tipo_arquivo?: string | null
          uploaded_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "chamado_anexos_chamado_id_fkey"
            columns: ["chamado_id"]
            isOneToOne: false
            referencedRelation: "chamados"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chamado_anexos_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
      chamado_categorias: {
        Row: {
          ativo: boolean
          created_at: string
          descricao: string | null
          id: string
          nome: string
          updated_at: string
        }
        Insert: {
          ativo?: boolean
          created_at?: string
          descricao?: string | null
          id?: string
          nome: string
          updated_at?: string
        }
        Update: {
          ativo?: boolean
          created_at?: string
          descricao?: string | null
          id?: string
          nome?: string
          updated_at?: string
        }
        Relationships: []
      }
      chamado_historico: {
        Row: {
          alteracoes: Json | null
          campo_alterado: string | null
          chamado_id: string
          created_at: string
          id: string
          operacao: string
          registro_completo: Json | null
          usuario_id: string | null
          valor_anterior: string | null
          valor_novo: string | null
        }
        Insert: {
          alteracoes?: Json | null
          campo_alterado?: string | null
          chamado_id: string
          created_at?: string
          id?: string
          operacao: string
          registro_completo?: Json | null
          usuario_id?: string | null
          valor_anterior?: string | null
          valor_novo?: string | null
        }
        Update: {
          alteracoes?: Json | null
          campo_alterado?: string | null
          chamado_id?: string
          created_at?: string
          id?: string
          operacao?: string
          registro_completo?: Json | null
          usuario_id?: string | null
          valor_anterior?: string | null
          valor_novo?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "chamado_historico_chamado_id_fkey"
            columns: ["chamado_id"]
            isOneToOne: false
            referencedRelation: "chamados"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chamado_historico_usuario_id_fkey"
            columns: ["usuario_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
      chamado_interacoes: {
        Row: {
          autor_id: string
          chamado_id: string
          created_at: string
          id: string
          interno: boolean
          mensagem: string
          updated_at: string
        }
        Insert: {
          autor_id: string
          chamado_id: string
          created_at?: string
          id?: string
          interno?: boolean
          mensagem: string
          updated_at?: string
        }
        Update: {
          autor_id?: string
          chamado_id?: string
          created_at?: string
          id?: string
          interno?: boolean
          mensagem?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "chamado_interacoes_autor_id_fkey"
            columns: ["autor_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chamado_interacoes_chamado_id_fkey"
            columns: ["chamado_id"]
            isOneToOne: false
            referencedRelation: "chamados"
            referencedColumns: ["id"]
          },
        ]
      }
      chamados: {
        Row: {
          categoria_id: string | null
          created_at: string
          data_fechamento: string | null
          descricao: string
          id: string
          local_id: string
          numero: number
          prioridade: Database["public"]["Enums"]["chamado_prioridade"]
          resolvido_em: string | null
          resolvido_por: string | null
          responsavel_id: string | null
          solicitante_id: string
          status: Database["public"]["Enums"]["chamado_status"]
          titulo: string
          updated_at: string
        }
        Insert: {
          categoria_id?: string | null
          created_at?: string
          data_fechamento?: string | null
          descricao: string
          id?: string
          local_id: string
          numero?: never
          prioridade?: Database["public"]["Enums"]["chamado_prioridade"]
          resolvido_em?: string | null
          resolvido_por?: string | null
          responsavel_id?: string | null
          solicitante_id: string
          status?: Database["public"]["Enums"]["chamado_status"]
          titulo: string
          updated_at?: string
        }
        Update: {
          categoria_id?: string | null
          created_at?: string
          data_fechamento?: string | null
          descricao?: string
          id?: string
          local_id?: string
          numero?: never
          prioridade?: Database["public"]["Enums"]["chamado_prioridade"]
          resolvido_em?: string | null
          resolvido_por?: string | null
          responsavel_id?: string | null
          solicitante_id?: string
          status?: Database["public"]["Enums"]["chamado_status"]
          titulo?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "chamados_categoria_id_fkey"
            columns: ["categoria_id"]
            isOneToOne: false
            referencedRelation: "chamado_categorias"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chamados_local_id_fkey"
            columns: ["local_id"]
            isOneToOne: false
            referencedRelation: "cost_center_locais"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chamados_resolvido_por_fkey"
            columns: ["resolvido_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chamados_responsavel_id_fkey"
            columns: ["responsavel_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chamados_solicitante_id_fkey"
            columns: ["solicitante_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist_avaliacao_itens: {
        Row: {
          checklist_avaliacao_id: string
          checklist_instancia_tarefa_id: string
          created_at: string
          feedback: string | null
          id: string
          nota: number | null
          resultado_conformidade: string
        }
        Insert: {
          checklist_avaliacao_id: string
          checklist_instancia_tarefa_id: string
          created_at?: string
          feedback?: string | null
          id?: string
          nota?: number | null
          resultado_conformidade: string
        }
        Update: {
          checklist_avaliacao_id?: string
          checklist_instancia_tarefa_id?: string
          created_at?: string
          feedback?: string | null
          id?: string
          nota?: number | null
          resultado_conformidade?: string
        }
        Relationships: [
          {
            foreignKeyName: "checklist_avaliacao_itens_checklist_avaliacao_id_fkey"
            columns: ["checklist_avaliacao_id"]
            isOneToOne: false
            referencedRelation: "checklist_avaliacoes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_avaliacao_itens_checklist_instancia_tarefa_id_fkey"
            columns: ["checklist_instancia_tarefa_id"]
            isOneToOne: false
            referencedRelation: "checklist_instancia_tarefas"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist_avaliacoes: {
        Row: {
          avaliado_em: string
          avaliado_por_user_id: string
          checklist_instancia_id: string
          comentario_avaliacao: string | null
          created_at: string
          decisao: Database["public"]["Enums"]["checklist_review_decision"]
          id: string
          plano_acao_necessario: boolean
        }
        Insert: {
          avaliado_em?: string
          avaliado_por_user_id: string
          checklist_instancia_id: string
          comentario_avaliacao?: string | null
          created_at?: string
          decisao: Database["public"]["Enums"]["checklist_review_decision"]
          id?: string
          plano_acao_necessario?: boolean
        }
        Update: {
          avaliado_em?: string
          avaliado_por_user_id?: string
          checklist_instancia_id?: string
          comentario_avaliacao?: string | null
          created_at?: string
          decisao?: Database["public"]["Enums"]["checklist_review_decision"]
          id?: string
          plano_acao_necessario?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "checklist_avaliacoes_avaliado_por_user_id_fkey"
            columns: ["avaliado_por_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_avaliacoes_checklist_instancia_id_fkey"
            columns: ["checklist_instancia_id"]
            isOneToOne: true
            referencedRelation: "checklist_instancias"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist_feedbacks: {
        Row: {
          autor_user_id: string
          checklist_avaliacao_item_id: string | null
          checklist_instancia_tarefa_id: string
          ciente: boolean
          ciente_em: string | null
          created_at: string
          destinatario_user_id: string
          id: string
          mensagem: string
        }
        Insert: {
          autor_user_id: string
          checklist_avaliacao_item_id?: string | null
          checklist_instancia_tarefa_id: string
          ciente?: boolean
          ciente_em?: string | null
          created_at?: string
          destinatario_user_id: string
          id?: string
          mensagem: string
        }
        Update: {
          autor_user_id?: string
          checklist_avaliacao_item_id?: string | null
          checklist_instancia_tarefa_id?: string
          ciente?: boolean
          ciente_em?: string | null
          created_at?: string
          destinatario_user_id?: string
          id?: string
          mensagem?: string
        }
        Relationships: [
          {
            foreignKeyName: "checklist_feedbacks_autor_user_id_fkey"
            columns: ["autor_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_feedbacks_checklist_avaliacao_item_id_fkey"
            columns: ["checklist_avaliacao_item_id"]
            isOneToOne: false
            referencedRelation: "checklist_avaliacao_itens"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_feedbacks_checklist_instancia_tarefa_id_fkey"
            columns: ["checklist_instancia_tarefa_id"]
            isOneToOne: false
            referencedRelation: "checklist_instancia_tarefas"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_feedbacks_destinatario_user_id_fkey"
            columns: ["destinatario_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist_instancia_tarefas: {
        Row: {
          ajuda_snapshot: string | null
          checklist_instancia_id: string
          checklist_template_tarefa_id: string | null
          config_json_snapshot: Json | null
          created_at: string
          descricao_snapshot: string | null
          id: string
          nota_max: number | null
          nota_min: number | null
          obrigatoria: boolean
          ordem: number
          permite_anexo: boolean
          permite_comentario: boolean
          tipo_resposta_snapshot: Database["public"]["Enums"]["checklist_task_response_type"]
          titulo_snapshot: string
        }
        Insert: {
          ajuda_snapshot?: string | null
          checklist_instancia_id: string
          checklist_template_tarefa_id?: string | null
          config_json_snapshot?: Json | null
          created_at?: string
          descricao_snapshot?: string | null
          id?: string
          nota_max?: number | null
          nota_min?: number | null
          obrigatoria: boolean
          ordem: number
          permite_anexo: boolean
          permite_comentario: boolean
          tipo_resposta_snapshot: Database["public"]["Enums"]["checklist_task_response_type"]
          titulo_snapshot: string
        }
        Update: {
          ajuda_snapshot?: string | null
          checklist_instancia_id?: string
          checklist_template_tarefa_id?: string | null
          config_json_snapshot?: Json | null
          created_at?: string
          descricao_snapshot?: string | null
          id?: string
          nota_max?: number | null
          nota_min?: number | null
          obrigatoria?: boolean
          ordem?: number
          permite_anexo?: boolean
          permite_comentario?: boolean
          tipo_resposta_snapshot?: Database["public"]["Enums"]["checklist_task_response_type"]
          titulo_snapshot?: string
        }
        Relationships: [
          {
            foreignKeyName: "checklist_instancia_tarefas_checklist_instancia_id_fkey"
            columns: ["checklist_instancia_id"]
            isOneToOne: false
            referencedRelation: "checklist_instancias"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_instancia_tarefas_checklist_template_tarefa_id_fkey"
            columns: ["checklist_template_tarefa_id"]
            isOneToOne: false
            referencedRelation: "checklist_template_tarefas"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist_instancias: {
        Row: {
          agendado_para: string | null
          checklist_template_id: string
          cost_center_id: string
          created_at: string
          criado_por_user_id: string
          descricao_snapshot: string | null
          exige_plano_acao: boolean
          finalizado_em: string | null
          finalizado_por_user_id: string | null
          id: string
          local_id: string
          observacao_snapshot: string | null
          prazo_em: string | null
          status: Database["public"]["Enums"]["checklist_instance_status"]
          template_versao: number
          titulo_snapshot: string
          updated_at: string
        }
        Insert: {
          agendado_para?: string | null
          checklist_template_id: string
          cost_center_id: string
          created_at?: string
          criado_por_user_id: string
          descricao_snapshot?: string | null
          exige_plano_acao?: boolean
          finalizado_em?: string | null
          finalizado_por_user_id?: string | null
          id?: string
          local_id: string
          observacao_snapshot?: string | null
          prazo_em?: string | null
          status?: Database["public"]["Enums"]["checklist_instance_status"]
          template_versao: number
          titulo_snapshot: string
          updated_at?: string
        }
        Update: {
          agendado_para?: string | null
          checklist_template_id?: string
          cost_center_id?: string
          created_at?: string
          criado_por_user_id?: string
          descricao_snapshot?: string | null
          exige_plano_acao?: boolean
          finalizado_em?: string | null
          finalizado_por_user_id?: string | null
          id?: string
          local_id?: string
          observacao_snapshot?: string | null
          prazo_em?: string | null
          status?: Database["public"]["Enums"]["checklist_instance_status"]
          template_versao?: number
          titulo_snapshot?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "checklist_instancias_checklist_template_id_fkey"
            columns: ["checklist_template_id"]
            isOneToOne: false
            referencedRelation: "checklist_templates"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_instancias_cost_center_id_fkey"
            columns: ["cost_center_id"]
            isOneToOne: false
            referencedRelation: "cost_center"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_instancias_criado_por_user_id_fkey"
            columns: ["criado_por_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_instancias_finalizado_por_user_id_fkey"
            columns: ["finalizado_por_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_instancias_local_id_fkey"
            columns: ["local_id"]
            isOneToOne: false
            referencedRelation: "cost_center_locais"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist_tarefa_responsaveis: {
        Row: {
          assigned_by_user_id: string
          assigned_user_id: string
          ativo: boolean
          atribuida_em: string
          checklist_instancia_tarefa_id: string
          concluida_em: string | null
          id: string
          pode_alterar_status: boolean
          status_kanban: Database["public"]["Enums"]["checklist_task_kanban_status"]
        }
        Insert: {
          assigned_by_user_id: string
          assigned_user_id: string
          ativo?: boolean
          atribuida_em?: string
          checklist_instancia_tarefa_id: string
          concluida_em?: string | null
          id?: string
          pode_alterar_status?: boolean
          status_kanban?: Database["public"]["Enums"]["checklist_task_kanban_status"]
        }
        Update: {
          assigned_by_user_id?: string
          assigned_user_id?: string
          ativo?: boolean
          atribuida_em?: string
          checklist_instancia_tarefa_id?: string
          concluida_em?: string | null
          id?: string
          pode_alterar_status?: boolean
          status_kanban?: Database["public"]["Enums"]["checklist_task_kanban_status"]
        }
        Relationships: [
          {
            foreignKeyName: "checklist_tarefa_responsaveis_assigned_by_user_id_fkey"
            columns: ["assigned_by_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_tarefa_responsaveis_assigned_user_id_fkey"
            columns: ["assigned_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_tarefa_responsaveis_checklist_instancia_tarefa_i_fkey"
            columns: ["checklist_instancia_tarefa_id"]
            isOneToOne: false
            referencedRelation: "checklist_instancia_tarefas"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist_tarefa_respostas: {
        Row: {
          checklist_instancia_tarefa_id: string
          comentario_resposta: string | null
          created_at: string
          id: string
          respondido_por_user_id: string
          resposta_boolean: boolean | null
          resposta_data: string | null
          resposta_datetime: string | null
          resposta_json: Json | null
          resposta_numero: number | null
          resposta_texto: string | null
          tarefa_responsavel_id: string
          updated_at: string
        }
        Insert: {
          checklist_instancia_tarefa_id: string
          comentario_resposta?: string | null
          created_at?: string
          id?: string
          respondido_por_user_id: string
          resposta_boolean?: boolean | null
          resposta_data?: string | null
          resposta_datetime?: string | null
          resposta_json?: Json | null
          resposta_numero?: number | null
          resposta_texto?: string | null
          tarefa_responsavel_id: string
          updated_at?: string
        }
        Update: {
          checklist_instancia_tarefa_id?: string
          comentario_resposta?: string | null
          created_at?: string
          id?: string
          respondido_por_user_id?: string
          resposta_boolean?: boolean | null
          resposta_data?: string | null
          resposta_datetime?: string | null
          resposta_json?: Json | null
          resposta_numero?: number | null
          resposta_texto?: string | null
          tarefa_responsavel_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "checklist_tarefa_respostas_checklist_instancia_tarefa_id_fkey"
            columns: ["checklist_instancia_tarefa_id"]
            isOneToOne: false
            referencedRelation: "checklist_instancia_tarefas"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_tarefa_respostas_respondido_por_user_id_fkey"
            columns: ["respondido_por_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_tarefa_respostas_tarefa_responsavel_id_fkey"
            columns: ["tarefa_responsavel_id"]
            isOneToOne: false
            referencedRelation: "checklist_tarefa_responsaveis"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist_tarefa_status_historico: {
        Row: {
          assigned_user_id: string
          changed_by_user_id: string
          checklist_instancia_tarefa_id: string
          created_at: string
          id: string
          motivo: string | null
          status_anterior:
            | Database["public"]["Enums"]["checklist_task_kanban_status"]
            | null
          status_novo: Database["public"]["Enums"]["checklist_task_kanban_status"]
        }
        Insert: {
          assigned_user_id: string
          changed_by_user_id: string
          checklist_instancia_tarefa_id: string
          created_at?: string
          id?: string
          motivo?: string | null
          status_anterior?:
            | Database["public"]["Enums"]["checklist_task_kanban_status"]
            | null
          status_novo: Database["public"]["Enums"]["checklist_task_kanban_status"]
        }
        Update: {
          assigned_user_id?: string
          changed_by_user_id?: string
          checklist_instancia_tarefa_id?: string
          created_at?: string
          id?: string
          motivo?: string | null
          status_anterior?:
            | Database["public"]["Enums"]["checklist_task_kanban_status"]
            | null
          status_novo?: Database["public"]["Enums"]["checklist_task_kanban_status"]
        }
        Relationships: [
          {
            foreignKeyName: "checklist_tarefa_status_histo_checklist_instancia_tarefa_i_fkey"
            columns: ["checklist_instancia_tarefa_id"]
            isOneToOne: false
            referencedRelation: "checklist_instancia_tarefas"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_tarefa_status_historico_assigned_user_id_fkey"
            columns: ["assigned_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_tarefa_status_historico_changed_by_user_id_fkey"
            columns: ["changed_by_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist_template_tarefas: {
        Row: {
          ajuda: string | null
          checklist_template_id: string
          config_json: Json | null
          created_at: string
          descricao: string | null
          id: string
          nota_max: number | null
          nota_min: number | null
          obrigatoria: boolean
          ordem: number
          permite_anexo: boolean
          permite_comentario: boolean
          tipo_resposta: Database["public"]["Enums"]["checklist_task_response_type"]
          titulo: string
          updated_at: string
        }
        Insert: {
          ajuda?: string | null
          checklist_template_id: string
          config_json?: Json | null
          created_at?: string
          descricao?: string | null
          id?: string
          nota_max?: number | null
          nota_min?: number | null
          obrigatoria?: boolean
          ordem: number
          permite_anexo?: boolean
          permite_comentario?: boolean
          tipo_resposta: Database["public"]["Enums"]["checklist_task_response_type"]
          titulo: string
          updated_at?: string
        }
        Update: {
          ajuda?: string | null
          checklist_template_id?: string
          config_json?: Json | null
          created_at?: string
          descricao?: string | null
          id?: string
          nota_max?: number | null
          nota_min?: number | null
          obrigatoria?: boolean
          ordem?: number
          permite_anexo?: boolean
          permite_comentario?: boolean
          tipo_resposta?: Database["public"]["Enums"]["checklist_task_response_type"]
          titulo?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "checklist_template_tarefas_checklist_template_id_fkey"
            columns: ["checklist_template_id"]
            isOneToOne: false
            referencedRelation: "checklist_templates"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist_templates: {
        Row: {
          ativo: boolean
          cost_center_id: string
          created_at: string
          criado_por_user_id: string
          descricao: string | null
          encerra_em: string | null
          equipe_responsavel_id: string
          exige_plano_acao: boolean
          id: string
          inicia_em: string | null
          local_id: string
          observacao: string | null
          prazo_padrao_horas: number | null
          proxima_geracao_em: string | null
          recorrencia: Database["public"]["Enums"]["module_recurrence_type"]
          recorrencia_intervalo: number
          status: Database["public"]["Enums"]["checklist_template_status"]
          titulo: string
          updated_at: string
          versao: number
        }
        Insert: {
          ativo?: boolean
          cost_center_id: string
          created_at?: string
          criado_por_user_id: string
          descricao?: string | null
          encerra_em?: string | null
          equipe_responsavel_id: string
          exige_plano_acao?: boolean
          id?: string
          inicia_em?: string | null
          local_id: string
          observacao?: string | null
          prazo_padrao_horas?: number | null
          proxima_geracao_em?: string | null
          recorrencia?: Database["public"]["Enums"]["module_recurrence_type"]
          recorrencia_intervalo?: number
          status?: Database["public"]["Enums"]["checklist_template_status"]
          titulo: string
          updated_at?: string
          versao?: number
        }
        Update: {
          ativo?: boolean
          cost_center_id?: string
          created_at?: string
          criado_por_user_id?: string
          descricao?: string | null
          encerra_em?: string | null
          equipe_responsavel_id?: string
          exige_plano_acao?: boolean
          id?: string
          inicia_em?: string | null
          local_id?: string
          observacao?: string | null
          prazo_padrao_horas?: number | null
          proxima_geracao_em?: string | null
          recorrencia?: Database["public"]["Enums"]["module_recurrence_type"]
          recorrencia_intervalo?: number
          status?: Database["public"]["Enums"]["checklist_template_status"]
          titulo?: string
          updated_at?: string
          versao?: number
        }
        Relationships: [
          {
            foreignKeyName: "checklist_templates_cost_center_id_fkey"
            columns: ["cost_center_id"]
            isOneToOne: false
            referencedRelation: "cost_center"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_templates_criado_por_user_id_fkey"
            columns: ["criado_por_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_templates_equipe_responsavel_id_fkey"
            columns: ["equipe_responsavel_id"]
            isOneToOne: false
            referencedRelation: "module_equipes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_templates_local_id_fkey"
            columns: ["local_id"]
            isOneToOne: false
            referencedRelation: "cost_center_locais"
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
          convenia_cost_center_id: string | null
          created_at: string
          id: number
          itens_adicionais: string | null
          nome_fantasia: string
          razao_social: string
          updated_at: string
        }
        Insert: {
          cnpj: string
          contato_email?: string | null
          contato_nome?: string | null
          contato_telefone?: string | null
          convenia_cost_center_id?: string | null
          created_at?: string
          id?: number
          itens_adicionais?: string | null
          nome_fantasia?: string
          razao_social: string
          updated_at?: string
        }
        Update: {
          cnpj?: string
          contato_email?: string | null
          contato_nome?: string | null
          contato_telefone?: string | null
          convenia_cost_center_id?: string | null
          created_at?: string
          id?: number
          itens_adicionais?: string | null
          nome_fantasia?: string
          razao_social?: string
          updated_at?: string
        }
        Relationships: []
      }
      colaborador_faltas: {
        Row: {
          colaborador_id: string
          created_at: string
          diaria_temporaria_id: number
          documento_url: string | null
          id: number
          justificada_em: string | null
          justificada_por: string | null
          motivo: Database["public"]["Enums"]["motivo_vago_type"]
          updated_at: string
        }
        Insert: {
          colaborador_id: string
          created_at?: string
          diaria_temporaria_id: number
          documento_url?: string | null
          id?: number
          justificada_em?: string | null
          justificada_por?: string | null
          motivo: Database["public"]["Enums"]["motivo_vago_type"]
          updated_at?: string
        }
        Update: {
          colaborador_id?: string
          created_at?: string
          diaria_temporaria_id?: number
          documento_url?: string | null
          id?: number
          justificada_em?: string | null
          justificada_por?: string | null
          motivo?: Database["public"]["Enums"]["motivo_vago_type"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "colaborador_faltas_colaborador_id_fkey"
            columns: ["colaborador_id"]
            isOneToOne: false
            referencedRelation: "colaboradores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "colaborador_faltas_diaria_temporaria_id_fkey"
            columns: ["diaria_temporaria_id"]
            isOneToOne: true
            referencedRelation: "diarias_temporarias"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "colaborador_faltas_justificada_por_fkey"
            columns: ["justificada_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
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
      colaborador_profiles: {
        Row: {
          ativo: boolean
          cost_center_id: string
          created_at: string
          created_by: string
          observacoes: string | null
          updated_at: string
          updated_by: string | null
          user_id: string
        }
        Insert: {
          ativo?: boolean
          cost_center_id: string
          created_at?: string
          created_by: string
          observacoes?: string | null
          updated_at?: string
          updated_by?: string | null
          user_id: string
        }
        Update: {
          ativo?: boolean
          cost_center_id?: string
          created_at?: string
          created_by?: string
          observacoes?: string | null
          updated_at?: string
          updated_by?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "colaborador_profiles_cost_center_id_fkey"
            columns: ["cost_center_id"]
            isOneToOne: false
            referencedRelation: "cost_center"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "colaborador_profiles_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "colaborador_profiles_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "colaborador_profiles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
      colaboradores: {
        Row: {
          cargo: string | null
          cliente_id: number | null
          cpf: string | null
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
          user_id: string | null
        }
        Insert: {
          cargo?: string | null
          cliente_id?: number | null
          cpf?: string | null
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
          user_id?: string | null
        }
        Update: {
          cargo?: string | null
          cliente_id?: number | null
          cpf?: string | null
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
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "colaboradores_cliente_id_fkey"
            columns: ["cliente_id"]
            isOneToOne: false
            referencedRelation: "clientes"
            referencedColumns: ["id"]
          },
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
      colaboradores_convenia: {
        Row: {
          address_city: string | null
          address_complement: string | null
          address_district: string | null
          address_number: string | null
          address_state: string | null
          address_street: string | null
          address_zip_code: string | null
          annotations: Json | null
          aso: Json | null
          bank_accounts: Json | null
          birth_date: string | null
          convenia_id: string
          cost_center: Json | null
          cost_center_id: string | null
          cost_center_name: string | null
          cpf: string | null
          created_at: string
          ctps_emission_date: string | null
          ctps_number: string | null
          ctps_serial_number: string | null
          department_id: string | null
          department_name: string | null
          disability: Json | null
          driver_license_category: string | null
          driver_license_emission_date: string | null
          driver_license_number: string | null
          driver_license_validate_date: string | null
          educations: Json | null
          electoral_card: Json | null
          email: string | null
          emergency_contacts: Json | null
          experience_period: Json | null
          foreign_data: Json | null
          hiring_date: string | null
          id: string
          intern_data: Json | null
          job_id: string | null
          job_name: string | null
          last_name: string | null
          name: string | null
          nationalities: Json | null
          payroll: Json | null
          personal_email: string | null
          personal_phone: string | null
          pis: string | null
          raw_data: Json | null
          registration: string | null
          reservist: Json | null
          residential_phone: string | null
          rg_emission_date: string | null
          rg_issuing_agency: string | null
          rg_number: string | null
          salary: number | null
          social_name: string | null
          status: string | null
          supervisor_id: string | null
          supervisor_last_name: string | null
          supervisor_name: string | null
          synced_at: string | null
          team_id: string | null
          team_name: string | null
          updated_at: string
        }
        Insert: {
          address_city?: string | null
          address_complement?: string | null
          address_district?: string | null
          address_number?: string | null
          address_state?: string | null
          address_street?: string | null
          address_zip_code?: string | null
          annotations?: Json | null
          aso?: Json | null
          bank_accounts?: Json | null
          birth_date?: string | null
          convenia_id: string
          cost_center?: Json | null
          cost_center_id?: string | null
          cost_center_name?: string | null
          cpf?: string | null
          created_at?: string
          ctps_emission_date?: string | null
          ctps_number?: string | null
          ctps_serial_number?: string | null
          department_id?: string | null
          department_name?: string | null
          disability?: Json | null
          driver_license_category?: string | null
          driver_license_emission_date?: string | null
          driver_license_number?: string | null
          driver_license_validate_date?: string | null
          educations?: Json | null
          electoral_card?: Json | null
          email?: string | null
          emergency_contacts?: Json | null
          experience_period?: Json | null
          foreign_data?: Json | null
          hiring_date?: string | null
          id?: string
          intern_data?: Json | null
          job_id?: string | null
          job_name?: string | null
          last_name?: string | null
          name?: string | null
          nationalities?: Json | null
          payroll?: Json | null
          personal_email?: string | null
          personal_phone?: string | null
          pis?: string | null
          raw_data?: Json | null
          registration?: string | null
          reservist?: Json | null
          residential_phone?: string | null
          rg_emission_date?: string | null
          rg_issuing_agency?: string | null
          rg_number?: string | null
          salary?: number | null
          social_name?: string | null
          status?: string | null
          supervisor_id?: string | null
          supervisor_last_name?: string | null
          supervisor_name?: string | null
          synced_at?: string | null
          team_id?: string | null
          team_name?: string | null
          updated_at?: string
        }
        Update: {
          address_city?: string | null
          address_complement?: string | null
          address_district?: string | null
          address_number?: string | null
          address_state?: string | null
          address_street?: string | null
          address_zip_code?: string | null
          annotations?: Json | null
          aso?: Json | null
          bank_accounts?: Json | null
          birth_date?: string | null
          convenia_id?: string
          cost_center?: Json | null
          cost_center_id?: string | null
          cost_center_name?: string | null
          cpf?: string | null
          created_at?: string
          ctps_emission_date?: string | null
          ctps_number?: string | null
          ctps_serial_number?: string | null
          department_id?: string | null
          department_name?: string | null
          disability?: Json | null
          driver_license_category?: string | null
          driver_license_emission_date?: string | null
          driver_license_number?: string | null
          driver_license_validate_date?: string | null
          educations?: Json | null
          electoral_card?: Json | null
          email?: string | null
          emergency_contacts?: Json | null
          experience_period?: Json | null
          foreign_data?: Json | null
          hiring_date?: string | null
          id?: string
          intern_data?: Json | null
          job_id?: string | null
          job_name?: string | null
          last_name?: string | null
          name?: string | null
          nationalities?: Json | null
          payroll?: Json | null
          personal_email?: string | null
          personal_phone?: string | null
          pis?: string | null
          raw_data?: Json | null
          registration?: string | null
          reservist?: Json | null
          residential_phone?: string | null
          rg_emission_date?: string | null
          rg_issuing_agency?: string | null
          rg_number?: string | null
          salary?: number | null
          social_name?: string | null
          status?: string | null
          supervisor_id?: string | null
          supervisor_last_name?: string | null
          supervisor_name?: string | null
          synced_at?: string | null
          team_id?: string | null
          team_name?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "colaboradores_convenia_cost_center_fk"
            columns: ["cost_center_id"]
            isOneToOne: false
            referencedRelation: "cost_center"
            referencedColumns: ["id"]
          },
        ]
      }
      colaboradores_demitidos_convenia: {
        Row: {
          accountancy_date: string | null
          breaking_contract: string | null
          comments: string | null
          convenia_employee_id: string
          corporate_email: string | null
          created_at: string
          dismissal_date: string | null
          dismissal_id: string | null
          dismissal_step_id: number | null
          dismissal_step_name: string | null
          dismissal_type_id: number | null
          dismissal_type_title: string | null
          finished_at: string | null
          id: string
          motive: string | null
          new_supervisor_id: string | null
          raw_data: Json | null
          remove_access_date: string | null
          remove_benefit: boolean | null
          supervisor_id: string | null
          supervisor_name: string | null
          synced_at: string | null
          termination_notice_date: string | null
          termination_notice_id: string | null
          termination_notice_type_id: number | null
          termination_notice_type_name: string | null
          updated_at: string
        }
        Insert: {
          accountancy_date?: string | null
          breaking_contract?: string | null
          comments?: string | null
          convenia_employee_id: string
          corporate_email?: string | null
          created_at?: string
          dismissal_date?: string | null
          dismissal_id?: string | null
          dismissal_step_id?: number | null
          dismissal_step_name?: string | null
          dismissal_type_id?: number | null
          dismissal_type_title?: string | null
          finished_at?: string | null
          id?: string
          motive?: string | null
          new_supervisor_id?: string | null
          raw_data?: Json | null
          remove_access_date?: string | null
          remove_benefit?: boolean | null
          supervisor_id?: string | null
          supervisor_name?: string | null
          synced_at?: string | null
          termination_notice_date?: string | null
          termination_notice_id?: string | null
          termination_notice_type_id?: number | null
          termination_notice_type_name?: string | null
          updated_at?: string
        }
        Update: {
          accountancy_date?: string | null
          breaking_contract?: string | null
          comments?: string | null
          convenia_employee_id?: string
          corporate_email?: string | null
          created_at?: string
          dismissal_date?: string | null
          dismissal_id?: string | null
          dismissal_step_id?: number | null
          dismissal_step_name?: string | null
          dismissal_type_id?: number | null
          dismissal_type_title?: string | null
          finished_at?: string | null
          id?: string
          motive?: string | null
          new_supervisor_id?: string | null
          raw_data?: Json | null
          remove_access_date?: string | null
          remove_benefit?: boolean | null
          supervisor_id?: string | null
          supervisor_name?: string | null
          synced_at?: string | null
          termination_notice_date?: string | null
          termination_notice_id?: string | null
          termination_notice_type_id?: number | null
          termination_notice_type_name?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      contratos: {
        Row: {
          cliente_id: number
          conq_perd: number
          created_at: string | null
          data_fim: string | null
          data_inicio: string
          id: string
          negocio: string
          updated_at: string | null
        }
        Insert: {
          cliente_id: number
          conq_perd: number
          created_at?: string | null
          data_fim?: string | null
          data_inicio: string
          id?: string
          negocio: string
          updated_at?: string | null
        }
        Update: {
          cliente_id?: number
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
      cost_center: {
        Row: {
          convenia_id: string
          created_at: string
          id: string
          name: string
          updated_at: string
        }
        Insert: {
          convenia_id: string
          created_at?: string
          id?: string
          name: string
          updated_at?: string
        }
        Update: {
          convenia_id?: string
          created_at?: string
          id?: string
          name?: string
          updated_at?: string
        }
        Relationships: []
      }
      cost_center_locais: {
        Row: {
          ativo: boolean
          cost_center_id: string
          created_at: string
          descricao: string | null
          id: string
          nome: string
          updated_at: string
        }
        Insert: {
          ativo?: boolean
          cost_center_id: string
          created_at?: string
          descricao?: string | null
          id?: string
          nome: string
          updated_at?: string
        }
        Update: {
          ativo?: boolean
          cost_center_id?: string
          created_at?: string
          descricao?: string | null
          id?: string
          nome?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "cost_center_locais_cost_center_id_fkey"
            columns: ["cost_center_id"]
            isOneToOne: false
            referencedRelation: "cost_center"
            referencedColumns: ["id"]
          },
        ]
      }
      cost_centers_convenia: {
        Row: {
          cliente_id: number | null
          convenia_cost_center_id: string
          convenia_cost_center_name: string
          created_at: string | null
          id: string
          updated_at: string | null
        }
        Insert: {
          cliente_id?: number | null
          convenia_cost_center_id: string
          convenia_cost_center_name: string
          created_at?: string | null
          id?: string
          updated_at?: string | null
        }
        Update: {
          cliente_id?: number | null
          convenia_cost_center_id?: string
          convenia_cost_center_name?: string
          created_at?: string | null
          id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "cost_centers_convenia_cliente_id_fkey"
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
      diarias_notificacoes: {
        Row: {
          campo: string
          created_at: string
          diaria_id: number
          evento: string
          id: string
          lida: boolean
          mensagem: string
          titulo: string
          updated_at: string
          user_id: string
          valor_antigo: string | null
          valor_novo: string | null
        }
        Insert: {
          campo: string
          created_at?: string
          diaria_id: number
          evento: string
          id?: string
          lida?: boolean
          mensagem: string
          titulo: string
          updated_at?: string
          user_id: string
          valor_antigo?: string | null
          valor_novo?: string | null
        }
        Update: {
          campo?: string
          created_at?: string
          diaria_id?: number
          evento?: string
          id?: string
          lida?: boolean
          mensagem?: string
          titulo?: string
          updated_at?: string
          user_id?: string
          valor_antigo?: string | null
          valor_novo?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "diarias_notificacoes_diaria_id_fkey"
            columns: ["diaria_id"]
            isOneToOne: false
            referencedRelation: "diarias_temporarias"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "diarias_notificacoes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
      diarias_temporarias: {
        Row: {
          aprovada_em: string | null
          aprovada_para_pagamento_em: string | null
          aprovada_por: string | null
          aprovado_para_pgto_por: string | null
          cancelada_em: string | null
          cancelada_por: string | null
          centro_custo_id: string | null
          cliente_id: number
          colaborador_ausente: string | null
          colaborador_ausente_convenia: string | null
          colaborador_ausente_nome: string | null
          colaborador_demitido: string | null
          colaborador_demitido_convenia: string | null
          colaborador_demitido_nome: string | null
          confirmada_em: string | null
          confirmada_por: string | null
          created_at: string
          criado_por: string | null
          data_diaria: string
          demissao: boolean | null
          diarista_id: string
          horario_fim: string | null
          horario_inicio: string | null
          id: number
          intervalo: number | null
          jornada_diaria: number | null
          lancada_em: string | null
          lancada_por: string | null
          motivo_cancelamento: string | null
          motivo_reprovacao:
            | Database["public"]["Enums"]["motivo_reprovacao"]
            | null
          motivo_reprovacao_observacao: string | null
          motivo_vago: Database["public"]["Enums"]["motivo_vago_type"]
          novo_posto: boolean | null
          observacao: string | null
          observacao_lancamento: string | null
          observacao_pagamento:
            | Database["public"]["Enums"]["observacao_pagamento_type"][]
            | null
          ok_pagamento: boolean | null
          ok_pagamento_em: string | null
          ok_pagamento_por: string | null
          outros_motivos_reprovacao_pagamento: string | null
          paga_em: string | null
          paga_por: string | null
          posto_servico: string | null
          posto_servico_id: string | null
          reprovada_em: string | null
          reprovada_por: string | null
          status: Database["public"]["Enums"]["status_diaria"]
          unidade: string
          updated_at: string
          valor_diaria: number
        }
        Insert: {
          aprovada_em?: string | null
          aprovada_para_pagamento_em?: string | null
          aprovada_por?: string | null
          aprovado_para_pgto_por?: string | null
          cancelada_em?: string | null
          cancelada_por?: string | null
          centro_custo_id?: string | null
          cliente_id: number
          colaborador_ausente?: string | null
          colaborador_ausente_convenia?: string | null
          colaborador_ausente_nome?: string | null
          colaborador_demitido?: string | null
          colaborador_demitido_convenia?: string | null
          colaborador_demitido_nome?: string | null
          confirmada_em?: string | null
          confirmada_por?: string | null
          created_at?: string
          criado_por?: string | null
          data_diaria: string
          demissao?: boolean | null
          diarista_id: string
          horario_fim?: string | null
          horario_inicio?: string | null
          id?: number
          intervalo?: number | null
          jornada_diaria?: number | null
          lancada_em?: string | null
          lancada_por?: string | null
          motivo_cancelamento?: string | null
          motivo_reprovacao?:
            | Database["public"]["Enums"]["motivo_reprovacao"]
            | null
          motivo_reprovacao_observacao?: string | null
          motivo_vago?: Database["public"]["Enums"]["motivo_vago_type"]
          novo_posto?: boolean | null
          observacao?: string | null
          observacao_lancamento?: string | null
          observacao_pagamento?:
            | Database["public"]["Enums"]["observacao_pagamento_type"][]
            | null
          ok_pagamento?: boolean | null
          ok_pagamento_em?: string | null
          ok_pagamento_por?: string | null
          outros_motivos_reprovacao_pagamento?: string | null
          paga_em?: string | null
          paga_por?: string | null
          posto_servico?: string | null
          posto_servico_id?: string | null
          reprovada_em?: string | null
          reprovada_por?: string | null
          status?: Database["public"]["Enums"]["status_diaria"]
          unidade: string
          updated_at?: string
          valor_diaria: number
        }
        Update: {
          aprovada_em?: string | null
          aprovada_para_pagamento_em?: string | null
          aprovada_por?: string | null
          aprovado_para_pgto_por?: string | null
          cancelada_em?: string | null
          cancelada_por?: string | null
          centro_custo_id?: string | null
          cliente_id?: number
          colaborador_ausente?: string | null
          colaborador_ausente_convenia?: string | null
          colaborador_ausente_nome?: string | null
          colaborador_demitido?: string | null
          colaborador_demitido_convenia?: string | null
          colaborador_demitido_nome?: string | null
          confirmada_em?: string | null
          confirmada_por?: string | null
          created_at?: string
          criado_por?: string | null
          data_diaria?: string
          demissao?: boolean | null
          diarista_id?: string
          horario_fim?: string | null
          horario_inicio?: string | null
          id?: number
          intervalo?: number | null
          jornada_diaria?: number | null
          lancada_em?: string | null
          lancada_por?: string | null
          motivo_cancelamento?: string | null
          motivo_reprovacao?:
            | Database["public"]["Enums"]["motivo_reprovacao"]
            | null
          motivo_reprovacao_observacao?: string | null
          motivo_vago?: Database["public"]["Enums"]["motivo_vago_type"]
          novo_posto?: boolean | null
          observacao?: string | null
          observacao_lancamento?: string | null
          observacao_pagamento?:
            | Database["public"]["Enums"]["observacao_pagamento_type"][]
            | null
          ok_pagamento?: boolean | null
          ok_pagamento_em?: string | null
          ok_pagamento_por?: string | null
          outros_motivos_reprovacao_pagamento?: string | null
          paga_em?: string | null
          paga_por?: string | null
          posto_servico?: string | null
          posto_servico_id?: string | null
          reprovada_em?: string | null
          reprovada_por?: string | null
          status?: Database["public"]["Enums"]["status_diaria"]
          unidade?: string
          updated_at?: string
          valor_diaria?: number
        }
        Relationships: [
          {
            foreignKeyName: "diarias_temporarias_aprovada_por_fkey"
            columns: ["aprovada_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "diarias_temporarias_aprovado_para_pgto_por_fkey"
            columns: ["aprovado_para_pgto_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "diarias_temporarias_cancelada_por_fkey"
            columns: ["cancelada_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "diarias_temporarias_cliente_id_fkey"
            columns: ["cliente_id"]
            isOneToOne: false
            referencedRelation: "clientes"
            referencedColumns: ["id"]
          },
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
            foreignKeyName: "diarias_temporarias_confirmada_por_fkey"
            columns: ["confirmada_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "diarias_temporarias_criado_por_fkey"
            columns: ["criado_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
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
            foreignKeyName: "diarias_temporarias_lancada_por_fkey"
            columns: ["lancada_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "diarias_temporarias_ok_pagamento_por_fkey"
            columns: ["ok_pagamento_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "diarias_temporarias_paga_por_fkey"
            columns: ["paga_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "diarias_temporarias_posto_servico_id_fkey"
            columns: ["posto_servico_id"]
            isOneToOne: false
            referencedRelation: "postos_servico"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "diarias_temporarias_reprovada_por_fkey"
            columns: ["reprovada_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_centro_custo"
            columns: ["centro_custo_id"]
            isOneToOne: false
            referencedRelation: "cost_center"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_colab_ausente_convenia"
            columns: ["colaborador_ausente_convenia"]
            isOneToOne: false
            referencedRelation: "colaboradores_convenia"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_colab_demitido_convenia"
            columns: ["colaborador_demitido_convenia"]
            isOneToOne: false
            referencedRelation: "colaboradores_convenia"
            referencedColumns: ["id"]
          },
        ]
      }
      diarias_temporarias_logs: {
        Row: {
          campo: string
          criado_em: string | null
          diaria_id: number
          id: string
          operacao: string
          operacao_em: string | null
          usuario_responsavel: string | null
          valor_antigo: string | null
          valor_novo: string | null
        }
        Insert: {
          campo: string
          criado_em?: string | null
          diaria_id: number
          id?: string
          operacao: string
          operacao_em?: string | null
          usuario_responsavel?: string | null
          valor_antigo?: string | null
          valor_novo?: string | null
        }
        Update: {
          campo?: string
          criado_em?: string | null
          diaria_id?: number
          id?: string
          operacao?: string
          operacao_em?: string | null
          usuario_responsavel?: string | null
          valor_antigo?: string | null
          valor_novo?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "diarias_temporarias_logs_diaria_id_fkey"
            columns: ["diaria_id"]
            isOneToOne: false
            referencedRelation: "diarias_temporarias"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "diarias_temporarias_logs_usuario_responsavel_fkey"
            columns: ["usuario_responsavel"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
      diarias_temporarias_logs_completos: {
        Row: {
          alteracoes: Json | null
          data_operacao: string
          diaria_id: number
          id: number
          operacao: string
          registro_completo: Json | null
          usuario: string | null
        }
        Insert: {
          alteracoes?: Json | null
          data_operacao?: string
          diaria_id: number
          id?: number
          operacao: string
          registro_completo?: Json | null
          usuario?: string | null
        }
        Update: {
          alteracoes?: Json | null
          data_operacao?: string
          diaria_id?: number
          id?: number
          operacao?: string
          registro_completo?: Json | null
          usuario?: string | null
        }
        Relationships: []
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
          motivo_alteracao: string | null
          motivo_restricao: string | null
          nome_completo: string
          numero_conta: string | null
          observacoes: string | null
          pix: string | null
          pix_pertence_beneficiario: boolean | null
          possui_antecedente: boolean | null
          reserva_tecnica: boolean | null
          status: Database["public"]["Enums"]["status_diarista"] | null
          telefone: string | null
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
          motivo_alteracao?: string | null
          motivo_restricao?: string | null
          nome_completo: string
          numero_conta?: string | null
          observacoes?: string | null
          pix?: string | null
          pix_pertence_beneficiario?: boolean | null
          possui_antecedente?: boolean | null
          reserva_tecnica?: boolean | null
          status?: Database["public"]["Enums"]["status_diarista"] | null
          telefone?: string | null
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
          motivo_alteracao?: string | null
          motivo_restricao?: string | null
          nome_completo?: string
          numero_conta?: string | null
          observacoes?: string | null
          pix?: string | null
          pix_pertence_beneficiario?: boolean | null
          possui_antecedente?: boolean | null
          reserva_tecnica?: boolean | null
          status?: Database["public"]["Enums"]["status_diarista"] | null
          telefone?: string | null
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
      diaristas_historico: {
        Row: {
          alterado_em: string | null
          campo_alterado: string
          diarista_id: string
          id: string
          motivo: string
          valor_anterior: string | null
          valor_novo: string | null
        }
        Insert: {
          alterado_em?: string | null
          campo_alterado: string
          diarista_id: string
          id?: string
          motivo: string
          valor_anterior?: string | null
          valor_novo?: string | null
        }
        Update: {
          alterado_em?: string | null
          campo_alterado?: string
          diarista_id?: string
          id?: string
          motivo?: string
          valor_anterior?: string | null
          valor_novo?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "diaristas_historico_diarista_id_fkey"
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
      faltas_colaboradores_convenia: {
        Row: {
          atestado_path: string | null
          colaborador_convenia_id: string
          created_at: string
          data_falta: string
          diaria_temporaria_id: number | null
          id: number
          justificada_em: string | null
          justificada_por: string | null
          local_falta: string | null
          motivo: string
          updated_at: string
        }
        Insert: {
          atestado_path?: string | null
          colaborador_convenia_id: string
          created_at?: string
          data_falta: string
          diaria_temporaria_id?: number | null
          id?: number
          justificada_em?: string | null
          justificada_por?: string | null
          local_falta?: string | null
          motivo: string
          updated_at?: string
        }
        Update: {
          atestado_path?: string | null
          colaborador_convenia_id?: string
          created_at?: string
          data_falta?: string
          diaria_temporaria_id?: number | null
          id?: number
          justificada_em?: string | null
          justificada_por?: string | null
          local_falta?: string | null
          motivo?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "faltas_colaboradores_convenia_colaborador_convenia_id_fkey"
            columns: ["colaborador_convenia_id"]
            isOneToOne: false
            referencedRelation: "colaboradores_convenia"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "faltas_colaboradores_convenia_diaria_temporaria_id_fkey"
            columns: ["diaria_temporaria_id"]
            isOneToOne: false
            referencedRelation: "diarias_temporarias"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "faltas_colaboradores_convenia_justificada_por_fkey"
            columns: ["justificada_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "faltas_colaboradores_convenia_local_falta_fkey"
            columns: ["local_falta"]
            isOneToOne: false
            referencedRelation: "cost_center"
            referencedColumns: ["id"]
          },
        ]
      }
      horas_extras: {
        Row: {
          aprovado_em: string | null
          aprovado_por: string | null
          cancelado_em: string | null
          cancelado_por: string | null
          colaborador_cobrindo_id: string
          confirmado_em: string | null
          confirmado_por: string | null
          criado_em: string
          criado_por: string
          data_hora_extra: string
          detalhe_cancelamento: string | null
          detalhe_reprovacao: string | null
          falta_id: number | null
          fim_em: string
          id: string
          inicio_em: string
          intervalo_fim_em: string | null
          intervalo_inicio_em: string | null
          local_hora_extra: string
          motivo_cancelamento:
            | Database["public"]["Enums"]["motivo_cancelamento_hora_extra"]
            | null
          motivo_reprovacao:
            | Database["public"]["Enums"]["motivo_reprovacao_hora_extra"]
            | null
          observacao: string | null
          operacao: Database["public"]["Enums"]["operacao_hora_extra"]
          reprovado_em: string | null
          reprovado_por: string | null
          status: Database["public"]["Enums"]["status_hora_extra"]
          updated_at: string
        }
        Insert: {
          aprovado_em?: string | null
          aprovado_por?: string | null
          cancelado_em?: string | null
          cancelado_por?: string | null
          colaborador_cobrindo_id: string
          confirmado_em?: string | null
          confirmado_por?: string | null
          criado_em?: string
          criado_por: string
          data_hora_extra: string
          detalhe_cancelamento?: string | null
          detalhe_reprovacao?: string | null
          falta_id?: number | null
          fim_em: string
          id?: string
          inicio_em: string
          intervalo_fim_em?: string | null
          intervalo_inicio_em?: string | null
          local_hora_extra: string
          motivo_cancelamento?:
            | Database["public"]["Enums"]["motivo_cancelamento_hora_extra"]
            | null
          motivo_reprovacao?:
            | Database["public"]["Enums"]["motivo_reprovacao_hora_extra"]
            | null
          observacao?: string | null
          operacao: Database["public"]["Enums"]["operacao_hora_extra"]
          reprovado_em?: string | null
          reprovado_por?: string | null
          status?: Database["public"]["Enums"]["status_hora_extra"]
          updated_at?: string
        }
        Update: {
          aprovado_em?: string | null
          aprovado_por?: string | null
          cancelado_em?: string | null
          cancelado_por?: string | null
          colaborador_cobrindo_id?: string
          confirmado_em?: string | null
          confirmado_por?: string | null
          criado_em?: string
          criado_por?: string
          data_hora_extra?: string
          detalhe_cancelamento?: string | null
          detalhe_reprovacao?: string | null
          falta_id?: number | null
          fim_em?: string
          id?: string
          inicio_em?: string
          intervalo_fim_em?: string | null
          intervalo_inicio_em?: string | null
          local_hora_extra?: string
          motivo_cancelamento?:
            | Database["public"]["Enums"]["motivo_cancelamento_hora_extra"]
            | null
          motivo_reprovacao?:
            | Database["public"]["Enums"]["motivo_reprovacao_hora_extra"]
            | null
          observacao?: string | null
          operacao?: Database["public"]["Enums"]["operacao_hora_extra"]
          reprovado_em?: string | null
          reprovado_por?: string | null
          status?: Database["public"]["Enums"]["status_hora_extra"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "horas_extras_aprovado_por_fkey"
            columns: ["aprovado_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "horas_extras_cancelado_por_fkey"
            columns: ["cancelado_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "horas_extras_colaborador_cobrindo_id_fkey"
            columns: ["colaborador_cobrindo_id"]
            isOneToOne: false
            referencedRelation: "colaboradores_convenia"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "horas_extras_confirmado_por_fkey"
            columns: ["confirmado_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "horas_extras_cost_center_id_fkey"
            columns: ["local_hora_extra"]
            isOneToOne: false
            referencedRelation: "cost_center"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "horas_extras_criado_por_fkey"
            columns: ["criado_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "horas_extras_falta_id_fkey"
            columns: ["falta_id"]
            isOneToOne: false
            referencedRelation: "faltas_colaboradores_convenia"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "horas_extras_reprovado_por_fkey"
            columns: ["reprovado_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
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
      internal_profile_cost_centers: {
        Row: {
          cost_center_id: string
          created_at: string
          created_by: string
          id: string
          user_id: string
        }
        Insert: {
          cost_center_id: string
          created_at?: string
          created_by: string
          id?: string
          user_id: string
        }
        Update: {
          cost_center_id?: string
          created_at?: string
          created_by?: string
          id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "internal_profile_cost_centers_cost_center_id_fkey"
            columns: ["cost_center_id"]
            isOneToOne: false
            referencedRelation: "cost_center"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "internal_profile_cost_centers_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "internal_profile_cost_centers_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
      internal_profiles: {
        Row: {
          cargo: string | null
          cpf: string | null
          created_at: string
          departamento: string | null
          email: string | null
          nivel_acesso: Database["public"]["Enums"]["internal_access_level"]
          nome_completo: string | null
          phone: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          cargo?: string | null
          cpf?: string | null
          created_at?: string
          departamento?: string | null
          email?: string | null
          nivel_acesso?: Database["public"]["Enums"]["internal_access_level"]
          nome_completo?: string | null
          phone?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          cargo?: string | null
          cpf?: string | null
          created_at?: string
          departamento?: string | null
          email?: string | null
          nivel_acesso?: Database["public"]["Enums"]["internal_access_level"]
          nome_completo?: string | null
          phone?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "internal_profiles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "usuarios"
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
      module_audit_logs: {
        Row: {
          action_name: string
          actor_user_id: string | null
          created_at: string
          entity_id: string
          entity_name: string
          id: string
          metadata: Json | null
          new_data: Json | null
          old_data: Json | null
        }
        Insert: {
          action_name: string
          actor_user_id?: string | null
          created_at?: string
          entity_id: string
          entity_name: string
          id?: string
          metadata?: Json | null
          new_data?: Json | null
          old_data?: Json | null
        }
        Update: {
          action_name?: string
          actor_user_id?: string | null
          created_at?: string
          entity_id?: string
          entity_name?: string
          id?: string
          metadata?: Json | null
          new_data?: Json | null
          old_data?: Json | null
        }
        Relationships: [
          {
            foreignKeyName: "module_audit_logs_actor_user_id_fkey"
            columns: ["actor_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
      module_colaborador_cargos: {
        Row: {
          area_nome: string | null
          ativo: boolean
          cargo_nome: string
          created_at: string
          descricao: string | null
          id: string
          updated_at: string
          user_id: string
        }
        Insert: {
          area_nome?: string | null
          ativo?: boolean
          cargo_nome: string
          created_at?: string
          descricao?: string | null
          id?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          area_nome?: string | null
          ativo?: boolean
          cargo_nome?: string
          created_at?: string
          descricao?: string | null
          id?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "module_colaborador_cargos_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
      module_equipe_cost_centers: {
        Row: {
          cost_center_id: string
          created_at: string
          equipe_id: string
          id: string
        }
        Insert: {
          cost_center_id: string
          created_at?: string
          equipe_id: string
          id?: string
        }
        Update: {
          cost_center_id?: string
          created_at?: string
          equipe_id?: string
          id?: string
        }
        Relationships: [
          {
            foreignKeyName: "module_equipe_cost_centers_cost_center_id_fkey"
            columns: ["cost_center_id"]
            isOneToOne: false
            referencedRelation: "cost_center"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "module_equipe_cost_centers_equipe_id_fkey"
            columns: ["equipe_id"]
            isOneToOne: false
            referencedRelation: "module_equipes"
            referencedColumns: ["id"]
          },
        ]
      }
      module_equipe_membros: {
        Row: {
          added_by_user_id: string
          ativo: boolean
          cost_center_id: string
          created_at: string
          equipe_id: string
          id: string
          updated_at: string
          user_id: string
        }
        Insert: {
          added_by_user_id: string
          ativo?: boolean
          cost_center_id: string
          created_at?: string
          equipe_id: string
          id?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          added_by_user_id?: string
          ativo?: boolean
          cost_center_id?: string
          created_at?: string
          equipe_id?: string
          id?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "module_equipe_membros_added_by_user_id_fkey"
            columns: ["added_by_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "module_equipe_membros_cost_center_id_fkey"
            columns: ["cost_center_id"]
            isOneToOne: false
            referencedRelation: "cost_center"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "module_equipe_membros_equipe_id_fkey"
            columns: ["equipe_id"]
            isOneToOne: false
            referencedRelation: "module_equipes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "module_equipe_membros_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
      module_equipes: {
        Row: {
          ativo: boolean
          created_at: string
          criada_por_user_id: string
          descricao: string | null
          escopo: string
          id: string
          nome: string
          updated_at: string
        }
        Insert: {
          ativo?: boolean
          created_at?: string
          criada_por_user_id: string
          descricao?: string | null
          escopo: string
          id?: string
          nome: string
          updated_at?: string
        }
        Update: {
          ativo?: boolean
          created_at?: string
          criada_por_user_id?: string
          descricao?: string | null
          escopo?: string
          id?: string
          nome?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "module_equipes_criada_por_user_id_fkey"
            columns: ["criada_por_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
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
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ordens_servico_solicitante_id_fkey"
            columns: ["solicitante_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
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
      password_reset_tokens: {
        Row: {
          created_at: string
          expires_at: string
          id: string
          profile_id: string
          token_hash: string
          used_at: string | null
        }
        Insert: {
          created_at?: string
          expires_at: string
          id?: string
          profile_id: string
          token_hash: string
          used_at?: string | null
        }
        Update: {
          created_at?: string
          expires_at?: string
          id?: string
          profile_id?: string
          token_hash?: string
          used_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "password_reset_tokens_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
      perfil_candidato: {
        Row: {
          altura: number | null
          created_at: string
          curso_adicional: string[] | null
          estado_civil: Database["public"]["Enums"]["estado_civil"] | null
          experiencia: string[] | null
          formacao: string[] | null
          habilidade: string[] | null
          id: string
          idade_maxima: number | null
          idade_minima: number | null
          peso: number | null
          requisito_descricao: string | null
          sexo: Database["public"]["Enums"]["sexualidade"] | null
          tempo_minimo_experiencia: number | null
          tipo_requisito: Database["public"]["Enums"]["tipos_requisito"]
          updated_at: string
        }
        Insert: {
          altura?: number | null
          created_at?: string
          curso_adicional?: string[] | null
          estado_civil?: Database["public"]["Enums"]["estado_civil"] | null
          experiencia?: string[] | null
          formacao?: string[] | null
          habilidade?: string[] | null
          id?: string
          idade_maxima?: number | null
          idade_minima?: number | null
          peso?: number | null
          requisito_descricao?: string | null
          sexo?: Database["public"]["Enums"]["sexualidade"] | null
          tempo_minimo_experiencia?: number | null
          tipo_requisito: Database["public"]["Enums"]["tipos_requisito"]
          updated_at?: string
        }
        Update: {
          altura?: number | null
          created_at?: string
          curso_adicional?: string[] | null
          estado_civil?: Database["public"]["Enums"]["estado_civil"] | null
          experiencia?: string[] | null
          formacao?: string[] | null
          habilidade?: string[] | null
          id?: string
          idade_maxima?: number | null
          idade_minima?: number | null
          peso?: number | null
          requisito_descricao?: string | null
          sexo?: Database["public"]["Enums"]["sexualidade"] | null
          tempo_minimo_experiencia?: number | null
          tipo_requisito?: Database["public"]["Enums"]["tipos_requisito"]
          updated_at?: string
        }
        Relationships: []
      }
      plano_acao_atualizacoes: {
        Row: {
          autor_user_id: string
          comentario: string | null
          created_at: string
          id: string
          plano_acao_id: string
          progresso_percentual: number | null
          status_anterior:
            | Database["public"]["Enums"]["action_plan_status"]
            | null
          status_novo: Database["public"]["Enums"]["action_plan_status"] | null
        }
        Insert: {
          autor_user_id: string
          comentario?: string | null
          created_at?: string
          id?: string
          plano_acao_id: string
          progresso_percentual?: number | null
          status_anterior?:
            | Database["public"]["Enums"]["action_plan_status"]
            | null
          status_novo?: Database["public"]["Enums"]["action_plan_status"] | null
        }
        Update: {
          autor_user_id?: string
          comentario?: string | null
          created_at?: string
          id?: string
          plano_acao_id?: string
          progresso_percentual?: number | null
          status_anterior?:
            | Database["public"]["Enums"]["action_plan_status"]
            | null
          status_novo?: Database["public"]["Enums"]["action_plan_status"] | null
        }
        Relationships: [
          {
            foreignKeyName: "plano_acao_atualizacoes_autor_user_id_fkey"
            columns: ["autor_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plano_acao_atualizacoes_plano_acao_id_fkey"
            columns: ["plano_acao_id"]
            isOneToOne: false
            referencedRelation: "planos_acao"
            referencedColumns: ["id"]
          },
        ]
      }
      plano_acao_responsaveis: {
        Row: {
          assigned_by_user_id: string
          assigned_user_id: string
          ativo: boolean
          atribuido_em: string
          id: string
          plano_acao_id: string
        }
        Insert: {
          assigned_by_user_id: string
          assigned_user_id: string
          ativo?: boolean
          atribuido_em?: string
          id?: string
          plano_acao_id: string
        }
        Update: {
          assigned_by_user_id?: string
          assigned_user_id?: string
          ativo?: boolean
          atribuido_em?: string
          id?: string
          plano_acao_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "plano_acao_responsaveis_assigned_by_user_id_fkey"
            columns: ["assigned_by_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plano_acao_responsaveis_assigned_user_id_fkey"
            columns: ["assigned_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plano_acao_responsaveis_plano_acao_id_fkey"
            columns: ["plano_acao_id"]
            isOneToOne: false
            referencedRelation: "planos_acao"
            referencedColumns: ["id"]
          },
        ]
      }
      planos_acao: {
        Row: {
          acao_proposta: string
          checklist_avaliacao_id: string
          checklist_instancia_id: string
          classe_nao_conformidade: Database["public"]["Enums"]["action_plan_nonconformity_class"]
          created_at: string
          criado_por_user_id: string
          equipe_responsavel_id: string
          finalizado_em: string | null
          finalizado_por_user_id: string | null
          id: string
          nao_conformidades_resumo: string
          prazo_em: string
          status: Database["public"]["Enums"]["action_plan_status"]
          updated_at: string
        }
        Insert: {
          acao_proposta: string
          checklist_avaliacao_id: string
          checklist_instancia_id: string
          classe_nao_conformidade: Database["public"]["Enums"]["action_plan_nonconformity_class"]
          created_at?: string
          criado_por_user_id: string
          equipe_responsavel_id: string
          finalizado_em?: string | null
          finalizado_por_user_id?: string | null
          id?: string
          nao_conformidades_resumo: string
          prazo_em: string
          status?: Database["public"]["Enums"]["action_plan_status"]
          updated_at?: string
        }
        Update: {
          acao_proposta?: string
          checklist_avaliacao_id?: string
          checklist_instancia_id?: string
          classe_nao_conformidade?: Database["public"]["Enums"]["action_plan_nonconformity_class"]
          created_at?: string
          criado_por_user_id?: string
          equipe_responsavel_id?: string
          finalizado_em?: string | null
          finalizado_por_user_id?: string | null
          id?: string
          nao_conformidades_resumo?: string
          prazo_em?: string
          status?: Database["public"]["Enums"]["action_plan_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "planos_acao_checklist_avaliacao_id_fkey"
            columns: ["checklist_avaliacao_id"]
            isOneToOne: false
            referencedRelation: "checklist_avaliacoes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "planos_acao_checklist_instancia_id_fkey"
            columns: ["checklist_instancia_id"]
            isOneToOne: true
            referencedRelation: "checklist_instancias"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "planos_acao_criado_por_user_id_fkey"
            columns: ["criado_por_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "planos_acao_equipe_responsavel_id_fkey"
            columns: ["equipe_responsavel_id"]
            isOneToOne: false
            referencedRelation: "module_equipes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "planos_acao_finalizado_por_user_id_fkey"
            columns: ["finalizado_por_user_id"]
            isOneToOne: false
            referencedRelation: "usuarios"
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
          acumulo_funcao:
            | Database["public"]["Enums"]["acumulo_funcao_options"]
            | null
          acumulo_funcao_percentual: number | null
          adc_insalubridade_percentual: number | null
          adicional_noturno: boolean | null
          assistencia_medica: boolean | null
          cesta: boolean | null
          cliente_id: number
          cost_center_id: string | null
          created_at: string | null
          dias_semana: number[] | null
          efetivo_planejado: number | null
          escala: string | null
          funcao: string
          gratificacao: boolean | null
          horario_fim: string | null
          horario_inicio: string | null
          id: string
          insalubridade: boolean | null
          intervalo_refeicao: number | null
          intrajornada: boolean | null
          jornada: number | null
          nome: string
          observacoes_especificas: string | null
          outros_beneficios: string[] | null
          periculosidade: boolean | null
          premio_assiduidade: boolean | null
          primeiro_dia_atividade: string | null
          salario: number | null
          status: Database["public"]["Enums"]["status_posto"] | null
          turno: Database["public"]["Enums"]["turno_opcoes"] | null
          ultimo_dia_atividade: string | null
          unidade_id: string | null
          updated_at: string | null
          valor_diaria: number
          valor_unitario: number | null
          vr_dia: number | null
          vt_dia: number | null
        }
        Insert: {
          acumulo_funcao?:
            | Database["public"]["Enums"]["acumulo_funcao_options"]
            | null
          acumulo_funcao_percentual?: number | null
          adc_insalubridade_percentual?: number | null
          adicional_noturno?: boolean | null
          assistencia_medica?: boolean | null
          cesta?: boolean | null
          cliente_id: number
          cost_center_id?: string | null
          created_at?: string | null
          dias_semana?: number[] | null
          efetivo_planejado?: number | null
          escala?: string | null
          funcao: string
          gratificacao?: boolean | null
          horario_fim?: string | null
          horario_inicio?: string | null
          id?: string
          insalubridade?: boolean | null
          intervalo_refeicao?: number | null
          intrajornada?: boolean | null
          jornada?: number | null
          nome: string
          observacoes_especificas?: string | null
          outros_beneficios?: string[] | null
          periculosidade?: boolean | null
          premio_assiduidade?: boolean | null
          primeiro_dia_atividade?: string | null
          salario?: number | null
          status?: Database["public"]["Enums"]["status_posto"] | null
          turno?: Database["public"]["Enums"]["turno_opcoes"] | null
          ultimo_dia_atividade?: string | null
          unidade_id?: string | null
          updated_at?: string | null
          valor_diaria?: number
          valor_unitario?: number | null
          vr_dia?: number | null
          vt_dia?: number | null
        }
        Update: {
          acumulo_funcao?:
            | Database["public"]["Enums"]["acumulo_funcao_options"]
            | null
          acumulo_funcao_percentual?: number | null
          adc_insalubridade_percentual?: number | null
          adicional_noturno?: boolean | null
          assistencia_medica?: boolean | null
          cesta?: boolean | null
          cliente_id?: number
          cost_center_id?: string | null
          created_at?: string | null
          dias_semana?: number[] | null
          efetivo_planejado?: number | null
          escala?: string | null
          funcao?: string
          gratificacao?: boolean | null
          horario_fim?: string | null
          horario_inicio?: string | null
          id?: string
          insalubridade?: boolean | null
          intervalo_refeicao?: number | null
          intrajornada?: boolean | null
          jornada?: number | null
          nome?: string
          observacoes_especificas?: string | null
          outros_beneficios?: string[] | null
          periculosidade?: boolean | null
          premio_assiduidade?: boolean | null
          primeiro_dia_atividade?: string | null
          salario?: number | null
          status?: Database["public"]["Enums"]["status_posto"] | null
          turno?: Database["public"]["Enums"]["turno_opcoes"] | null
          ultimo_dia_atividade?: string | null
          unidade_id?: string | null
          updated_at?: string | null
          valor_diaria?: number
          valor_unitario?: number | null
          vr_dia?: number | null
          vt_dia?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "postos_servico_cliente_id_fkey"
            columns: ["cliente_id"]
            isOneToOne: false
            referencedRelation: "clientes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "postos_servico_cost_center_id_fkey"
            columns: ["cost_center_id"]
            isOneToOne: false
            referencedRelation: "cost_center"
            referencedColumns: ["id"]
          },
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
      subitens: {
        Row: {
          cliente_id: number
          created_at: string
          id: string
          nome: string
          observacao: string | null
          updated_at: string
          valor_unitario: number | null
        }
        Insert: {
          cliente_id: number
          created_at?: string
          id?: string
          nome: string
          observacao?: string | null
          updated_at?: string
          valor_unitario?: number | null
        }
        Update: {
          cliente_id?: number
          created_at?: string
          id?: string
          nome?: string
          observacao?: string | null
          updated_at?: string
          valor_unitario?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "subitens_cliente_id_fkey"
            columns: ["cliente_id"]
            isOneToOne: false
            referencedRelation: "clientes"
            referencedColumns: ["id"]
          },
        ]
      }
      sync_logs: {
        Row: {
          completed_at: string | null
          created_at: string | null
          error_message: string | null
          id: string
          job_name: string
          records_synced: number | null
          response_data: Json | null
          started_at: string | null
          status: string | null
        }
        Insert: {
          completed_at?: string | null
          created_at?: string | null
          error_message?: string | null
          id?: string
          job_name: string
          records_synced?: number | null
          response_data?: Json | null
          started_at?: string | null
          status?: string | null
        }
        Update: {
          completed_at?: string | null
          created_at?: string | null
          error_message?: string | null
          id?: string
          job_name?: string
          records_synced?: number | null
          response_data?: Json | null
          started_at?: string | null
          status?: string | null
        }
        Relationships: []
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
          role: Database["public"]["Enums"]["internal_access_level"]
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          role?: Database["public"]["Enums"]["internal_access_level"]
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          role?: Database["public"]["Enums"]["internal_access_level"]
          user_id?: string
        }
        Relationships: []
      }
      usuarios: {
        Row: {
          created_at: string
          email: string
          full_name: string | null
          id: string
          phone: string | null
          role: Database["public"]["Enums"]["user_type"]
          superior: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          email: string
          full_name?: string | null
          id: string
          phone?: string | null
          role?: Database["public"]["Enums"]["user_type"]
          superior?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          email?: string
          full_name?: string | null
          id?: string
          phone?: string | null
          role?: Database["public"]["Enums"]["user_type"]
          superior?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "profiles_superior_fkey"
            columns: ["superior"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
      vagas_temp: {
        Row: {
          aberta_por: string
          altura: number | null
          aprovada_por: string | null
          cancelada_por: string | null
          created_at: string
          criado_por: string
          curso_adicional: string[] | null
          data_abertura: string
          data_aprovacao: string | null
          data_cancelamento: string | null
          data_fechamento: string | null
          data_fim: string | null
          data_inicio: string
          data_reprovacao: string | null
          data_selecao: string | null
          entrevistador: string | null
          estado_civil: Database["public"]["Enums"]["estado_civil"] | null
          experiencia: string[] | null
          fechada_por: string | null
          formacao: string[] | null
          habilidade: string[] | null
          horario_fim: string
          horario_inicio: string
          id: number
          idade_maxima: number | null
          idade_minima: number | null
          intervalo_refeicao: number
          motivo_contratacao: Database["public"]["Enums"]["motivo_contratacao"]
          nome_candidato: string | null
          nome_colaborador: string | null
          nome_vaga: string
          observacoes: string | null
          peso: number | null
          posto_servico_id: string
          reprovada_por: string | null
          requisito_descricao: string | null
          sexo: Database["public"]["Enums"]["sexualidade"] | null
          status: Database["public"]["Enums"]["status_vaga"]
          tempo_minimo_experiencia: number | null
          tipo_requisito: Database["public"]["Enums"]["tipos_requisito"]
          tipo_vaga: Database["public"]["Enums"]["tipo_de_vaga"]
          updated_at: string
        }
        Insert: {
          aberta_por: string
          altura?: number | null
          aprovada_por?: string | null
          cancelada_por?: string | null
          created_at?: string
          criado_por: string
          curso_adicional?: string[] | null
          data_abertura?: string
          data_aprovacao?: string | null
          data_cancelamento?: string | null
          data_fechamento?: string | null
          data_fim?: string | null
          data_inicio: string
          data_reprovacao?: string | null
          data_selecao?: string | null
          entrevistador?: string | null
          estado_civil?: Database["public"]["Enums"]["estado_civil"] | null
          experiencia?: string[] | null
          fechada_por?: string | null
          formacao?: string[] | null
          habilidade?: string[] | null
          horario_fim: string
          horario_inicio: string
          id?: number
          idade_maxima?: number | null
          idade_minima?: number | null
          intervalo_refeicao?: number
          motivo_contratacao: Database["public"]["Enums"]["motivo_contratacao"]
          nome_candidato?: string | null
          nome_colaborador?: string | null
          nome_vaga: string
          observacoes?: string | null
          peso?: number | null
          posto_servico_id: string
          reprovada_por?: string | null
          requisito_descricao?: string | null
          sexo?: Database["public"]["Enums"]["sexualidade"] | null
          status?: Database["public"]["Enums"]["status_vaga"]
          tempo_minimo_experiencia?: number | null
          tipo_requisito: Database["public"]["Enums"]["tipos_requisito"]
          tipo_vaga: Database["public"]["Enums"]["tipo_de_vaga"]
          updated_at?: string
        }
        Update: {
          aberta_por?: string
          altura?: number | null
          aprovada_por?: string | null
          cancelada_por?: string | null
          created_at?: string
          criado_por?: string
          curso_adicional?: string[] | null
          data_abertura?: string
          data_aprovacao?: string | null
          data_cancelamento?: string | null
          data_fechamento?: string | null
          data_fim?: string | null
          data_inicio?: string
          data_reprovacao?: string | null
          data_selecao?: string | null
          entrevistador?: string | null
          estado_civil?: Database["public"]["Enums"]["estado_civil"] | null
          experiencia?: string[] | null
          fechada_por?: string | null
          formacao?: string[] | null
          habilidade?: string[] | null
          horario_fim?: string
          horario_inicio?: string
          id?: number
          idade_maxima?: number | null
          idade_minima?: number | null
          intervalo_refeicao?: number
          motivo_contratacao?: Database["public"]["Enums"]["motivo_contratacao"]
          nome_candidato?: string | null
          nome_colaborador?: string | null
          nome_vaga?: string
          observacoes?: string | null
          peso?: number | null
          posto_servico_id?: string
          reprovada_por?: string | null
          requisito_descricao?: string | null
          sexo?: Database["public"]["Enums"]["sexualidade"] | null
          status?: Database["public"]["Enums"]["status_vaga"]
          tempo_minimo_experiencia?: number | null
          tipo_requisito?: Database["public"]["Enums"]["tipos_requisito"]
          tipo_vaga?: Database["public"]["Enums"]["tipo_de_vaga"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "vagas_temp_aberta_por_fkey"
            columns: ["aberta_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vagas_temp_aprovada_por_fkey"
            columns: ["aprovada_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vagas_temp_cancelada_por_fkey"
            columns: ["cancelada_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vagas_temp_criado_por_fkey"
            columns: ["criado_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vagas_temp_entrevistador_fkey"
            columns: ["entrevistador"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vagas_temp_fechada_por_fkey"
            columns: ["fechada_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vagas_temp_nome_candidato_fkey"
            columns: ["nome_candidato"]
            isOneToOne: false
            referencedRelation: "candidatos"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vagas_temp_nome_colaborador_fkey"
            columns: ["nome_colaborador"]
            isOneToOne: false
            referencedRelation: "colaboradores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vagas_temp_posto_servico_id_fkey"
            columns: ["posto_servico_id"]
            isOneToOne: false
            referencedRelation: "postos_servico"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vagas_temp_reprovada_por_fkey"
            columns: ["reprovada_por"]
            isOneToOne: false
            referencedRelation: "usuarios"
            referencedColumns: ["id"]
          },
        ]
      }
      webhook_logs: {
        Row: {
          created_at: string | null
          error_message: string | null
          event_type: string | null
          id: string
          payload: Json | null
          processed_at: string | null
          source: string
          status: string | null
        }
        Insert: {
          created_at?: string | null
          error_message?: string | null
          event_type?: string | null
          id?: string
          payload?: Json | null
          processed_at?: string | null
          source: string
          status?: string | null
        }
        Update: {
          created_at?: string | null
          error_message?: string | null
          event_type?: string | null
          id?: string
          payload?: Json | null
          processed_at?: string | null
          source?: string
          status?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      usuarios_public: {
        Row: {
          cargo: string | null
          full_name: string | null
          id: string | null
        }
        Relationships: []
      }
    }
    Functions: {
      adicionar_diarista_blacklist: {
        Args: {
          p_bloqueado_por: string
          p_diarista_id: string
          p_motivo: string
        }
        Returns: undefined
      }
      agendar_ocupacao_posto: {
        Args: {
          p_colaborador_id: string
          p_data: string
          p_posto_servico_id: string
          p_usuario_id?: string
        }
        Returns: undefined
      }
      aprovar_hora_extra: {
        Args: { p_hora_extra_id: string }
        Returns: undefined
      }
      arquivar_dias_trabalho_em_presencas: { Args: never; Returns: undefined }
      calc_next_recurrence: {
        Args: {
          _from: string
          _intervalo: number
          _recurrence: Database["public"]["Enums"]["module_recurrence_type"]
        }
        Returns: string
      }
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
      can_assign_action_plan_user: {
        Args: { _assigned_user_id: string; _cost_center_id: string }
        Returns: boolean
      }
      can_assign_checklist_task: {
        Args: { _assigned_user_id: string; _cost_center_id: string }
        Returns: boolean
      }
      can_change_checklist_task_kanban: {
        Args: { _instancia_tarefa_id: string; _user_id: string }
        Returns: boolean
      }
      can_create_checklist_template: {
        Args: { _cost_center_id: string; _user_id: string }
        Returns: boolean
      }
      can_manage_checklist_cc: {
        Args: { _cost_center_id: string; _user_id: string }
        Returns: boolean
      }
      can_manage_equipe: {
        Args: { _equipe_id: string; _user_id: string }
        Returns: boolean
      }
      can_review_checklist: {
        Args: { _cost_center_id: string; _user_id: string }
        Returns: boolean
      }
      can_update_action_plan_status: {
        Args: { _cost_center_id: string; _user_id: string }
        Returns: boolean
      }
      cancelar_execucao_checklist: {
        Args: { execucao_id: string }
        Returns: undefined
      }
      cancelar_execucao_checklist_item: {
        Args: { execucao_item_id: string }
        Returns: undefined
      }
      cancelar_hora_extra: {
        Args: {
          p_detalhe_cancelamento?: string
          p_hora_extra_id: string
          p_motivo_cancelamento: Database["public"]["Enums"]["motivo_cancelamento_hora_extra"]
        }
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
      checklist_instance_allows_kanban_edit: {
        Args: {
          _instance_status: Database["public"]["Enums"]["checklist_instance_status"]
        }
        Returns: boolean
      }
      confirmar_hora_extra: {
        Args: { p_hora_extra_id: string }
        Returns: undefined
      }
      confirmar_presenca: {
        Args: {
          p_dia_trabalho_id: string
          p_novo_status: Database["public"]["Enums"]["status_posto"]
        }
        Returns: undefined
      }
      criar_diaria_falta_justificada:
        | {
            Args: {
              p_atestado_path: string
              p_cliente_id: number
              p_colaborador_ausente?: string
              p_colaborador_ausente_convenia?: string
              p_colaborador_ausente_nome?: string
              p_data_diaria: string
              p_diarista_id: string
              p_horario_fim?: string
              p_horario_inicio?: string
              p_intervalo?: number
              p_jornada_diaria?: number
              p_observacao?: string
              p_posto_servico?: string
              p_posto_servico_id?: string
              p_unidade: string
              p_user_id?: string
              p_valor_diaria: number
            }
            Returns: number
          }
        | {
            Args: {
              p_atestado_path: string
              p_cliente_id: number
              p_colaborador_ausente?: string
              p_colaborador_ausente_convenia?: string
              p_colaborador_ausente_nome?: string
              p_data_diaria: string
              p_diarista_id: string
              p_horario_fim?: string
              p_horario_inicio?: string
              p_intervalo?: number
              p_jornada_diaria?: number
              p_observacao?: string
              p_posto_servico?: string
              p_posto_servico_id?: string
              p_unidade: string
              p_user_id: string
              p_valor_diaria: number
            }
            Returns: number
          }
      criar_hora_extra:
        | {
            Args: {
              p_colaborador_cobrindo_id: string
              p_falta_id: number
              p_fim_em: string
              p_inicio_em: string
              p_intervalo_fim_em?: string
              p_intervalo_inicio_em?: string
              p_observacao?: string
              p_operacao: Database["public"]["Enums"]["operacao_hora_extra"]
            }
            Returns: string
          }
        | {
            Args: {
              p_colaborador_cobrindo_id: string
              p_falta_id: number
              p_fim_em: string
              p_inicio_em: string
              p_intervalo_fim_em?: string
              p_intervalo_inicio_em?: string
              p_observacao?: string
              p_operacao: string
            }
            Returns: string
          }
      criar_notificacao_diaria: {
        Args: {
          p_campo: string
          p_diaria_id: number
          p_evento: string
          p_mensagem: string
          p_titulo: string
          p_user_id: string
          p_valor_antigo: string
          p_valor_novo: string
        }
        Returns: undefined
      }
      current_internal_access_level: {
        Args: never
        Returns: Database["public"]["Enums"]["internal_access_level"]
      }
      definir_usuario_como_colaborador: {
        Args: { p_cost_center_id: string; p_user_id: string }
        Returns: undefined
      }
      fn_diff_jsonb: { Args: { new_row: Json; old_row: Json }; Returns: Json }
      generate_due_checklist_instances: { Args: never; Returns: number }
      gerar_dias_trabalho_proximo_mes: { Args: never; Returns: undefined }
      get_action_plan_assignable_users: {
        Args: { _plano_acao_id: string }
        Returns: {
          email: string
          nivel_acesso: string
          nome: string
          tipo: string
          user_id: string
        }[]
      }
      get_current_user_can_manage_plan: {
        Args: { _plano_acao_id: string }
        Returns: boolean
      }
      get_equipe_id_for_instancia: {
        Args: { _instancia_id: string }
        Returns: string
      }
      get_visible_internal_users_public: {
        Args: never
        Returns: {
          cargo: string
          full_name: string
          id: string
        }[]
      }
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["internal_access_level"]
          _user_id: string
        }
        Returns: boolean
      }
      internal_user_can_access_chamado: {
        Args: { p_chamado_id: string; p_user_id: string }
        Returns: boolean
      }
      internal_user_can_access_local: {
        Args: { p_local_id: string; p_user_id: string }
        Returns: boolean
      }
      internal_user_can_use_local_for_chamado: {
        Args: { p_local_id: string; p_user_id: string }
        Returns: boolean
      }
      internal_user_has_cost_center_access: {
        Args: { p_cost_center_id: string; p_user_id: string }
        Returns: boolean
      }
      internal_user_is_admin: { Args: { p_user_id: string }; Returns: boolean }
      is_action_plan_responsavel: {
        Args: { _plano_id: string; _user_id: string }
        Returns: boolean
      }
      is_admin: { Args: { _user_id: string }; Returns: boolean }
      is_admin_user: { Args: never; Returns: boolean }
      is_colaborador_user: { Args: { p_user_id: string }; Returns: boolean }
      is_internal_user: { Args: never; Returns: boolean }
      is_task_responsible: {
        Args: { _instancia_tarefa_id: string; _user_id: string }
        Returns: boolean
      }
      justificar_falta_convenia: {
        Args: {
          p_atestado_path: string
          p_diaria_temporaria_id: number
          p_user_id: string
        }
        Returns: undefined
      }
      justificar_falta_convenia_por_falta_id: {
        Args: { p_atestado_path: string; p_falta_id: number; p_user_id: string }
        Returns: undefined
      }
      justificar_falta_diaria_temporaria: {
        Args: {
          p_atestado_path: string
          p_diaria_temporaria_id: number
          p_user_id: string
        }
        Returns: undefined
      }
      limpar_diarias_antigas: { Args: never; Returns: undefined }
      limpar_diarias_temporarias_antigas: { Args: never; Returns: undefined }
      limpar_posto_dias_vagos_antigos: { Args: never; Returns: undefined }
      limpar_presencas_antigas: { Args: never; Returns: undefined }
      limpar_tokens_expirados: { Args: never; Returns: undefined }
      module_internal_in_cc: {
        Args: { _cost_center_id: string; _user_id: string }
        Returns: boolean
      }
      module_is_admin: { Args: { _user_id: string }; Returns: boolean }
      module_is_colaborador_in_cc: {
        Args: { _cost_center_id: string; _user_id: string }
        Returns: boolean
      }
      module_supervisor_has_cost_center: {
        Args: { _cost_center_id: string; _user_id: string }
        Returns: boolean
      }
      module_user_allowed: { Args: { _user_id: string }; Returns: boolean }
      normalizar_cpf: { Args: { input: string }; Returns: string }
      obter_usuarios_envolvidos_diaria: {
        Args: {
          p_new: Database["public"]["Tables"]["diarias_temporarias"]["Row"]
          p_old: Database["public"]["Tables"]["diarias_temporarias"]["Row"]
        }
        Returns: {
          user_id: string
        }[]
      }
      processar_movimentacoes_agendadas: { Args: never; Returns: undefined }
      reprovar_hora_extra: {
        Args: {
          p_detalhe_reprovacao?: string
          p_hora_extra_id: string
          p_motivo_reprovacao: Database["public"]["Enums"]["motivo_reprovacao_hora_extra"]
        }
        Returns: undefined
      }
      reverter_justificativa_falta_convenia:
        | {
            Args: {
              p_bucket_id?: string
              p_falta_id: number
              p_user_id: string
            }
            Returns: string
          }
        | { Args: { p_falta_id: string; p_user_id: string }; Returns: string }
      template_has_instancias: {
        Args: { _template_id: string }
        Returns: boolean
      }
    }
    Enums: {
      action_plan_nonconformity_class:
        | "organizacao"
        | "limpeza"
        | "conservacao"
        | "manutencao_predial"
        | "manutencao_equipamentos"
        | "infraestrutura"
        | "instalacoes_eletricas"
        | "instalacoes_hidraulicas"
        | "ti_sistemas"
        | "ti_hardware"
        | "ti_rede"
        | "seguranca_trabalho"
        | "seguranca_patrimonial"
        | "epi"
        | "epc"
        | "sinalizacao"
        | "acessibilidade"
        | "ergonomia"
        | "saude_ocupacional"
        | "treinamentos"
        | "competencia_tecnica"
        | "documentacao"
        | "procedimentos"
        | "qualidade"
        | "processos_operacionais"
        | "produtividade"
        | "comunicacao"
        | "lideranca"
        | "dimensionamento_equipe"
        | "comportamento_conduta"
        | "disciplina_operacional"
        | "atendimento_cliente"
        | "fornecedores"
        | "materiais_insumos"
        | "estoque_armazenamento"
        | "transporte_logistica"
        | "meio_ambiente"
        | "residuos_descartes"
        | "conformidade_legal"
        | "compliance"
        | "auditoria_controles"
        | "financeiro_orcamento"
        | "planejamento"
        | "continuidade_operacional"
        | "risco"
        | "incidente_ocorrencia"
        | "outros"
      action_plan_status:
        | "open"
        | "in_progress"
        | "waiting_validation"
        | "done"
        | "cancelled"
      acumulo_funcao_options: "Sim" | "Não" | "Especial"
      chamado_prioridade: "baixa" | "media" | "alta" | "critica"
      chamado_status:
        | "aberto"
        | "em_andamento"
        | "pendente"
        | "resolvido"
        | "fechado"
        | "cancelado"
      checklist_instance_status:
        | "scheduled"
        | "open"
        | "in_progress"
        | "submitted"
        | "under_review"
        | "reviewed"
        | "awaiting_action_plan"
        | "closed"
        | "cancelled"
      checklist_review_decision:
        | "approved"
        | "rejected"
        | "needs_action_plan"
        | "needs_adjustment"
      checklist_task_kanban_status:
        | "pending"
        | "doing"
        | "blocked"
        | "ignored"
        | "done"
        | "closed"
      checklist_task_response_type:
        | "conformity_radio"
        | "text"
        | "textarea"
        | "number"
        | "score"
        | "boolean"
        | "single_select"
        | "multi_select"
        | "date"
        | "datetime"
        | "time"
      checklist_template_status: "draft" | "published" | "archived"
      estado_civil:
        | "Solteiro"
        | "Casado"
        | "Divorciado"
        | "Viúvo"
        | "Indiferente"
      internal_access_level:
        | "admin"
        | "gestor_operacoes"
        | "supervisor"
        | "analista_centro_controle"
        | "tecnico"
        | "cliente_view"
        | "assistente_operacoes"
        | "assistente_financeiro"
        | "gestor_financeiro"
      module_recurrence_type:
        | "one_time"
        | "daily"
        | "weekly"
        | "biweekly"
        | "monthly"
        | "quarterly"
        | "semiannual"
        | "annual"
      motivo_cancelamento_hora_extra:
        | "cobertura_nao_necessaria"
        | "lancamento_indevido"
        | "substituicao_reorganizada"
        | "erro_operacional"
        | "outros"
      motivo_contratacao:
        | "Substituição efetivo"
        | "Substituição férias licença"
        | "Implantação/Abertura de novo contrato"
        | "Solicitação do cliente"
      motivo_reprovacao: "Diarista ausente" | "Dados incorretos"
      motivo_reprovacao_hora_extra:
        | "horario_invalido"
        | "dados_inconsistentes"
        | "colaborador_indisponivel"
        | "falta_sem_validacao"
        | "duplicidade"
        | "outros"
      motivo_vago_type:
        | "DIÁRIA - FALTA ATESTADO"
        | "DIÁRIA - FALTA"
        | "AFASTAMENTO INSS"
        | "DIÁRIA - FÉRIAS"
        | "SUSPENSÃO"
        | "DIÁRIA - SALÁRIO"
        | "LICENÇA MATERNIDADE"
        | "LICENÇA PATERNIDADE"
        | "LICENÇA CASAMENTO"
        | "LICENÇA NOJO (FALECIMENTO)"
        | "DIÁRIA - DEMANDA EXTRA"
        | "DIÁRIA - BÔNUS"
      observacao_pagamento_type:
        | "Valores divergentes"
        | "Beneficiário do pix não identificado"
        | "Outros"
      operacao_hora_extra:
        | "cobertura_falta"
        | "cobertura_falta_atestado"
        | "cobertura_ferias"
        | "cobertura_afastamento_inss"
        | "cobertura_licenca"
        | "demanda_extra"
        | "bonus"
        | "dobra_turno"
        | "extensao_jornada"
        | "outros"
      periodicidade_type:
        | "diaria"
        | "semanal"
        | "quinzenal"
        | "mensal"
        | "trimestral"
        | "semestral"
        | "anual"
      sexualidade: "Masculino" | "Feminino" | "Indiferente"
      status_colaborador: "ativo" | "inativo"
      status_diaria:
        | "Aguardando confirmacao"
        | "Confirmada"
        | "Aprovada"
        | "Lançada para pagamento"
        | "Paga"
        | "Cancelada"
        | "Reprovada"
      status_diarista: "ativo" | "inativo" | "desligado" | "restrito"
      status_execucao: "ativo" | "concluido" | "atrasado" | "cancelado"
      status_hora_extra:
        | "pendente"
        | "confirmada"
        | "aprovada"
        | "reprovada"
        | "cancelada"
      status_posto:
        | "vago"
        | "ocupado"
        | "vago_temporariamente"
        | "ocupado_temporariamente"
        | "presenca_confirmada"
        | "ocupacao_agendada"
        | "inativo"
      status_vaga:
        | "Aberta"
        | "Em seleção"
        | "Em aprovação"
        | "Aguardando documentação"
        | "Aguardando exame"
        | "Em Admissão"
        | "Fechada"
        | "Cancelada"
        | "Reprovada"
      tipo_conta_bancaria: "conta corrente" | "conta poupança" | "conta salário"
      tipo_de_vaga: "Efetivo" | "Temporário" | "Seleção" | "Estágio"
      tipos_requisito:
        | "TQC (D.A. 06-01)"
        | "TQC (D.A. 06-01) + exigências do cliente"
        | "Solicitação do cliente"
      turno_opcoes:
        | "Diurno"
        | "Noturno"
        | "Vespertino"
        | "Revezamento"
        | "Ininterrupto"
      user_type: "candidato" | "colaborador" | "perfil_interno"
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
      action_plan_nonconformity_class: [
        "organizacao",
        "limpeza",
        "conservacao",
        "manutencao_predial",
        "manutencao_equipamentos",
        "infraestrutura",
        "instalacoes_eletricas",
        "instalacoes_hidraulicas",
        "ti_sistemas",
        "ti_hardware",
        "ti_rede",
        "seguranca_trabalho",
        "seguranca_patrimonial",
        "epi",
        "epc",
        "sinalizacao",
        "acessibilidade",
        "ergonomia",
        "saude_ocupacional",
        "treinamentos",
        "competencia_tecnica",
        "documentacao",
        "procedimentos",
        "qualidade",
        "processos_operacionais",
        "produtividade",
        "comunicacao",
        "lideranca",
        "dimensionamento_equipe",
        "comportamento_conduta",
        "disciplina_operacional",
        "atendimento_cliente",
        "fornecedores",
        "materiais_insumos",
        "estoque_armazenamento",
        "transporte_logistica",
        "meio_ambiente",
        "residuos_descartes",
        "conformidade_legal",
        "compliance",
        "auditoria_controles",
        "financeiro_orcamento",
        "planejamento",
        "continuidade_operacional",
        "risco",
        "incidente_ocorrencia",
        "outros",
      ],
      action_plan_status: [
        "open",
        "in_progress",
        "waiting_validation",
        "done",
        "cancelled",
      ],
      acumulo_funcao_options: ["Sim", "Não", "Especial"],
      chamado_prioridade: ["baixa", "media", "alta", "critica"],
      chamado_status: [
        "aberto",
        "em_andamento",
        "pendente",
        "resolvido",
        "fechado",
        "cancelado",
      ],
      checklist_instance_status: [
        "scheduled",
        "open",
        "in_progress",
        "submitted",
        "under_review",
        "reviewed",
        "awaiting_action_plan",
        "closed",
        "cancelled",
      ],
      checklist_review_decision: [
        "approved",
        "rejected",
        "needs_action_plan",
        "needs_adjustment",
      ],
      checklist_task_kanban_status: [
        "pending",
        "doing",
        "blocked",
        "ignored",
        "done",
        "closed",
      ],
      checklist_task_response_type: [
        "conformity_radio",
        "text",
        "textarea",
        "number",
        "score",
        "boolean",
        "single_select",
        "multi_select",
        "date",
        "datetime",
        "time",
      ],
      checklist_template_status: ["draft", "published", "archived"],
      estado_civil: [
        "Solteiro",
        "Casado",
        "Divorciado",
        "Viúvo",
        "Indiferente",
      ],
      internal_access_level: [
        "admin",
        "gestor_operacoes",
        "supervisor",
        "analista_centro_controle",
        "tecnico",
        "cliente_view",
        "assistente_operacoes",
        "assistente_financeiro",
        "gestor_financeiro",
      ],
      module_recurrence_type: [
        "one_time",
        "daily",
        "weekly",
        "biweekly",
        "monthly",
        "quarterly",
        "semiannual",
        "annual",
      ],
      motivo_cancelamento_hora_extra: [
        "cobertura_nao_necessaria",
        "lancamento_indevido",
        "substituicao_reorganizada",
        "erro_operacional",
        "outros",
      ],
      motivo_contratacao: [
        "Substituição efetivo",
        "Substituição férias licença",
        "Implantação/Abertura de novo contrato",
        "Solicitação do cliente",
      ],
      motivo_reprovacao: ["Diarista ausente", "Dados incorretos"],
      motivo_reprovacao_hora_extra: [
        "horario_invalido",
        "dados_inconsistentes",
        "colaborador_indisponivel",
        "falta_sem_validacao",
        "duplicidade",
        "outros",
      ],
      motivo_vago_type: [
        "DIÁRIA - FALTA ATESTADO",
        "DIÁRIA - FALTA",
        "AFASTAMENTO INSS",
        "DIÁRIA - FÉRIAS",
        "SUSPENSÃO",
        "DIÁRIA - SALÁRIO",
        "LICENÇA MATERNIDADE",
        "LICENÇA PATERNIDADE",
        "LICENÇA CASAMENTO",
        "LICENÇA NOJO (FALECIMENTO)",
        "DIÁRIA - DEMANDA EXTRA",
        "DIÁRIA - BÔNUS",
      ],
      observacao_pagamento_type: [
        "Valores divergentes",
        "Beneficiário do pix não identificado",
        "Outros",
      ],
      operacao_hora_extra: [
        "cobertura_falta",
        "cobertura_falta_atestado",
        "cobertura_ferias",
        "cobertura_afastamento_inss",
        "cobertura_licenca",
        "demanda_extra",
        "bonus",
        "dobra_turno",
        "extensao_jornada",
        "outros",
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
      sexualidade: ["Masculino", "Feminino", "Indiferente"],
      status_colaborador: ["ativo", "inativo"],
      status_diaria: [
        "Aguardando confirmacao",
        "Confirmada",
        "Aprovada",
        "Lançada para pagamento",
        "Paga",
        "Cancelada",
        "Reprovada",
      ],
      status_diarista: ["ativo", "inativo", "desligado", "restrito"],
      status_execucao: ["ativo", "concluido", "atrasado", "cancelado"],
      status_hora_extra: [
        "pendente",
        "confirmada",
        "aprovada",
        "reprovada",
        "cancelada",
      ],
      status_posto: [
        "vago",
        "ocupado",
        "vago_temporariamente",
        "ocupado_temporariamente",
        "presenca_confirmada",
        "ocupacao_agendada",
        "inativo",
      ],
      status_vaga: [
        "Aberta",
        "Em seleção",
        "Em aprovação",
        "Aguardando documentação",
        "Aguardando exame",
        "Em Admissão",
        "Fechada",
        "Cancelada",
        "Reprovada",
      ],
      tipo_conta_bancaria: [
        "conta corrente",
        "conta poupança",
        "conta salário",
      ],
      tipo_de_vaga: ["Efetivo", "Temporário", "Seleção", "Estágio"],
      tipos_requisito: [
        "TQC (D.A. 06-01)",
        "TQC (D.A. 06-01) + exigências do cliente",
        "Solicitação do cliente",
      ],
      turno_opcoes: [
        "Diurno",
        "Noturno",
        "Vespertino",
        "Revezamento",
        "Ininterrupto",
      ],
      user_type: ["candidato", "colaborador", "perfil_interno"],
    },
  },
} as const
