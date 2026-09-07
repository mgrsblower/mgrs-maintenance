-- MANUAL ADMINISTRATION ONLY. Review target and QA evidence before execution.
-- In the same approved SQL session, explicitly run:
-- SET mgrs.maintenance_deploy_approved = 'yes';
begin;
do $$
begin
 if coalesce(current_setting('mgrs.maintenance_deploy_approved',true),'') <> 'yes' then
  raise exception 'Explicit target deployment approval flag required';
 end if;
 if not exists(select 1 from pg_extension where extname='pg_cron') then
  raise exception 'Enable Supabase Cron before activation';
 end if;
 if to_regprocedure('maintenance_private.generate_periods(timestamp with time zone)') is null then
  raise exception 'Maintenance API migration missing';
 end if;
 if not exists(select 1 from maintenance_private.settings) then
  perform maintenance_private.activate(clock_timestamp());
 end if;
end $$;
select cron.schedule(
 'mgrs-maintenance-generate-periods',
 '*/15 * * * *',
 $job$select maintenance_private.generate_periods();$job$
);
select maintenance_private.generate_periods();
commit;
