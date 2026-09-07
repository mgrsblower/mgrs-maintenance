# 002 — Shared database compatibility

Status: implementation baseline, 7 September 2026.

The user requested continuation after the proposed compatibility option. This implementation keeps legacy code and existing table permissions unchanged. New maintenance RPCs enforce active Admin, Tim Service and Tim Pemasangan, derive the actor from auth.uid(), and never write status_penggunaan or operational relations.

Conflict detection applies to NEW RPC submissions against the latest locked master row, including intervening legacy changes. It does not prevent a legacy client from subsequently sending an unconditional stale update. Same-user sessions retain existing legacy privileges. No claim of app-specific identity isolation is made.

The existing service history requires numeric cost with default zero. New events explicitly record costRecorded=false, cost=null and append “Biaya belum dicatat” to the legacy service note. The stored legacy zero is a compatibility sentinel, not an asserted actual cost. New UI renders “Belum dicatat”. No legacy numeric field is made nullable.

This refines PRD INT-04 and the unknown-cost integration rule for a compatible MVP; future all-client CAS enforcement requires a separate legacy change. Production rollout and cross-application QA remain gated. No production migrations have been applied.
