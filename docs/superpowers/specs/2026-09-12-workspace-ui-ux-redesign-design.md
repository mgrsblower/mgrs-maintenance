# Workspace UI/UX Redesign Design

**Date:** 2026-09-12  
**Product:** MGRS  
**Platform:** Flutter Android  
**Status:** Approved for specification review

## Problem

The current Flutter application combines maintenance, field operations, orders, invoices, and PIC flows inside one navigation model. The product is intentionally a combined MGRS application, but the current UI does not express clear workspace boundaries. Admin, PIC, and field users need different entry points and task-focused navigation.

This redesign changes the information architecture and component system, not only colors or visual styling.
## Visual reference and anti-slop mode

`C:\Users\ogi\Downloads\DESIGN-apple.md` is the approved visual north star. Apply its cool monochrome surfaces, Action Blue, restrained chrome, typography-led hierarchy, and curated product focus as an aggressive replacement of the current visual world. Do not copy its marketing-gallery composition or iOS/web-only patterns into the Android app.

Apply the globally installed `antislop`, `antislop-ui`, `antislop-human`, and `antislop-layoutmobile` skills **DURING** planning and implementation. Every technique must pass a purpose test. Every interactive element must work, real data must remain evidence-based, and all states, contrast, focus, touch targets, and responsive layouts must be verified before delivery.


## Product model

The product has two workspaces:

1. **PIC MGRS** — orderan and invoice.
2. **Tim Lapangan** — maintenance, field order context, and installation confirmation.

Roles:

| Role | Workspace access | Default entry |
|---|---|---|
| Admin | PIC MGRS and Tim Lapangan | Workspace chooser or last-used workspace |
| PIC MGRS | PIC MGRS only | Orderan |
| Tim Lapangan | Tim Lapangan only | Scan / field task |

“Tim Lapangan” replaces the previous “Tim Pemasangan” role name and combines the previous field-installation and service responsibilities. Admin workspace switching changes the visible product area, not the authenticated role or server permissions.

## Goals

- Make each role land directly in the correct work context.
- Keep maintenance primary for Tim Lapangan.
- Keep orderan and invoice together for PIC MGRS.
- Allow Tim Lapangan to view relevant order/pasangan context without entering the PIC workspace.
- Support installation confirmation with optional unit selection.
- Replace decorative custom navigation with native Material navigation that adapts to screen size.
- Establish one semantic design system for shared primitives and states.
- Preserve existing backend contracts, authentication, transaction behavior, and working domain actions unless a product rule explicitly changes them.

## Non-goals

- No new AI, diagnosis, photo workflow, push notification, offline queue, or analytics feature.
- No change to server-side authorization model as part of UI work.
- No deletion of order, allocation, invoice, maintenance, or history capabilities.
- No universal dashboard that mixes all domains into one flat navigation.

## Workspace IA

### PIC MGRS workspace

Primary navigation:

```text
Beranda
Orderan
Invoice
Profil
```

The landing screen shows operational order information and clear actions for opening order detail, managing allocation, and creating or reviewing invoices. Maintenance controls are not shown in this workspace except where a specific order needs field status context.

### Tim Lapangan workspace

Primary navigation:

```text
Scan
Berkala
Komponen
Riwayat
```

The scanner is the primary action and the default entry for Tim Lapangan. Servis and pemeriksaan are actions reached from component detail or task detail, not competing primary destinations.

Field order context is available from relevant order/pasangan cards and detail views:

```text
Order/pasangan detail
  └── Konfirmasi pemasangan
        └── Pilih unit (opsional)
```

Optional unit selection must never silently select a unit. If no unit is selected, the confirmation remains valid only when the underlying operation allows an installation without an explicit unit selection.

### Admin workspace switching

Admin sees a prominent workspace switcher with exactly two choices:

- PIC MGRS
- Tim Lapangan

Switching workspace resets the navigation selection to that workspace’s landing screen, preserves authentication, and does not grant or revoke server permissions. The active workspace is visually and semantically announced.

## Core task flows

### Tim Lapangan: maintenance

```text
Scan / manual code
  → Detail komponen
  → Catat pemeriksaan atau Catat servis
  → Review hasil
  → Simpan
  → Success / conflict / retry
```

Opening detail or scanning alone never records a maintenance event.

### Tim Lapangan: periodic task

```text
Berkala
  → Pilih periode
  → Pilih atau scan komponen
  → Catat pemeriksaan
  → Simpan untuk periode
  → Status task diperbarui
```

Task status and component condition remain separate concepts. “Selesai diperiksa” does not mean “Kondisi baik”.

### Tim Lapangan: installation confirmation

```text
Order/pasangan context
  → Konfirmasi pemasangan
  → Pilih unit (opsional)
  → Review
  → Simpan
```

The UI must distinguish order identity, pasangan context, and selected component identity. It must show when unit selection is omitted.

### PIC MGRS

```text
Orderan
  → Order detail
  → Alokasi / status / invoice
```

Invoice remains inside PIC MGRS and is not placed in the Tim Lapangan navigation.

## Component system

### Shared primitives

Create or consolidate these components:

- `MGRSAppShell`
- `WorkspaceSwitcher`
- `AdaptiveNavigation`
- `MGRSTopAppBar`
- `AsyncStateView`
- `LoadingState`
- `ErrorState`
- `EmptyState`
- `ConflictState`
- `SearchField`
- `FilterControl`
- `StatusBadge`
- `FormSection`
- `ChoiceField`
- `SaveActionBar`
- `ConfirmDiscardDialog`

### Tim Lapangan components

- `ScanEntryCard`
- `ManualCodeField`
- `ComponentIdentityCard`
- `ConditionSummaryCard`
- `PeriodicTaskCard`
- `MaintenanceActionCard`
- `HistoryEventCard`
- `InstallationConfirmationCard`
- `OptionalUnitPicker`

### PIC MGRS components

- `OrderSummaryCard`
- `OrderStatusCard`
- `AllocationSummaryCard`
- `InvoiceSummaryCard`
- `PaymentStatusControl`

Shared primitives own interaction, semantics, spacing, and state behavior. Workspace components own domain content and vocabulary. Do not force both workspaces into identical card layouts.

## Visual and platform direction

- Use Material 3 color roles and typography roles.
- Use `NavigationBar` on compact Android widths.
- Use `NavigationRail` or drawer on expanded widths.
- Use native Material buttons, chips, dialogs, fields, sheets, and snackbar patterns.
- Minimum interactive target: 48dp with at least 8dp separation.
- Preserve system Back and predictive Back behavior.
- Support edge-to-edge insets, IME resize, large text, and Android dark mode.
- Remove the liquid-glass navigation dock, drag-to-scrub tab interaction, and unnecessary decorative blur/gradient effects.
- Motion should communicate navigation, selection, saving, success, conflict, or loading. Reduced-motion mode uses crossfade or immediate state changes.
- Status is always communicated with text; color is supplemental.

## Form rules

- Checking forms start with no preselected condition or usability result.
- Service forms start empty; example copy belongs in hint text only.
- Component identity becomes read-only after selection, with an explicit change action before save.
- Save is disabled while the request is running.
- Failed saves preserve input and offer retry without duplicate submission.
- Conflict state shows current data and requires review before retry.
- Leaving dirty forms requires discard confirmation.

## Data and permission constraints

- Preserve existing authenticated session and server-derived actor identity.
- Keep maintenance writes atomic and idempotent according to existing gateway contracts.
- UI workspace switching must not be treated as authorization.
- Tim Lapangan may read relevant order/pasangan context and confirm installation only through the authorized operation.
- PIC MGRS may manage order and invoice features according to its existing permissions.
- Admin may access both workspaces through the UI, while server authorization remains authoritative.

## Acceptance criteria

1. Admin can switch between exactly two workspaces: PIC MGRS and Tim Lapangan.
2. PIC MGRS opens directly into orderan and does not show Tim Lapangan primary navigation.
3. Tim Lapangan opens directly into Scan/maintenance navigation and does not show invoice as a primary destination.
4. Tim Lapangan can open relevant order/pasangan context and submit installation confirmation with zero or one explicitly selected unit according to the operation rule.
5. Tim Lapangan can perform scan, component detail, manual/periodic checking, service, and history flows without entering PIC MGRS.
6. All interactive controls expose accessible labels/states and meet the 48dp Android target minimum.
7. Navigation adapts from Material `NavigationBar` to `NavigationRail` or drawer at expanded widths.
8. Dark mode and 1.3 font scale do not clip or hide primary actions.
9. Checking and service forms contain no fabricated default results or example maintenance data.
10. Loading, empty, error, saving, success, conflict, and retry states are distinguishable and consistent across workspaces.
11. Existing auth, server permission, atomic save, idempotency, conflict, and history behavior remain intact.

## Open implementation boundary

The UI redesign may require renaming the client-facing role label from “Tim Pemasangan” to “Tim Lapangan”. Any persisted role value or server policy migration is outside the visual implementation and must be handled as a separate compatibility change before release if required by the live schema.

## Verified Implementation Boundaries

1. **Role Resolution & Compatibility**: `UserProfile` in `gateway.dart` resolves both modern `Tim Lapangan` and legacy strings (`Tim Service`, `Tim Pemasangan`) to `ProductRole.timLapangan` without modifying persisted database values.
2. **Installation Confirmation Contract**: Supabase and gateway RPC contracts do not yet expose a write endpoint for installation confirmation. In accordance with the anti-slop principles, `OrderDetailScreen` displays verified order identity and pasangan context with an explicit status message (`Konfirmasi pemasangan belum tersedia`) rather than fabricating an unverified write contract or dummy submission button.
3. **Workspace Surface Isolation**: Invoice cards and actions within `OrderDetailScreen` are strictly conditioned on `user.canManageOrders`, completely hiding invoice data and payment flows from Tim Lapangan users.
4. **Android Embedding Metadata**: The `flutterEmbedding` v2 `<meta-data>` in `AndroidManifest.xml` has been restored alongside `FileProvider`, ensuring standard Gradle Android v2 compilation succeeds cleanly for debug and release APKs.

