# 001 — Platform and product baseline

**Status:** partial — 6 September 2026  
**Scope:** MGRS-Maintenance only; this document does not authorize database, legacy-source, or production changes.

## Confirmed product scope

| Area | Decision |
| --- | --- |
| Components | `Kepala`, `Batang`, and `Tabung` only. Existing master identity and barcode/code remain the source of truth. |
| Users | Active `Admin`, `Tim Service`, and `Tim Pemasangan` may read and record maintenance. `PIC Pemasangan` is not included automatically. |
| Data | Uses the existing MGRS Supabase project (`ztindtxlbkgykyasgpnd`); it is not a new operational database. |
| Operational boundary | No installation, order, allocation, reservation, invoice, or user-management workflow. A maintenance write must not change `status_penggunaan` or operational relations, including through a trigger. |
| Schedule | Monthly fourth Saturday and the following Sunday in `Asia/Jakarta` (WIB). |

## Working implementation baseline

Flutter/Dart is the working client baseline, with **Android-first** as a reversible implementation assumption after the user authorized implementation. It is not a final user platform decision. The reported Windows toolchain is Flutter 3.44.8 and Dart 3.12.2; Chrome and Edge are available. No physical Android or iOS pilot device is currently available.

Do not scaffold or claim support for iOS, web, desktop, or distribution from this assumption. Build identity must be distinct from MGRS. Distribution method, pilot device, and final supported platform remain open before release work.

## Product rules carried forward from the PRD

The remaining PRD detail is the accepted planning baseline for pilot refinement, not a claim that the shared backend already supports it. In particular: manual checks before a window do not complete the monthly task; service never completes it automatically; a physically missing component remains open; correction is a new record; and history is not edited or deleted in the MVP.

The pilot acceptance target remains p95 of at most three seconds for lookup-to-detail and save, measured from at least 30 attempts per flow on the agreed device, network, and QA data.

## Open gates that cannot be resolved in this document

1. **Shared-writer conflict guarantee:** the legacy writer paths may update without a version. A trigger that increments a version does not itself guarantee conflict detection for every writer. The database audit must determine whether all writers can use an enforceable contract; legacy changes require separate scope.
2. **Shared role sessions:** the new and legacy applications use the same user/JWT and database roles. Application identity alone cannot safely isolate direct-update permission. Server access design remains a G0 decision.
3. **Service cost:** the known legacy service-cost column is numeric, `NOT NULL`, with default `0`; the PRD requires unknown cost to remain unknown rather than invented. The audit must find a compatible representation or obtain a product decision before service writes are implemented.
4. **Device and distribution:** physical-device pilot availability and Android/iOS distribution method are undecided.

Until these shared-database gates are closed, work may document and test isolated fixtures but must not activate writes against the shared production database.
