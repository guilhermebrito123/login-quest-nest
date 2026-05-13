CREATE OR REPLACE FUNCTION public.rpc_desvincular_colaborador_convenia(p_colaborador_convenia_id uuid, p_data_fim date, p_motivo text, p_usuario_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare v_alocacao_atual public.colaboradores_convenia_alocacoes%rowtype; v_registro_novo jsonb;
begin
  perform set_config('app.skip_alocacao_trigger','true',true);
  select * into v_alocacao_atual from public.colaboradores_convenia_alocacoes where colaborador_convenia_id = p_colaborador_convenia_id and ativo = true for update;
  if not found then raise exception 'Colaborador não possui alocação ativa.'; end if;
  update public.colaboradores_convenia_alocacoes
    set ativo = false, data_fim = coalesce(p_data_fim, current_date), observacao = p_motivo, updated_by = p_usuario_id
    where id = v_alocacao_atual.id;
  select to_jsonb(a) into v_registro_novo from public.colaboradores_convenia_alocacoes a where a.id = v_alocacao_atual.id;
  insert into public.colaboradores_convenia_alocacoes_historico (
    colaborador_convenia_id, alocacao_id, posto_servico_id_anterior, posto_servico_id_novo,
    horario_entrada_anterior, horario_entrada_novo, horario_saida_anterior, horario_saida_novo,
    paridade_12x36_anterior, paridade_12x36_nova,
    operacao, motivo, registro_anterior, registro_novo, created_by
  ) values (
    p_colaborador_convenia_id, v_alocacao_atual.id,
    v_alocacao_atual.posto_servico_id, null,
    v_alocacao_atual.horario_entrada, null,
    v_alocacao_atual.horario_saida, null,
    v_alocacao_atual.paridade_12x36, null,
    'desvinculacao', p_motivo, to_jsonb(v_alocacao_atual), v_registro_novo, p_usuario_id
  );
  return v_alocacao_atual.id;
end;
$function$;