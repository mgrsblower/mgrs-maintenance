# Maintenance rollout (manual only)

The two additive migrations and scheduler activation were applied on 7 September 2026 to the user-authorized non-production `MGRS-Dashboard` target. See `docs/evidence/remote-rollout-2026-09-07.md` for exact checksums and verification. The local baseline and auth shim remain development fixtures and were not deployed.

## Sequence

1. Use a dedicated QA copy of the existing MGRS database. Verify the existing schema against `docs/contracts/schema-manifest.json`; include legacy callers in compatibility QA. Use synthetic QA users for Admin, Tim Service, Tim Pemasangan, denied PIC, and inactive profiles.
2. Back up the target and retain the verified previous application release. Review only `20260907000100_maintenance_api.sql` and `20260907000200_maintenance_history.sql`. Apply those two files in order, each using a transaction and stop-on-error. **Never run the `20260906000100` baseline, seed, generic `supabase db push`, or reset against the existing database.** This repo contains a local bootstrap which generic migration deployment could include accidentally.
3. Verify real Supabase Auth and PostgREST: allowed and denied roles, atomic rollback, uncertain retry, stale version rejection, history, and scanner on a physical device. Native PostgreSQL harness results do not establish this API/auth gate.
4. After deployment approval for the exact target, enable the Supabase Cron extension (`pg_cron`) with its normal administration workflow. Run `activate-and-schedule.sql` as the database owner in one session after setting the explicit session approval flag shown in that file. This creates the activation cutoff at execution time and a named job every 15 minutes. Tasks materialize only once the fourth Saturday starts in Asia/Jakarta. The rest of the weekend ends Monday 00:00 WIB. Catch-up reconstructs component membership at the period opening; activation never invents older periods.
5. Inspect `verify-rollout.sql`. Check the cron job result after its first execution and after the first due cutoff. A current period with no generated snapshot must appear as unavailable in the app, not as a completed month.
6. Roll out the app only after QA gates pass. If rollback is needed, stop the named cron job and revert the application release. Preserve maintenance events, task completion, legacy history, and audit rows; do not delete tables or undo user data as an automatic rollback.

## Shared writer limitation

The new maintenance RPC locks the component row, compares its full-row version, and writes the condition, legacy history, event receipt, audit, and periodic completion in one transaction. Replays are scoped to actor/request UUID and require the identical payload. Usage and installation fields are never mutated.

Legacy MGRS clients still perform unconditional writes. A legacy write before the new command is detected by its stale version; a legacy write after the new transaction can still overwrite the new condition. End-to-end CAS across all applications requires migrating those legacy writers separately. No deployment script here revokes their existing table grants or changes their flows.

Service cost is unknown in the new API (`costRecorded=false`, `cost=null`). The legacy nonnullable numeric field retains its default zero and receives the explicit note `Biaya belum dicatat`. Legacy consumers may still display that compatibility zero without understanding the new metadata.

The additive API and history migrations are covered by the native PostgreSQL harness. Cron extension installation and execution require the QA/Supabase environment and have not been verified by that harness.

## Local evidence (2026-09-07)

Command: `node tools/db-harness/verify-baseline.mjs --maintenance`

Working directory: `C:/Users/ogi/MGRS-Maintenance`. Exit code: 0. Native PostgreSQL 17.10 returned PASS for 63 maintenance assertions and 7 baseline smoke assertions. The disposable database was dropped and its task-owned server stopped by the harness.

Coverage includes allowed/denied roles via an auth shim; stable replay and payload mismatch; stale versions; two-client concurrent replay; audit failure rollback; unchanged usage; explicit unknown service cost; fourth-Saturday calculations; generator idempotency; server-month lookup; null and malformed field rejection; periodic missing, early, late, timely, unavailable and already-completed cases; event-only corrections and same-component validation; actor-scoped receipt lookup; legacy placeholder normalization; history de-duplication and cursor pagination; and task pagination.

Not covered: production or QA Supabase Auth/PostgREST, extension installation, cron execution, or legacy clients writing concurrently after a new RPC. The activation SQL is a reviewed operator artifact, not evidence of deployment.
