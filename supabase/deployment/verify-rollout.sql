-- Read-only owner checks after the separately approved rollout.
begin read only;
select activation_at from maintenance_private.settings;
select id, opens_at at time zone 'Asia/Jakarta' as opens_wib,
 closes_at at time zone 'Asia/Jakarta' as closes_wib, generated_at
from public.maintenance_periods order by id desc limit 3;
select period_id,count(*) as targets,count(completed_at) as completed
from public.maintenance_tasks group by period_id order by period_id desc limit 3;
select jobid,jobname,schedule,active from cron.job
where jobname='mgrs-maintenance-generate-periods';
select d.status,d.start_time,d.end_time,d.return_message
from cron.job_run_details d join cron.job j using(jobid)
where j.jobname='mgrs-maintenance-generate-periods'
order by d.start_time desc limit 5;
rollback;
