create view maintenance_private.history_rows as
select e.id::text as event_id,e.component_id::text as component_id,e.activity,e.recorded_at,
 jsonb_build_object('eventId',e.id,'componentId',e.component_id,'code',e.after_value->>'code','kind',e.after_value->>'kind','activity',e.activity,'before',e.before_value,'after',e.after_value,
 'actor',coalesce(p.full_name,p.username,'Petugas'),'recordedAt',e.recorded_at,'note',e.command->>'eventNote','problem',e.command->>'problem','action',e.command->>'action',
 'correctsEventId',e.command->>'correctsEventId','correctionReason',e.command->>'correctionReason','periodId',t.period_id,'costRecorded',e.cost_recorded,'cost',null,'legacy',false) as payload
from public.maintenance_events e left join public.profiles p on p.id=e.actor_id left join public.maintenance_tasks t on t.completed_event_id=e.id
union all
select 'checking:'||h.id,c.id::text,'manual_check',h.timestamp,
 jsonb_build_object('eventId','checking:'||h.id,'componentId',c.id,'code',h.nomor_stiker,'kind',h.jenis_komponen,'activity','manual_check','before',null,
 'after',jsonb_build_object('condition',h.kondisi_terbaru,'usable',h.boleh_dipakai,'impairedFunction',nullif(nullif(btrim(h.fungsi_terganggu),''),'-')),
 'actor',coalesce(p.full_name,p.username,'Tidak tercatat'),'recordedAt',h.timestamp,'note',nullif(nullif(btrim(h.catatan),''),'-'),'legacy',true,'identityVerified',false)
from public.riwayat_checking_komponen h left join public.master_komponen c on c.nomor_stiker=h.nomor_stiker left join public.profiles p on p.id=h.petugas
where not exists(select 1 from public.maintenance_events e where e.legacy_id=h.id and e.activity<>'service')
union all
select 'service:'||h.id,c.id::text,'service',h.timestamp,
 jsonb_build_object('eventId','service:'||h.id,'componentId',c.id,'code',h.nomor_stiker,'kind',h.jenis_komponen,'activity','service','before',null,
 'after',jsonb_build_object('condition',h.hasil_kondisi,'usable',h.boleh_dipakai,'impairedFunction',nullif(nullif(btrim(h.fungsi_terganggu),''),'-')),
 'actor',coalesce(p.full_name,p.username,'Tidak tercatat'),'recordedAt',h.timestamp,'note',nullif(nullif(btrim(h.catatan),''),'-'),'problem',nullif(nullif(btrim(h.masalah),''),'-'),'action',nullif(nullif(btrim(h.tindakan_service),''),'-'),
 'cost',h.biaya_service,'costRecorded',null,'legacy',true,'identityVerified',false)
from public.riwayat_service h left join public.master_komponen c on c.nomor_stiker=h.nomor_stiker left join public.profiles p on p.id=h.teknisi
where not exists(select 1 from public.maintenance_events e where e.legacy_id=h.id and e.activity='service');
revoke all on maintenance_private.history_rows from public,anon,authenticated;

create function public.maintenance_list_history(p_component_id text default null,p_activity text default null,p_from timestamptz default null,p_until timestamptz default null,p_cursor text default null,p_limit integer default 30) returns jsonb
language plpgsql security definer set search_path='' as $$
declare result jsonb; cursor_at timestamptz; cursor_id text;
begin
 perform maintenance_private.actor();
 if p_limit is null or p_limit not between 1 and 100 or (p_activity is not null and p_activity not in ('manual_check','periodic_check','service')) or (p_from is not null and p_until is not null and p_from>=p_until) then raise exception 'invalid_input'; end if;
 if p_cursor is not null then
  begin cursor_at:=(p_cursor::jsonb->>'at')::timestamptz; cursor_id:=p_cursor::jsonb->>'id'; exception when others then raise exception 'invalid_input'; end;
  if cursor_at is null or cursor_id is null or length(cursor_id) not between 1 and 100 or not isfinite(cursor_at) then raise exception 'invalid_input'; end if;
 end if;
 with page as (
  select * from maintenance_private.history_rows where (p_component_id is null or component_id=p_component_id) and (p_activity is null or activity=p_activity)
  and (p_from is null or recorded_at>=p_from) and (p_until is null or recorded_at<p_until)
  and (p_cursor is null or (recorded_at,event_id)<(cursor_at,cursor_id)) order by recorded_at desc,event_id desc limit p_limit+1
 ), shown as (select * from page order by recorded_at desc,event_id desc limit p_limit)
 select jsonb_build_object('items',coalesce((select jsonb_agg(payload order by recorded_at desc,event_id desc) from shown),'[]'::jsonb),
 'nextCursor',case when (select count(*) from page)>p_limit then (select jsonb_build_object('at',recorded_at,'id',event_id)::text from shown order by recorded_at,event_id limit 1) else null end) into result;
 return result;
end $$;

create function public.maintenance_get_history(p_event_id text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 perform maintenance_private.actor();
 select payload into result from maintenance_private.history_rows where event_id=p_event_id;
 if result is null then raise exception 'not_found'; end if;
 return result;
end $$;
revoke all on function public.maintenance_list_history(text,text,timestamptz,timestamptz,text,integer),public.maintenance_get_history(text) from public,anon;
grant execute on function public.maintenance_list_history(text,text,timestamptz,timestamptz,text,integer),public.maintenance_get_history(text) to authenticated;
