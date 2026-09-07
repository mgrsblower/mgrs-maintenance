# Task 3 baseline report

**Date:** 6 September 2026  
**Status:** created; execution pending a local database runtime

## Scope and safety boundary

`supabase/migrations/20260906000100_maintenance_baseline.sql` is a **LOCAL BOOTSTRAP ONLY** schema for a new Supabase-local database. It must never be applied to the existing linked project, QA, or production. It creates no production RPC, trigger, scheduler, or database mutation beyond the isolated local bootstrap.

The baseline intentionally does not create or redefine `auth` schemas, `auth.users`, `auth.uid()`, or Supabase roles. Those are supplied by Supabase local. The only new helper is `private.current_user_has_role(text[])`, copied from the live read-only helper contract and retaining its `is_active = true` check.

## Contract basis

- `docs/contracts/schema-manifest.json`, live read-only metadata captured 6 September 2026.
- `docs/contracts/database-constraints.json`, live primary, foreign-key, unique, and check constraints.
- `docs/contracts/role-helper.json`, audited helper definition.
- Read-only legacy references: `C:\Users\ogi\Documents\MGRS\supabase\schema.sql` and `C:\Users\ogi\Documents\MGRS\supabase\migrations\20260714104752_harden_role_policies_and_public_rate_limit.sql`.

The local baseline covers only `profiles`, `master_komponen`, `riwayat_checking_komponen`, `riwayat_service`, and `audit_log`. It preserves the audited component enums, profile FK cascade, component uniqueness, history/profile foreign keys, RLS policy shape, and active-role semantics. The four non-profile tables retain the audited `anon`, `authenticated`, and `service_role` table grants; RLS is the authorization boundary.

## Synthetic fixtures

`supabase/seed.sql` inserts five deterministic UUID users with invalid-domain fixture emails and no password values: Admin, PIC Pemasangan, Tim Pemasangan, Tim Service, and one inactive Tim Service profile. It also inserts one component of each kind: Kepala, Batang, and Tabung. No real credentials or production data are used.

## Test artifact and execution result

`supabase/tests/database/001_baseline.test.sql` is a pgTAP transaction test. It verifies the extension, five tables, private helper, RLS, policy counts, fixtures, component kinds, and that inactive users fail the helper check. The test ends with `rollback`.

The intended command is:

```powershell
supabase test db supabase/tests/database/001_baseline.test.sql
```

It was **not run** in this task because Docker/local Supabase startup was unavailable at the time of implementation. No test success is claimed. G0 remains unresolved; no production RPC, production migration, operational write path, or schedule has been created.
