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
            referencedRelation: "usuarios"
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
            referencedRelation: "usuarios"
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
            referencedRelation: "usuarios"
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
          created_at?: string
          id?: number
          itens_adicionais?: string | null
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
          user_id: string | null
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
          user_id?: string | null
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
          user_id?: string | null
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
          aprovada_em: string | null
          aprovada_para_pagamento_em: string | null
          aprovada_por: string | null
          aprovado_para_pgto_por: string | null
          cancelada_em: string | null
          cancelada_por: string | null
          cliente_id: number
          colaborador_ausente: string | null
          colaborador_ausente_nome: string | null
          colaborador_demitido: string | null
          colaborador_demitido_nome: string | null
          colaborador_falecido: string | null
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
          licenca_nojo: boolean | null
          motivo_cancelamento: string | null
          motivo_reprovacao: string | null
          motivo_vago: Database["public"]["Enums"]["motivo_vago_type"]
          novo_posto: boolean | null
          observacao: string | null
          paga_em: string | null
          paga_por: string | null
          posto_servico: string | null
          posto_servico_id: string | null
          reprovada_em: string | null
          reprovada_por: string | null
          status: Database["public"]["Enums"]["status_diaria"]
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
          cliente_id: number
          colaborador_ausente?: string | null
          colaborador_ausente_nome?: string | null
          colaborador_demitido?: string | null
          colaborador_demitido_nome?: string | null
          colaborador_falecido?: string | null
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
          licenca_nojo?: boolean | null
          motivo_cancelamento?: string | null
          motivo_reprovacao?: string | null
          motivo_vago?: Database["public"]["Enums"]["motivo_vago_type"]
          novo_posto?: boolean | null
          observacao?: string | null
          paga_em?: string | null
          paga_por?: string | null
          posto_servico?: string | null
          posto_servico_id?: string | null
          reprovada_em?: string | null
          reprovada_por?: string | null
          status?: Database["public"]["Enums"]["status_diaria"]
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
          cliente_id?: number
          colaborador_ausente?: string | null
          colaborador_ausente_nome?: string | null
          colaborador_demitido?: string | null
          colaborador_demitido_nome?: string | null
          colaborador_falecido?: string | null
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
          licenca_nojo?: boolean | null
          motivo_cancelamento?: string | null
          motivo_reprovacao?: string | null
          motivo_vago?: Database["public"]["Enums"]["motivo_vago_type"]
          novo_posto?: boolean | null
          observacao?: string | null
          paga_em?: string | null
          paga_por?: string | null
          posto_servico?: string | null
          posto_servico_id?: string | null
          reprovada_em?: string | null
          reprovada_por?: string | null
          status?: Database["public"]["Enums"]["status_diaria"]
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
          cpf: string | null
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
          cpf?: string | null
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
          cpf?: string | null
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
            referencedRelation: "usuarios"
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
            referencedRelation: "usuarios"
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
          acumulo_funcao: boolean | null
          acumulo_funcao_percentual: number | null
          adc_insalubridade_percentual: number | null
          adicional_noturno: boolean | null
          assistencia_medica: boolean | null
          cesta: boolean | null
          cliente_id: number | null
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
          acumulo_funcao?: boolean | null
          acumulo_funcao_percentual?: number | null
          adc_insalubridade_percentual?: number | null
          adicional_noturno?: boolean | null
          assistencia_medica?: boolean | null
          cesta?: boolean | null
          cliente_id?: number | null
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
          acumulo_funcao?: boolean | null
          acumulo_funcao_percentual?: number | null
          adc_insalubridade_percentual?: number | null
          adicional_noturno?: boolean | null
          assistencia_medica?: boolean | null
          cesta?: boolean | null
          cliente_id?: number | null
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
          _role: Database["public"]["Enums"]["internal_access_level"]
          _user_id: string
        }
        Returns: boolean
      }
      is_admin: { Args: { _user_id: string }; Returns: boolean }
      limpar_diarias_antigas: { Args: never; Returns: undefined }
      limpar_diarias_temporarias_antigas: { Args: never; Returns: undefined }
      limpar_posto_dias_vagos_antigos: { Args: never; Returns: undefined }
      limpar_presencas_antigas: { Args: never; Returns: undefined }
      limpar_tokens_expirados: { Args: never; Returns: undefined }
      processar_movimentacoes_agendadas: { Args: never; Returns: undefined }
    }
    Enums: {
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
      motivo_contratacao:
        | "Substituição efetivo"
        | "Substituição férias licença"
        | "Implantação/Abertura de novo contrato"
        | "Solicitação do cliente"
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
      sexualidade: "Masculino" | "Feminino" | "Indiferente"
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
      ],
      motivo_contratacao: [
        "Substituição efetivo",
        "Substituição férias licença",
        "Implantação/Abertura de novo contrato",
        "Solicitação do cliente",
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
      sexualidade: ["Masculino", "Feminino", "Indiferente"],
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
