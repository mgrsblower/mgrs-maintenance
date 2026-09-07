# Remote rollout evidence — 7 September 2026

Target: Supabase project `MGRS-Dashboard` (`ztindtxlbkgykyasgpnd`), confirmed by `supabase projects list` as linked and healthy. The user identified this target as non-production and authorized the migration and scheduler activation.

## Applied

- `20260907000100_maintenance_api.sql`, SHA-256 `a41bd84a2f4ec3da3de93da2a96d4b1ed6c87763dc043286354561abede90e2e`.
- `20260907000200_maintenance_history.sql`, SHA-256 `98447095a8e999d47d5ce608c35b8a44757ab8cd37b36ec69b7fc7856001bc6b`.
- Migration history repaired to `applied` for those two versions only.
- `pg_cron` enabled and one active job created: `mgrs-maintenance-generate-periods`, schedule `*/15 * * * *`, job ID 1.
- Maintenance activation recorded at `2026-09-07 04:46:02.876066+00`.

The local baseline `20260906000100_maintenance_baseline.sql` and `supabase/seed.sql` were not applied.

## Post-deployment verification

- Master components: 60.
- Active membership snapshot: 60.
- Maintenance events: 0.
- Periods/tasks: 0/0, expected because the fourth Saturday after activation has not opened yet.
- RPC smoke with an existing active Admin profile: component lookup returned one exact match; detail type was valid; history returned a valid list; `current` resolved to the WIB server month.
- `anon` has no execute permission on `maintenance_submit`; `authenticated` has execute permission and the RPC performs its own active-role check.
- Remote migration history contains both additive versions.

Only two active Admin profiles currently exist. There are no Tim Service, Tim Pemasangan, PIC, or inactive profiles available for remote role smoke testing. The attempted PIC-context probe therefore resolved to an empty subject and correctly failed as `unauthenticated`; role-specific QA still requires creating or assigning non-production test accounts.

No component condition, usage status, history row, or maintenance event was written during rollout verification.
