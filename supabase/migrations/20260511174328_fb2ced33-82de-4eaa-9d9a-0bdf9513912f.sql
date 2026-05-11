drop view if exists public.v_colaboradores_convenia_alocacao_atual;

create view public.v_colaboradores_convenia_alocacao_atual as
select
  a.id as alocacao_id,

  c.id as colaborador_convenia_id,
  c.convenia_id,
  concat_ws(' ', c.name, c.last_name) as nome_colaborador,
  c.cpf,
  c.email,
  c.personal_email,
  c.registration,
  c.job_name,
  c.status as status_convenia,
  c.cost_center_id as colaborador_cost_center_id,
  c.cost_center_name as colaborador_cost_center_name,

  p.id as posto_servico_id,
  p.nome as posto_servico_nome,
  p.escala,
  p.dias_semana,
  p.turno,
  p.cliente_id,
  p.unidade_id,
  p.cost_center_id as posto_cost_center_id,

  cc.name as posto_cost_center_name,

  a.horario_entrada,
  a.horario_saida,
  a.intervalo_minutos,
  a.paridade_12x36,

  a.data_inicio,
  a.data_fim,
  a.ativo,

  a.observacao,

  a.created_at,
  a.created_by,
  a.updated_at,
  a.updated_by

from public.colaboradores_convenia_alocacoes a
join public.colaboradores_convenia c
  on c.id = a.colaborador_convenia_id
join public.postos_servico p
  on p.id = a.posto_servico_id
left join public.cost_center cc
  on cc.id = p.cost_center_id
where a.ativo = true;

grant select on public.v_colaboradores_convenia_alocacao_atual to authenticated;

alter view public.v_colaboradores_convenia_alocacao_atual set (security_invoker = true);