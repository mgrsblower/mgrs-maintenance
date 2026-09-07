# Implementation ledger

Workspace: C:\Users\ogi\MGRS-Maintenance
Branch: codex/maintenance-mvp
Updated: 7 September 2026

## Current state

- Task 1: Android-first Flutter baseline recorded. Physical pilot device, signing, and distribution remain release prerequisites.
- Task 2: live read-only schema, policies, helper and constraint audit complete; compatibility interpretation recorded in decisions/002-shared-database.md.
- Task 3: disposable PostgreSQL 17.10 baseline and synthetic fixtures complete. Supabase Auth/API and pgTAP remain unverified.
- Tasks 4–6: lookup/detail, atomic condition/service writes, event ledger, history adapter, monthly periods, frozen tasks, and deployment scripts implemented and locally verified.
- Tasks 7–12: Android app implemented with protected login, manual scan fallback, component detail, reviewed checking/service forms, stable request recovery, monthly task list, combined history, and append-only correction.
- Task 13: emulator integration flow passed with synthetic QA gateway. Physical camera/barcode, real QA accounts, legacy-client interoperability, and performance sampling remain open.
- Task 14: the additive migrations and scheduler are deployed to the user-authorized non-production `MGRS-Dashboard` target. Release signing and distribution have not run; see `remote-rollout-2026-09-07.md`.

## Verified commands

- `flutter --version`: Flutter 3.44.8 / Dart 3.12.2.
- `npx --yes supabase --version`: 2.109.1.
- `supabase db query --linked` with explicit read-only SQL: source metadata verified against MGRS-Dashboard. 60 components (20 of each kind), zero duplicate stickers, no custom triggers on maintenance tables.
- `node tools/db-harness/verify-baseline.mjs`: PASS, seven baseline assertions against a disposable native PostgreSQL database. Server stopped and disposable database removed afterward.
- `node tools/db-harness/verify-baseline.mjs --maintenance`: PASS, 63 maintenance assertions plus seven baseline assertions. This includes rollback, concurrency, idempotency, CAS, schedule boundaries, periodic completion, correction, history de-duplication, actor isolation, and pagination.
- `flutter analyze`: no issues.
- `flutter test`: three tests passed, including lost-response recovery with the same immutable request.
- `flutter drive --driver integration_test/driver.dart --target integration_test/app_flow_test.dart -d emulator-5554`: PASS. Manual lookup/checking, service, schedule, history, and correction entry point were observed on Android; see `android-qa.md`.
- Real configured Android build cold-started to the MGRS Maintenance login screen without entering credentials or writing remote data.
- Development APK: `build/app/outputs/flutter-apk/app-debug.apk`, 195,761,884 bytes, SHA-256 `ed4c5de25f965a7f57cd557dc6649aea335f4fb33691625b8b1aff27579ec9a7`. This is a debug artifact, not a signed production release.
- Docker start/version did not reach a usable engine within bounded waits. No system Docker/WSL reset performed.
- No physical Android device attached; QA ran on the `mgrs_phase2_x86_qa` emulator at 1080 x 1920.

## Production boundary

The two additive maintenance migrations, `pg_cron`, activation snapshot, and one scheduler job were applied to the user-authorized non-production shared database on 7 September 2026. The local baseline and seed were not applied. Verification made no component, history, usage-status, task, or event write. No source in mgrs-release or Documents/MGRS has been edited.
