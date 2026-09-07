-- Additive maintenance API. Deploy only after review; never apply the local bootstrap to production.
create schema if not exists maintenance_private;
revoke all on schema maintenance_private from public, anon, authenticated;

create table public.maintenance_events (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid not null,
  request_id uuid not null,
  command jsonb not null,
  component_id uuid not null,
  activity text not null check (activity in ('manual_check','periodic_check','service')),
  before_value jsonb not null,
  after_value jsonb not null,
  recorded_at timestamptz not null default clock_timestamp(),
  legacy_id uuid not null,
  cost_recorded boolean not null default false,
  receipt jsonb not null,
  unique(actor_id,request_id)
);
alter table public.maintenance_events enable row level security;
revoke all on public.maintenance_events from public, anon, authenticated;
create index maintenance_events_component_time on public.maintenance_events(component_id,recorded_at desc,id desc);

create function maintenance_private.actor() returns uuid
language plpgsql security definer set search_path='' as $$
declare actor uuid := auth.uid();
begin
  if actor is null then raise exception 'unauthenticated'; end if;
  if not exists(select 1 from public.profiles where id=actor and is_active and role in ('Admin','Tim Service','Tim Pemasangan')) then raise exception 'forbidden'; end if;
  return actor;
end $$;

create function maintenance_private.component_json(c public.master_komponen) returns jsonb
language sql stable set search_path='' as $$
select jsonb_build_object('id',c.id,'code',c.nomor_stiker,'kind',c.jenis_komponen,
 'condition',c.kondisi,'usable',c.boleh_dipakai,'impairedFunction',c.fungsi_terganggu,
 'note',nullif(nullif(btrim(c.keterangan),''),'-'),'version',md5(to_jsonb(c)::text),
 'lastCheckingAt',(select max(timestamp) from public.riwayat_checking_komponen where nomor_stiker=c.nomor_stiker),
 'lastServiceAt',(select max(timestamp) from public.riwayat_service where nomor_stiker=c.nomor_stiker))
$$;

create function public.maintenance_lookup_component(p_code text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 perform maintenance_private.actor();
 if p_code is null or length(btrim(p_code)) not between 1 and 120 then raise exception 'invalid_input'; end if;
 select coalesce(jsonb_agg(maintenance_private.component_json(c)),'[]'::jsonb) into result
 from (select * from public.master_komponen where nomor_stiker=btrim(p_code) or komponen_id=btrim(p_code) order by id limit 2)c;
 return result;
end $$;

create function public.maintenance_get_component(p_component_id text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare c public.master_komponen;
begin
 perform maintenance_private.actor();
 select * into c from public.master_komponen where id::text=p_component_id;
 if not found then raise exception 'not_found'; end if;
 return maintenance_private.component_json(c);
end $$;

create function public.maintenance_request_result(p_request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid:=maintenance_private.actor(); result jsonb;
begin
 select receipt into result from public.maintenance_events where actor_id=actor and request_id=p_request_id;
 return result;
end $$;

create table public.maintenance_periods (
 id text primary key check(id ~ '^[0-9]{4}-(0[1-9]|1[0-2])$'),
 opens_at timestamptz not null, closes_at timestamptz not null,
 generated_at timestamptz not null default clock_timestamp(),
 check(closes_at>opens_at)
);
create table public.maintenance_tasks (
 id uuid primary key default gen_random_uuid(), period_id text not null references public.maintenance_periods(id),
 component_id uuid not null, code text not null, kind text not null,
 completed_event_id uuid unique references public.maintenance_events(id), completed_at timestamptz,
 unique(period_id,component_id), check((completed_event_id is null)=(completed_at is null))
);
create table maintenance_private.settings (singleton boolean primary key default true check(singleton),activation_at timestamptz not null);
-- Activation is set during rollout, not implicitly by installing this migration.
create table maintenance_private.membership (
 id bigint generated always as identity primary key, component_id uuid not null, code text not null,
 kind text not null, present boolean not null, effective_at timestamptz not null default clock_timestamp()
);
create index maintenance_membership_component_time on maintenance_private.membership(component_id,effective_at desc,id desc);
alter table public.maintenance_periods enable row level security;
alter table public.maintenance_tasks enable row level security;
revoke all on public.maintenance_periods,public.maintenance_tasks from public,anon,authenticated;

create function maintenance_private.capture_membership() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if tg_op='DELETE' then
  insert into maintenance_private.membership(component_id,code,kind,present) values(old.id,old.nomor_stiker,old.jenis_komponen,false);
  return old;
 end if;
 if tg_op='INSERT' or new.nomor_stiker is distinct from old.nomor_stiker or new.jenis_komponen is distinct from old.jenis_komponen then
  insert into maintenance_private.membership(component_id,code,kind,present) values(new.id,new.nomor_stiker,new.jenis_komponen,true);
 end if;
 return new;
end $$;
create trigger maintenance_membership_change after insert or delete or update on public.master_komponen
for each row execute function maintenance_private.capture_membership();

create function maintenance_private.fourth_saturday(p_month date) returns date
language sql immutable strict set search_path='' as $$
 select date_trunc('month',p_month)::date + ((6-extract(dow from date_trunc('month',p_month))::integer+7)%7)+21
$$;

create function maintenance_private.activate(p_at timestamptz) returns void
language plpgsql security definer set search_path='' as $$
begin
 if p_at < clock_timestamp()-interval '1 minute' then raise exception 'invalid_activation'; end if;
 lock table public.master_komponen in share mode;
 if exists(select 1 from maintenance_private.settings) then raise exception 'already_activated'; end if;
 insert into maintenance_private.settings values(true,p_at);
 insert into maintenance_private.membership(component_id,code,kind,present,effective_at)
 select id,nomor_stiker,jenis_komponen,true,clock_timestamp() from public.master_komponen;
end $$;

create function maintenance_private.generate_periods(p_now timestamptz default clock_timestamp()) returns integer
language plpgsql security definer set search_path='' as $$
declare activation timestamptz; month_start date; sat date; opening timestamptz; period text; created integer:=0;
begin
 perform pg_advisory_xact_lock(714029);
 select activation_at into activation from maintenance_private.settings;
 if activation is null then return 0; end if;
 -- Wait for identity mutations before reconstructing the registry cutoff.
 lock table public.master_komponen in share mode;
 month_start:=date_trunc('month',activation at time zone 'Asia/Jakarta')::date;
 while month_start<=date_trunc('month',p_now at time zone 'Asia/Jakarta')::date loop
  sat:=maintenance_private.fourth_saturday(month_start);
  opening:=sat::timestamp at time zone 'Asia/Jakarta'; period:=to_char(month_start,'YYYY-MM');
  if opening>=activation and opening<=p_now and not exists(select 1 from public.maintenance_periods where id=period) then
   insert into public.maintenance_periods(id,opens_at,closes_at) values(period,opening,(sat+2)::timestamp at time zone 'Asia/Jakarta');
   insert into public.maintenance_tasks(period_id,component_id,code,kind)
   select period,component_id,code,kind from
    (select distinct on(component_id) component_id,code,kind,present from maintenance_private.membership where effective_at<=opening order by component_id,effective_at desc,id desc)m where present;
   created:=created+1;
  end if;
  month_start:=(month_start+interval '1 month')::date;
 end loop;
 return created;
end $$;

create function public.maintenance_submit(p_command jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid:=maintenance_private.actor(); req uuid; c public.master_komponen; e public.maintenance_events;
 task public.maintenance_tasks; period public.maintenance_periods; event_id uuid:=gen_random_uuid(); legacy uuid:=gen_random_uuid();
 activity text; condition text; usable text; impaired text; note text; summary text; problem text; action text;
 before_value jsonb; after_value jsonb; receipt jsonb; at_time timestamptz:=clock_timestamp(); corrected uuid;
begin
 if p_command is null or jsonb_typeof(p_command)<>'object' then raise exception 'invalid_input'; end if;
 begin req:=(p_command->>'requestId')::uuid; exception when invalid_text_representation then raise exception 'invalid_input'; end;
 if req is null then raise exception 'invalid_input'; end if;
 perform pg_advisory_xact_lock(hashtextextended(actor::text||req::text,0));
 select * into e from public.maintenance_events where actor_id=actor and request_id=req;
 if found then
  if e.command<>p_command then raise exception 'request_mismatch'; end if;
  return e.receipt;
 end if;
 if exists(select 1 from jsonb_object_keys(p_command) k where k not in ('requestId','componentId','expectedVersion','activity','condition','usable','impairedFunction','eventNote','summaryAction','summaryText','taskId','problem','action','correctsEventId','correctionReason')) then raise exception 'invalid_input'; end if;
 if exists(select 1 from jsonb_each(p_command) where jsonb_typeof(value) not in ('string','null')) then raise exception 'invalid_input'; end if;
 select * into c from public.master_komponen where id::text=p_command->>'componentId' for update;
 if not found then raise exception 'not_found'; end if;
 if p_command->>'expectedVersion' is distinct from md5(to_jsonb(c)::text) then raise exception 'conflict'; end if;
 activity:=p_command->>'activity'; condition:=p_command->>'condition'; usable:=p_command->>'usable';
 impaired:=btrim(coalesce(p_command->>'impairedFunction','')); note:=btrim(coalesce(p_command->>'eventNote',''));
 problem:=btrim(coalesce(p_command->>'problem','')); action:=btrim(coalesce(p_command->>'action',''));
 if activity is null or activity not in ('manual_check','periodic_check','service') or condition is null or condition not in ('OK','Rusak Ringan','Rusak Berat','Service','Hilang') or usable is null or usable not in ('Ya','Tidak') then raise exception 'invalid_input'; end if;
 if length(note)>2000 or length(impaired)>500 or length(problem)>2000 or length(action)>2000 then raise exception 'invalid_input'; end if;
 if condition in ('Rusak Berat','Service','Hilang') and usable='Ya' then raise exception 'invalid_input'; end if;
 if condition<>'OK' and (impaired='' or note='') then raise exception 'invalid_input'; end if;
 if condition='OK' then impaired:='Tidak Ada'; end if;
 if activity='service' and (problem='' or action='' or p_command->>'taskId' is not null) then raise exception 'invalid_input'; end if;
 if activity<>'service' and (problem<>'' or action<>'') then raise exception 'invalid_input'; end if;
 if activity='manual_check' and p_command->>'taskId' is not null then raise exception 'invalid_input'; end if;
 if (p_command->>'correctsEventId' is null)<>(p_command->>'correctionReason' is null) then raise exception 'invalid_input'; end if;
 if p_command->>'correctsEventId' is not null then
  if length(btrim(p_command->>'correctionReason')) not between 1 and 2000 then raise exception 'invalid_input'; end if;
  select id into corrected from public.maintenance_events where id::text=p_command->>'correctsEventId' and component_id=c.id;
  if not found then raise exception 'invalid_input'; end if;
 end if;
 if p_command->>'summaryAction'<>'replace' and p_command->>'summaryText' is not null then raise exception 'invalid_input'; end if;
 summary:=c.keterangan;
 case p_command->>'summaryAction'
  when 'keep' then null;
  when 'clear' then summary:=null;
  when 'replace' then
   summary:=btrim(coalesce(p_command->>'summaryText',''));
   if summary='' or length(summary)>2000 then raise exception 'invalid_input'; end if;
  else raise exception 'invalid_input';
 end case;
 if activity='periodic_check' then
  select * into task from public.maintenance_tasks where id::text=p_command->>'taskId' and component_id=c.id for update;
  if not found then raise exception 'not_found'; end if;
  select * into period from public.maintenance_periods where id=task.period_id;
  at_time:=clock_timestamp();
  if at_time<period.opens_at then raise exception 'task_not_open'; end if;
  if task.completed_event_id is not null then raise exception 'task_already_completed'; end if;
  if condition='Hilang' then raise exception 'component_unavailable'; end if;
 end if;
 at_time:=clock_timestamp();
 before_value:=maintenance_private.component_json(c);
 if activity='service' then
  insert into public.riwayat_service(id,nomor_stiker,jenis_komponen,masalah,tindakan_service,teknisi,hasil_kondisi,boleh_dipakai,fungsi_terganggu,catatan,timestamp)
  values(legacy,c.nomor_stiker,c.jenis_komponen,problem,action,actor,condition,usable,impaired,concat_ws(chr(10),nullif(note,''),'Biaya belum dicatat'),at_time);
 else
  insert into public.riwayat_checking_komponen(id,nomor_stiker,jenis_komponen,kondisi_terbaru,boleh_dipakai,fungsi_terganggu,catatan,petugas,tanggal_checking,timestamp)
  values(legacy,c.nomor_stiker,c.jenis_komponen,condition,usable,impaired,nullif(note,''),actor,(at_time at time zone 'Asia/Jakarta')::date,at_time);
 end if;
 update public.master_komponen set kondisi=condition,boleh_dipakai=usable,fungsi_terganggu=impaired,keterangan=summary,updated_by=actor,updated_at=at_time where id=c.id returning * into c;
 after_value:=maintenance_private.component_json(c);
 receipt:=jsonb_build_object('eventId',event_id,'requestId',req,'componentId',c.id,'version',after_value->>'version','recordedAt',at_time,'completedTaskId',task.id);
 insert into public.maintenance_events(id,actor_id,request_id,command,component_id,activity,before_value,after_value,recorded_at,legacy_id,receipt)
 values(event_id,actor,req,p_command,c.id,activity,before_value,after_value,at_time,legacy,receipt);
 insert into public.audit_log(action,entity_type,entity_id,old_value,new_value,user_id,timestamp)
 values('maintenance.'||activity,'master_komponen',c.id::text,before_value,after_value,actor,at_time);
 if task.id is not null then update public.maintenance_tasks set completed_event_id=event_id,completed_at=at_time where id=task.id; end if;
 return receipt;
end $$;

create function public.maintenance_list_tasks(p_period_id text,p_kind text default null,p_status text default null,p_code text default null,p_cursor text default null,p_limit integer default 30) returns jsonb
language plpgsql security definer set search_path='' as $$
declare period public.maintenance_periods; result jsonb; server_now timestamptz:=clock_timestamp(); start_date date;
begin
 perform maintenance_private.actor();
 if p_period_id='current' then p_period_id:=to_char(server_now at time zone 'Asia/Jakarta','YYYY-MM'); end if;
 if (p_kind is not null and p_kind not in ('Kepala','Batang','Tabung'))
 or (p_status is not null and p_status not in ('scheduled','due','overdue','completed','completed_late'))
 or (p_code is not null and length(p_code)>120)
 or (p_cursor is not null and p_cursor !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') then raise exception 'invalid_input'; end if;
 if p_period_id is null or p_period_id !~ '^[0-9]{4}-(0[1-9]|1[0-2])$' or p_limit is null or p_limit not between 1 and 100 then raise exception 'invalid_input'; end if;
 select * into period from public.maintenance_periods where id=p_period_id;
 if not found then
  start_date:=maintenance_private.fourth_saturday((p_period_id||'-01')::date);
  return jsonb_build_object('period',jsonb_build_object('id',p_period_id,'opensAt',start_date::timestamp at time zone 'Asia/Jakarta','closesAt',(start_date+2)::timestamp at time zone 'Asia/Jakarta','serverNow',server_now,'snapshotState',case when server_now<start_date::timestamp at time zone 'Asia/Jakarta' then 'preview' else 'not_generated' end),'items','[]'::jsonb,'total',0,'completed',0,'nextCursor',null);
 end if;
 with all_tasks as (
  select t.*,case when completed_at is not null then case when completed_at<period.closes_at then 'completed' else 'completed_late' end
   when server_now<period.opens_at then 'scheduled' when server_now>=period.closes_at then 'overdue' else 'due' end as state
  from public.maintenance_tasks t where period_id=p_period_id
 ), filtered as (
  select * from all_tasks where (p_kind is null or kind=p_kind) and (p_status is null or state=p_status)
   and (p_code is null or position(lower(p_code) in lower(code))>0)
 ), page as (
  select * from filtered where p_cursor is null or id::text>p_cursor order by id limit p_limit+1
 ), shown as (select * from page order by id limit p_limit)
 select jsonb_build_object('period',jsonb_build_object('id',period.id,'opensAt',period.opens_at,'closesAt',period.closes_at,'serverNow',server_now,'snapshotState','ready'),
 'total',(select count(*) from filtered),'completed',(select count(*) from filtered where completed_at is not null),
 'items',coalesce((select jsonb_agg(jsonb_build_object('id',id,'periodId',period_id,'componentId',component_id,'code',code,'kind',kind,'status',state,'completedAt',completed_at,'completedEventId',completed_event_id) order by id) from shown),'[]'::jsonb),
 'nextCursor',case when (select count(*) from page)>p_limit then (select id::text from shown order by id desc limit 1) else null end) into result;
 return result;
end $$;

revoke all on all functions in schema maintenance_private from public,anon,authenticated;
revoke all on function public.maintenance_lookup_component(text),public.maintenance_get_component(text),public.maintenance_request_result(uuid),public.maintenance_submit(jsonb),public.maintenance_list_tasks(text,text,text,text,text,integer) from public,anon;
grant execute on function public.maintenance_lookup_component(text),public.maintenance_get_component(text),public.maintenance_request_result(uuid),public.maintenance_submit(jsonb),public.maintenance_list_tasks(text,text,text,text,text,integer) to authenticated;
