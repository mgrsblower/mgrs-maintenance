# MGRS Screen-to-Code Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menerapkan seluruh screen dan state pada `Redesign UI.pen` ke aplikasi Flutter MGRS Maintenance dengan `y8voL5` sebagai fondasi visual, tanpa mengubah kontrak data dan perilaku bisnis yang sudah diuji.

**Architecture:** Pertahankan arsitektur `MaterialApp`, `MaintenanceGateway`, `PageView`, dan screen berbasis `StatefulWidget` yang sudah ada. Tambahkan design-system layer kecil dan reusable state views, lalu migrasikan flow secara vertikal: shell, authentication, service, order, invoice, scanner, dan global states. Loaded, loading, empty, error, serta search-no-results dirender sebagai state dari screen yang sama, bukan route terpisah.

**Tech Stack:** Flutter 3 / Dart 3.12, Material 3, `flutter_test`, `integration_test`, `mobile_scanner`, Supabase melalui `MaintenanceGateway`; tanpa dependency baru.

## Global Constraints

- Sumber visual normatif: frame `y8voL5` pada `C:\Users\ogi\Downloads\Redesign UI.pen` dan `DESIGN.md`.
- Canvas `#F5F5F5`, surface `#FFFFFF`, ink `#171717`, muted `#666666`, line `#E7E7E7`, action `#D91C48`.
- Success `#166534`, warning `#854D0E`, danger `#B42318` dan soft background semantik masing-masing.
- Inter adalah font normatif; button label 15px/600, app-bar title 17px/600, body 14px/400, label 12px/600.
- Gutter mobile 20, control minimum 48, primary button 52, app bar 56, bottom navigation 68.
- Input radius 12, compact surface 16, card 24, sheet 28, pill 999.
- Artboard 390 x 844 adalah reference viewport, bukan ukuran hardcoded. UI wajib aman pada lebar 320, 360, 390, dan 430 serta text scale 200%.
- Tidak mengubah signature RPC, payload gateway, model database, atau aturan bisnis dalam pekerjaan visual ini.
- Nilai form, draft, request ID, dan hasil scan tidak boleh hilang saat loading, error, conflict, resize, atau keyboard muncul.
- Tidak menampilkan exception, SQL, atau `e.toString()` kepada pengguna.
- Satu filled primary action per action group.
- Loading, empty, error, dan search-no-results mempertahankan header, filter, search, dan bottom navigation screen induk.
- Scanner wajib berhenti ketika hasil ditemukan, screen ditutup, aplikasi pause, atau sesi berakhir.
- PRD saat ini menyatakan order dan invoice di luar MVP, sedangkan source dan canvas sudah mengimplementasikannya. Task 1 menyelaraskan dokumen dengan scope aktual sebelum migrasi visual.

---

## Canvas-to-Code Matrix

| Canvas | Flutter target |
| --- | --- |
| `y8voL5` Foundations | `lib/app/app_theme.dart`, `lib/design_system/*` |
| `FDInN` Profil Admin | profile sheet di `lib/features/home/home_screen.dart` dan `pic_home_screen.dart` |
| `U5fSK` Beranda operasional | `lib/features/home/home_screen.dart` |
| `XAOVW` Daftar order | `lib/features/schedule/upcoming_orders_screen.dart` |
| `G2Duhu` Detail order & alokasi | `lib/features/schedule/order_detail_screen.dart`, `unit_allocation_card.dart` |
| `NxK5V`, `t4azBZ`, `BTcsW`, `qzi8f` | `lib/features/schedule/component_picker_sheet.dart` |
| `Cs0Cf` Konfirmasi order | confirmation UI di `order_detail_screen.dart` |
| `ZD3Ks` Katalog | `lib/features/components/asset_catalog_screen.dart` |
| `wpHDh` Detail komponen | `lib/features/components/component_detail_screen.dart` |
| `BEhNG`, `lBRgC`, `tOMM6` | `lib/features/maintenance/checking_screen.dart` |
| `F5r3W3`, `BSfSy` | success sheet di `checking_screen.dart` |
| `Nb5Mm` Catat servis | `CheckingScreen(service: true)` |
| `P0DHyS` Pusat tindakan | `lib/features/maintenance/action_center_screen.dart` |
| `DbVfe`, `PHWAe`, `V4woXN`, `w0WWMY`, `N3YDPw` | `lib/features/scan/scan_screen.dart` |
| `Z3jInt`, `DVahT` | `lib/features/history/history_screen.dart` dan list search states |
| `yXaDP` Detail riwayat | `lib/features/history/history_detail_screen.dart` |
| `U9rmO` Login | `lib/features/auth/login_screen.dart` |
| `cL6xW` Buat order | `lib/features/schedule/create_order_screen.dart` |
| `sVFCA` Batalkan order | cancellation dialog di `upcoming_orders_screen.dart` |
| `c5fyaG` Scan alokasi | allocation scan mode di `unit_allocation_card.dart` |
| `Zesyn` PIC Beranda | `lib/features/home/pic_home_screen.dart` |
| `zfLV8` Order kosong | empty state di `upcoming_orders_screen.dart` |
| `Am5S7`, `wda7C`, `Xizur`, `Ltkxp` | satu `InvoiceListScreen` dengan empat data states |
| `I6BN3` Pembayaran | `lib/features/invoices/quick_payment_dialog.dart` |
| `Tqj7E`, `xhUdK` | `lib/features/invoices/invoice_builder_dialog.dart` |
| `i1muR`, `R5HNus` | `lib/features/invoices/pdf/invoice_pdf_dialogs.dart` |
| `lufpi`, `LmGKc` | `create_invoice_dialog.dart` dan invoice builder source mode |
| `Qb9H5`, `UQQgU` | invoice card variants berdasarkan `InvoicePaymentStatus` |
| `cTy8K` Hapus invoice | destructive confirmation dari invoice detail |
| `uz7xq`, `gKrU1` | session overlay di `lib/app/app.dart` |

---

### Task 1: Lock Scope and Establish the Visual Contract

**Files:**
- Modify: `PRD.md:1-80`
- Modify: `README.md:1-20`
- Modify: `DESIGN.md:1-297`
- Create: `docs/evidence/redesign-screen-matrix.md`

**Interfaces:**
- Consumes: Canvas-to-code matrix pada plan ini.
- Produces: Satu daftar screen/state yang dapat digunakan sebagai acceptance ledger oleh semua task berikutnya.

- [ ] **Step 1: Write the scope assertion document**

Create `docs/evidence/redesign-screen-matrix.md` with these columns and every row from the matrix above:

```markdown
# Redesign Screen Matrix

Source of truth: `Redesign UI.pen`, foundation `y8voL5`.

| Canvas ID | Design name | Flutter owner | Loaded | Loading | Empty | Error | Search empty | Implemented | Verified |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Am5S7 | PIC 02 · Daftar invoice | InvoiceListScreen | yes | Xizur | wda7C | Ltkxp | DVahT | no | no |
```

Mark non-list screens with `n/a`. Do not mark a row implemented until its widget test and visual review both pass.

- [ ] **Step 2: Resolve documentation drift explicitly**

Update the PRD executive summary and MVP boundary so it states that the current app has two operational modes: Service and PIC, with PIC order and invoice flows. Preserve the maintenance acceptance rules. Remove the statements that categorically exclude order, allocation, and invoice because they contradict shipped source and approved canvas.

- [ ] **Step 3: Align the button token in `DESIGN.md`**

Add a `button-label` typography token with `15px`, weight `600`, and point `components.button-primary.typography` and `button-neutral.typography` to it. Keep cobalt documented as operational-only, not the default primary action.

- [ ] **Step 4: Verify documentation consistency**

Run:

```bash
grep -n "order\|invoice\|PIC" PRD.md README.md DESIGN.md docs/evidence/redesign-screen-matrix.md
```

Expected: all four files acknowledge PIC order and invoice flows; no active MVP statement says they are excluded.

- [ ] **Step 5: Commit**

```bash
git add PRD.md README.md DESIGN.md docs/evidence/redesign-screen-matrix.md
git commit -m "docs: align redesign scope and screen matrix"
```

---

### Task 2: Implement Design Tokens and Theme

**Files:**
- Modify: `lib/app/app_theme.dart`
- Create: `lib/design_system/mgrs_tokens.dart`
- Test: `test/design_system/theme_test.dart`

**Interfaces:**
- Produces: `MgrsColors`, `MgrsSpacing`, `MgrsRadii`, `MgrsSizes`, and `maintenanceTheme()` used by all later tasks.

- [ ] **Step 1: Write the failing token and theme test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app_theme.dart';
import 'package:mgrs_maintenance/design_system/mgrs_tokens.dart';

void main() {
  test('foundation tokens match y8voL5', () {
    expect(MgrsColors.canvas, const Color(0xFFF5F5F5));
    expect(MgrsColors.surface, const Color(0xFFFFFFFF));
    expect(MgrsColors.ink, const Color(0xFF171717));
    expect(MgrsColors.action, const Color(0xFFD91C48));
    expect(MgrsRadii.card, 24);
    expect(MgrsSizes.primaryButton, 52);
    expect(MgrsSizes.bottomNavigation, 68);
  });

  test('theme uses Inter and rose primary', () {
    final theme = maintenanceTheme();
    expect(theme.colorScheme.primary, MgrsColors.action);
    expect(theme.scaffoldBackgroundColor, MgrsColors.canvas);
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
    expect(theme.cardTheme.elevation, 0);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/design_system/theme_test.dart`

Expected: FAIL because `mgrs_tokens.dart` and token classes do not exist.

- [ ] **Step 3: Create canonical tokens**

```dart
import 'package:flutter/material.dart';

abstract final class MgrsColors {
  static const canvas = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF171717);
  static const muted = Color(0xFF666666);
  static const line = Color(0xFFE7E7E7);
  static const action = Color(0xFFD91C48);
  static const operational = Color(0xFF147CC1);
  static const success = Color(0xFF166534);
  static const successSoft = Color(0xFFECF8F0);
  static const warning = Color(0xFF854D0E);
  static const warningSoft = Color(0xFFFEFCE8);
  static const danger = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFEF0EE);
}

abstract final class MgrsSpacing {
  static const xs = 4.0, sm = 8.0, md = 12.0, base = 16.0;
  static const lg = 20.0, xl = 24.0, section = 32.0;
}

abstract final class MgrsRadii {
  static const control = 12.0, compact = 16.0, card = 24.0;
  static const sheet = 28.0, pill = 999.0;
}

abstract final class MgrsSizes {
  static const minTouch = 48.0, appBar = 56.0;
  static const primaryButton = 52.0, bottomNavigation = 68.0;
  static const maxContentWidth = 640.0;
}
```

- [ ] **Step 4: Rebuild `maintenanceTheme()` from tokens**

Use `ColorScheme.light`, `Inter` for all text styles, a 52-high pill `FilledButton`, 48-high fields with radius 12, and flat radius-24 cards with no default border. Keep deprecated `AppTokens` aliases temporarily so feature migrations remain incremental.

- [ ] **Step 5: Run tests and analyzer**

Run:

```bash
flutter test test/design_system/theme_test.dart
flutter analyze
```

Expected: theme test PASS; analyzer introduces no new diagnostics.

- [ ] **Step 6: Commit**

```bash
git add lib/app/app_theme.dart lib/design_system/mgrs_tokens.dart test/design_system/theme_test.dart
git commit -m "feat: establish y8voL5 Flutter tokens"
```

---

### Task 3: Build Reusable Foundation Components

**Files:**
- Create: `lib/design_system/components/mgrs_button.dart`
- Create: `lib/design_system/components/mgrs_app_bar.dart`
- Create: `lib/design_system/components/mgrs_search_field.dart`
- Create: `lib/design_system/components/mgrs_status_badge.dart`
- Create: `lib/design_system/components/mgrs_multiline_field.dart`
- Create: `lib/design_system/components/mgrs_state_view.dart`
- Create: `lib/design_system/layout/mgrs_screen.dart`
- Modify: `lib/shared/async_state_view.dart`
- Modify: `lib/shared/condition_badge.dart`
- Test: `test/design_system/components_test.dart`

**Interfaces:**
- Produces: `MgrsButton.primary`, `MgrsDetailAppBar`, `MgrsSearchField`, `MgrsStatusBadge`, `MgrsMultilineField`, `MgrsStateView`, and `MgrsScreen`.

- [ ] **Step 1: Write failing component contract tests**

Test exact semantics and dimensions:

```dart
await tester.pumpWidget(MaterialApp(home: Scaffold(body: MgrsButton.primary(label: 'Simpan pemeriksaan', onPressed: () {}))));
expect(tester.getSize(find.byType(FilledButton)).height, 52);
expect(find.text('Simpan pemeriksaan'), findsOneWidget);

await tester.pumpWidget(const MaterialApp(home: Scaffold(body: MgrsStateView.empty(title: 'Belum ada invoice', actionLabel: 'Buat invoice'))));
expect(find.text('Belum ada invoice'), findsOneWidget);
expect(find.text('Buat invoice'), findsOneWidget);
```

Also assert that icon-only app-bar actions have tooltips and that search clear control has a semantic label.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/design_system/components_test.dart`

Expected: FAIL because foundation widgets do not exist.

- [ ] **Step 3: Implement component APIs**

Use these stable signatures:

```dart
class MgrsButton extends StatelessWidget {
  const MgrsButton.primary({super.key, required this.label, this.icon, this.onPressed, this.loading = false});
  const MgrsButton.neutral({super.key, required this.label, this.icon, this.onPressed, this.loading = false});
  const MgrsButton.destructive({super.key, required this.label, this.icon, this.onPressed, this.loading = false});
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
}

class MgrsStateView extends StatelessWidget {
  const MgrsStateView.loading({super.key, this.title = 'Memuat data...'});
  const MgrsStateView.empty({super.key, required this.title, required this.actionLabel, this.message, this.onAction});
  const MgrsStateView.error({super.key, required this.title, required this.actionLabel, this.message, this.onAction});
  const MgrsStateView.noResults({super.key, required this.query, required this.onReset});
}
```

`MgrsStateView` must not own a page scaffold. It only replaces a screen's data region.

- [ ] **Step 4: Bridge legacy shared components**

Make `ConditionBadge` delegate to `MgrsStatusBadge`. Refactor `AsyncStateView` to use `MgrsStateView.loading/error` while preserving its public constructor so existing screens compile.

- [ ] **Step 5: Verify components**

Run:

```bash
flutter test test/design_system/components_test.dart
flutter test test/flow_screens_test.dart
flutter analyze
```

Expected: PASS with no new analyzer diagnostics.

- [ ] **Step 6: Commit**

```bash
git add lib/design_system lib/shared/async_state_view.dart lib/shared/condition_badge.dart test/design_system/components_test.dart
git commit -m "feat: add reusable MGRS visual components"
```

---

### Task 4: Replace Navigation and Role Shell Styling

**Files:**
- Modify: `lib/shared/bottom_nav_bar.dart`
- Modify: `lib/app/app.dart`
- Test: `test/navigation_shell_test.dart`
- Test: `test/admin_mode_switch_test.dart`

**Interfaces:**
- Consumes: `MgrsColors`, `MgrsSizes`, `MgrsRadii`.
- Preserves: `AppBottomNavBar`, `AppNavItem`, `onNavigateToTab`, `onOpenScanner`, role switching, and `PageController` behavior.

- [ ] **Step 1: Write shell tests**

Assert Service destinations are `Beranda`, `Aset`, `Servis`; PIC destinations are `Beranda`, `Orderan`, `Invoice`; optional scanner invokes `onOpenScanner`; selected tab exposes `Semantics(selected: true)`; dock height is 68 excluding safe-area padding.

- [ ] **Step 2: Run tests to verify the current glass dock fails visual contracts**

Run: `flutter test test/navigation_shell_test.dart`

Expected: FAIL on height, dark surface, or selected semantics.

- [ ] **Step 3: Simplify the dock to the y8voL5 structure**

Retain tap, drag-to-scrub, haptic feedback, and spring snapping. Replace frosted gradients and chromatic bubble effects with an ink pill, clear active item, white active icon/label, `#A8A8A8` inactive state, and rose circular scanner action. Use a 68-high dock and avoid stacking a sticky CTA behind it.

- [ ] **Step 4: Preserve role shell behavior**

Keep `MaintenanceHome.effectiveIsPic`, PIC and service destination arrays, `PageView`, scanner route, and admin mode reset to tab zero unchanged.

- [ ] **Step 5: Verify shell behavior**

Run:

```bash
flutter test test/navigation_shell_test.dart test/admin_mode_switch_test.dart test/pic_flow_test.dart
flutter analyze
```

Expected: PASS; both roles retain three destinations and scanner navigation.

- [ ] **Step 6: Commit**

```bash
git add lib/shared/bottom_nav_bar.dart lib/app/app.dart test/navigation_shell_test.dart test/admin_mode_switch_test.dart
git commit -m "feat: align role navigation with MGRS foundation"
```

---

### Task 5: Migrate Authentication and Global Access States

**Files:**
- Modify: `lib/features/auth/login_screen.dart`
- Modify: `lib/app/app.dart`
- Test: `test/auth_states_test.dart`
- Existing test: `test/widget_test.dart`

**Interfaces:**
- Implements: `U9rmO`, `uz7xq`, `gKrU1`.
- Preserves: `MaintenanceGateway.signIn`, `profile`, `signOut`, and auth stream behavior.

- [ ] **Step 1: Add failing tests for login and access states**

Cover empty credentials, incorrect credentials, loading-disabled submit, session expiry with `Masuk kembali`, forbidden role with `Keluar`, and technical exception masking.

```dart
expect(find.text('Masuk ke MGRS'), findsOneWidget);
expect(find.text('Masukkan email atau username.'), findsOneWidget);
expect(find.textContaining('PostgrestException'), findsNothing);
```

- [ ] **Step 2: Run tests to verify failures**

Run: `flutter test test/auth_states_test.dart`

Expected: at least one missing copy/state assertion fails.

- [ ] **Step 3: Implement the login reference**

Use `MgrsScreen`, 20px gutter, one rose primary button, labeled fields, inline errors, password visibility toggle with tooltip, and stable field values on failure. Do not reproduce the 390 width literally.

- [ ] **Step 4: Split global auth overlay states**

In `app.dart`, map `AppFailure('unauthenticated')` to the session-expired state and `AppFailure('forbidden')` to access denied. Provide explicit recovery actions instead of rendering one generic failure screen.

- [ ] **Step 5: Verify authentication**

Run:

```bash
flutter test test/auth_states_test.dart test/widget_test.dart
flutter analyze
```

Expected: PASS; no raw exception is visible.

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/login_screen.dart lib/app/app.dart test/auth_states_test.dart
git commit -m "feat: implement redesigned authentication states"
```

---

### Task 6: Migrate the Service Asset and History Flow

**Files:**
- Modify: `lib/features/home/home_screen.dart`
- Modify: `lib/features/components/asset_catalog_screen.dart`
- Modify: `lib/features/components/component_detail_screen.dart`
- Modify: `lib/features/history/history_screen.dart`
- Modify: `lib/features/history/history_detail_screen.dart`
- Modify: `lib/features/maintenance/action_center_screen.dart`
- Test: `test/service_visual_states_test.dart`
- Existing test: `test/flow_screens_test.dart`

**Interfaces:**
- Implements: `U5fSK`, `P0DHyS`, `ZD3Ks`, `wpHDh`, `Z3jInt`, `yXaDP`, `DVahT`.
- Preserves: gateway fetch, filtering, sorting, refresh, and navigation behavior.

- [ ] **Step 1: Add failing screen-shell tests**

For each list screen, assert header and filters remain visible when gateway returns loading, empty, error, or filtered-empty data. Assert component code is the strongest identity and status text is not color-only.

- [ ] **Step 2: Run the target tests**

Run: `flutter test test/service_visual_states_test.dart`

Expected: FAIL because current screens use independent hardcoded styling and incomplete no-result treatment.

- [ ] **Step 3: Migrate Home and Action Center**

Replace local color/radius/font constants with design-system components. Preserve all gateway calls and navigation callbacks. Remove decorative cards that do not group distinct information.

- [ ] **Step 4: Migrate Catalog and Detail**

Use `MgrsSearchField`, `MgrsStatusBadge`, surface cards, and stable list state region. Search-no-results must include the active query and a `Hapus pencarian` action. Empty database must use different copy from filtered-empty.

- [ ] **Step 5: Migrate History and History Detail**

Keep pagination and filters. Use explicit activity labels for manual check, periodic check, and service. Historical values remain as stored; never reconstruct missing facts.

- [ ] **Step 6: Verify flow and responsive layout**

Run:

```bash
flutter test test/service_visual_states_test.dart test/flow_screens_test.dart
flutter analyze
```

Repeat widget tests at logical widths 320, 390, and 430 and assert `tester.takeException()` is null.

- [ ] **Step 7: Commit**

```bash
git add lib/features/home/home_screen.dart lib/features/components lib/features/history lib/features/maintenance/action_center_screen.dart test/service_visual_states_test.dart test/flow_screens_test.dart
git commit -m "feat: migrate service browse and history screens"
```

---

### Task 7: Migrate Checking, Service, Validation, Conflict, and Success

**Files:**
- Modify: `lib/features/maintenance/checking_screen.dart`
- Preserve: `lib/features/maintenance/submission_controller.dart`
- Test: `test/checking_visual_states_test.dart`
- Existing test: `test/submission_controller_test.dart`

**Interfaces:**
- Implements: `BEhNG`, `Nb5Mm`, `F5r3W3`, `BSfSy`, `lBRgC`, `tOMM6`.
- Preserves: `SubmissionState`, immutable command retry, receipt lookup, conflict refresh, discard confirmation.

- [ ] **Step 1: Write failing tests for all form states**

Cover idle, invalid, submitting, known failure, uncertain result, conflict, success, discard, and text scale 200%. Verify invalid fields show inline messages and focus moves to the first error.

- [ ] **Step 2: Run form tests**

Run: `flutter test test/checking_visual_states_test.dart test/submission_controller_test.dart`

Expected: visual-state tests fail; existing submission tests pass.

- [ ] **Step 3: Extract presentation-only sections**

Inside `checking_screen.dart`, keep business methods unchanged and extract private widgets for identity, condition selection, service fields, error banner, conflict banner, bottom action, and success sheet. Use `MgrsDetailAppBar`, `MgrsMultilineField`, `MgrsStatusBadge`, and `MgrsButton`.

- [ ] **Step 4: Implement validation and conflict references**

Use danger-soft inline field treatment for validation. For conflict, explain that newer data exists and offer `Muat data terbaru`; do not erase controllers until refresh succeeds. Uncertain result offers `Periksa status penyimpanan` and calls `submission.recover()`.

- [ ] **Step 5: Implement success sheets**

Use one shared success sheet builder with title and body parameters. Close the form only after the backend reports `SubmissionState.succeeded`.

- [ ] **Step 6: Verify controller invariants and UI**

Run:

```bash
flutter test test/checking_visual_states_test.dart test/submission_controller_test.dart test/flow_screens_test.dart
flutter analyze
```

Expected: PASS; same request ID is reused after an uncertain response.

- [ ] **Step 7: Commit**

```bash
git add lib/features/maintenance/checking_screen.dart test/checking_visual_states_test.dart
git commit -m "feat: implement maintenance form states"
```

---

### Task 8: Migrate Order Creation, Lists, Detail, Allocation, and Cancellation

**Files:**
- Modify: `lib/features/schedule/create_order_screen.dart`
- Modify: `lib/features/schedule/upcoming_orders_screen.dart`
- Modify: `lib/features/schedule/order_detail_screen.dart`
- Modify: `lib/features/schedule/unit_allocation_card.dart`
- Test: `test/order_visual_states_test.dart`
- Existing tests: `test/order_cancellation_test.dart`, `test/unit_allocation_flow_test.dart`, `test/unit_allocation_card_test.dart`

**Interfaces:**
- Implements: `XAOVW`, `G2Duhu`, `Cs0Cf`, `cL6xW`, `sVFCA`, `c5fyaG`, `zfLV8`.
- Preserves: `createOrderWithInvoice`, order status transitions, unit allocation gateway calls, and order cancellation rules.

- [ ] **Step 1: Add failing order-state tests**

Cover list loaded/empty/error, create validation/submitting/failure/success, allocation scan match/mismatch, completion confirmation, cancellation reason, and unpaid invoice option.

- [ ] **Step 2: Run the order tests**

Run: `flutter test test/order_visual_states_test.dart`

Expected: FAIL on missing stable state views and dialog details.

- [ ] **Step 3: Migrate order list and create form**

Keep the list shell visible for empty/error. Replace generated random UI identity with server-returned order identity where available. Disable submit while creating. Preserve all controllers after request failure and display sanitized inline recovery copy.

- [ ] **Step 4: Migrate detail and allocation**

Use the component picker result as an explicit selection. Scanner allocation must reject wrong component kind, not-found, duplicate, and already-allocated results without mutating the allocation list.

- [ ] **Step 5: Migrate completion and cancellation dialogs**

Cancellation requires a non-empty reason. Present the unpaid-invoice option only when the order has an unpaid invoice. Destructive action uses danger styling and mentions the affected order ID.

- [ ] **Step 6: Verify order behavior**

Run:

```bash
flutter test test/order_visual_states_test.dart test/order_cancellation_test.dart test/unit_allocation_flow_test.dart test/unit_allocation_card_test.dart
flutter analyze
```

Expected: PASS; no order or invoice gateway contract changes.

- [ ] **Step 7: Commit**

```bash
git add lib/features/schedule test/order_visual_states_test.dart
git commit -m "feat: migrate complete order flow"
```

---

### Task 9: Implement Component Picker State Parity

**Files:**
- Modify: `lib/features/schedule/component_picker_sheet.dart`
- Test: `test/component_picker_sheet_test.dart`

**Interfaces:**
- Implements: `NxK5V`, `t4azBZ`, `BTcsW`, `qzi8f`.
- Preserves: `Future<String?> showComponentPickerSheet(...)`, availability filtering, usage-count sorting, current selection, and empty-string clear result.

- [ ] **Step 1: Extend tests for each state**

Use controllable completers and mock failures. Assert the sheet title, close action, and search stay present during loading, empty, error, and no-results. Assert retry invokes `fetchComponents` again and raw exception text is absent.

- [ ] **Step 2: Run tests to verify failures**

Run: `flutter test test/component_picker_sheet_test.dart`

Expected: new error sanitization and state-shell tests fail.

- [ ] **Step 3: Rebuild sheet presentation**

Use radius 28, max height 75% to 85%, 20px horizontal gutter, `MgrsSearchField`, reusable loading/empty/error/no-results views, and component rows matching `WSMnC`. Keep the existing filter and sort logic exactly.

- [ ] **Step 4: Verify picker behavior**

Run:

```bash
flutter test test/component_picker_sheet_test.dart test/unit_allocation_card_test.dart
flutter analyze
```

Expected: PASS; `K-02` remains ahead of `K-01` when usage is lower.

- [ ] **Step 5: Commit**

```bash
git add lib/features/schedule/component_picker_sheet.dart test/component_picker_sheet_test.dart
git commit -m "feat: implement component picker states"
```

---

### Task 10: Migrate the Full Invoice Flow

**Files:**
- Modify: `lib/features/invoices/invoice_list_screen.dart`
- Modify: `lib/features/invoices/create_invoice_dialog.dart`
- Modify: `lib/features/invoices/invoice_builder_dialog.dart`
- Modify: `lib/features/invoices/quick_payment_dialog.dart`
- Modify: `lib/features/invoices/pdf/invoice_pdf_dialogs.dart`
- Create: `lib/features/invoices/widgets/invoice_list_shell.dart`
- Create: `lib/features/invoices/widgets/invoice_card.dart`
- Test: `test/invoice_visual_states_test.dart`
- Existing tests: `test/pic_flow_test.dart`, `test/invoice_pdf_test.dart`

**Interfaces:**
- Implements: `Am5S7`, `wda7C`, `Xizur`, `Ltkxp`, `I6BN3`, `Tqj7E`, `xhUdK`, `i1muR`, `R5HNus`, `lufpi`, `LmGKc`, `Qb9H5`, `UQQgU`, `cTy8K`.
- Preserves: `InvoiceRecord`, filters, calculations, payment updates, PDF export/download/share, invoice source, and gateway callbacks.

- [ ] **Step 1: Add failing stable-shell tests**

Assert `Daftar Invoice`, create action, source switch, search, and status filter remain visible in loaded, loading, empty, failure, and no-results states. Assert the body alone changes. Cover paid, partial, and unpaid card variants.

- [ ] **Step 2: Run invoice tests**

Run: `flutter test test/invoice_visual_states_test.dart test/pic_flow_test.dart`

Expected: new stable-shell assertions fail against the current implementation.

- [ ] **Step 3: Extract `InvoiceListShell`**

Use this interface:

```dart
class InvoiceListShell extends StatelessWidget {
  const InvoiceListShell({
    super.key,
    required this.sourceFilter,
    required this.paymentFilter,
    required this.searchController,
    required this.onSourceChanged,
    required this.onPaymentChanged,
    required this.onSearchChanged,
    required this.onCreate,
    required this.body,
  });
  final InvoiceSourceFilter sourceFilter;
  final InvoicePaymentStatus? paymentFilter;
  final TextEditingController searchController;
  final ValueChanged<InvoiceSourceFilter> onSourceChanged;
  final ValueChanged<InvoicePaymentStatus?> onPaymentChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCreate;
  final Widget body;
}
```

The shell owns header/filter/search layout, never async loading.

- [ ] **Step 4: Map list states into the shell body**

Use loading when `_isLoading`, error when `_error != null`, database empty when source data is empty, no-results when source data exists but `_filteredInvoices` is empty, and cards otherwise. Retry calls `_loadInvoices(forceRefresh: true)`.

- [ ] **Step 5: Migrate invoice dialogs**

Apply the shared app bar, fields, buttons, dialog radius, and destructive confirmation. Keep calculation and PDF code untouched. Delete confirmation must name the invoice and state that deletion is permanent. If the gateway has no delete operation, keep the delete action disabled and do not add a fake local delete.

- [ ] **Step 6: Verify invoice behavior and constrained layouts**

Run:

```bash
flutter test test/invoice_visual_states_test.dart test/pic_flow_test.dart test/invoice_pdf_test.dart
flutter analyze
```

Expected: PASS; all footer buttons remain within the dialog at 600 x 800 test size.

- [ ] **Step 7: Commit**

```bash
git add lib/features/invoices test/invoice_visual_states_test.dart test/pic_flow_test.dart
git commit -m "feat: migrate invoice flow and state parity"
```

---

### Task 11: Implement Scanner State Machine and Allocation Mode

**Files:**
- Modify: `lib/features/scan/scan_screen.dart`
- Create: `lib/features/scan/scan_state.dart`
- Test: `test/scan_state_test.dart`
- Test: `test/scan_screen_test.dart`
- Existing test: scanner assertions in `test/flow_screens_test.dart`

**Interfaces:**
- Implements: `DbVfe`, `PHWAe`, `V4woXN`, `w0WWMY`, `N3YDPw`, and lookup loading/network failure.
- Preserves: `ScanScreen` constructor, read-only PIC behavior, `maintenance_lookup_component`, lifecycle camera stopping, and component-detail navigation.

- [ ] **Step 1: Write state transition tests**

Define and test:

```dart
enum ScanPhase { camera, lookingUp, permissionDenied, unavailable, notFound, ambiguous, networkFailure, result }
```

Assert only one lookup runs at a time, duplicate frames do not navigate twice, and `notFound`/`ambiguous` keep manual search available.

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/scan_state_test.dart test/scan_screen_test.dart`

Expected: FAIL because `ScanPhase` and explicit state rendering do not exist.

- [ ] **Step 3: Implement explicit scan state**

Move phase derivation out of combinations of `scanning`, `busy`, `error`, and `scannedComponent`. Store the last submitted code. Map `AppFailure` codes to user states without exposing technical messages.

- [ ] **Step 4: Render each state over a stable scanner shell**

Keep close, flash, lens controls, viewfinder, and manual input placement stable where supported. Permission denied includes `Buka pengaturan`; camera unavailable and lookup failures include manual code entry; not-found includes retry; ambiguous blocks automatic selection and explains that the barcode is not unique.

- [ ] **Step 5: Verify camera lifecycle**

Test pause/resume, result, dispose, and session-change behavior. Ensure `camera.stop()` is called before opening detail and camera disposal is awaited or safely unawaited during dispose.

- [ ] **Step 6: Run verification**

```bash
flutter test test/scan_state_test.dart test/scan_screen_test.dart test/flow_screens_test.dart
flutter analyze
```

Expected: PASS with deterministic state transitions.

- [ ] **Step 7: Commit**

```bash
git add lib/features/scan test/scan_state_test.dart test/scan_screen_test.dart
git commit -m "feat: implement complete scanner state machine"
```

---

### Task 12: Responsive, Accessibility, Golden, and End-to-End Verification

**Files:**
- Create: `test/helpers/test_viewport.dart`
- Create: `test/golden/redesign_golden_test.dart`
- Modify: `integration_test/app_flow_test.dart`
- Modify: `docs/evidence/redesign-screen-matrix.md`
- Modify: `docs/evidence/android-qa.md`

**Interfaces:**
- Consumes: all screens and components from Tasks 2 through 11.
- Produces: repeatable regression evidence for representative service, PIC, form, sheet, scanner, and global states.

- [ ] **Step 1: Create a viewport test helper**

```dart
Future<void> withViewport(
  WidgetTester tester,
  Size size,
  Future<void> Function() body, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await body();
  expect(tester.takeException(), isNull);
}
```

Wrap tested widgets with `MediaQuery.withClampedTextScaling` or explicit `MediaQueryData` in each test when verifying 200% text scale.

- [ ] **Step 2: Add representative golden tests**

Capture 390 x 844 goldens for Login, Service Home, PIC Home, Catalog, Component Detail, Checking, Service Form, Order List, Order Detail, Invoice List, Invoice Empty, Invoice Failure, Component Picker, and non-camera scanner fallback.

- [ ] **Step 3: Generate and review goldens**

Run:

```bash
flutter test --update-goldens test/golden/redesign_golden_test.dart
flutter test test/golden/redesign_golden_test.dart
```

Expected: first command writes PNG baselines; second command PASS. Review each PNG against its mapped canvas before committing.

- [ ] **Step 4: Add critical end-to-end paths**

Update `integration_test/app_flow_test.dart` to cover:

1. Login to Service shell, open Asset, select component, open checking form, submit, observe success.
2. Admin switches to PIC, opens Orderan, opens order detail, returns, opens Invoice.
3. Invoice list remains navigable through empty or error retry.
4. Session expiry returns to the login recovery state.

Use mock/test gateway configuration; do not rely on production credentials.

- [ ] **Step 5: Run full automated verification**

Run:

```bash
flutter analyze
flutter test
flutter test integration_test/app_flow_test.dart
```

Expected: analyzer has no new diagnostics; all unit/widget tests PASS; integration flow PASS on the configured device.

- [ ] **Step 6: Perform physical Android checks**

Record in `docs/evidence/android-qa.md`:

- 320, 360, 390, and 430 logical width checks.
- Text scale 100%, 150%, and 200%.
- Keyboard visibility on Login, Create Order, Checking, Service, and Invoice forms.
- TalkBack labels for back, close, clear search, scanner, flash, PDF, and WhatsApp actions.
- Camera permission denial, permanent denial, unavailable camera, valid barcode, unknown barcode, ambiguous barcode, background/resume, and logout while scanner is open.
- Back navigation and draft-discard confirmation.

- [ ] **Step 7: Close the screen matrix**

Mark `Implemented=yes` only where code and tests pass. Mark `Verified=yes` only after visual comparison and device checks. Any remaining `no` is a release blocker and must name its failing command or missing device evidence.

- [ ] **Step 8: Commit final evidence**

```bash
git add test/golden integration_test/app_flow_test.dart docs/evidence/redesign-screen-matrix.md docs/evidence/android-qa.md
git commit -m "test: verify screen-to-code redesign"
```

---

## Release Gate

Implementation is complete only when all conditions are true:

- `flutter analyze` introduces no new diagnostics.
- `flutter test` passes.
- Integration test passes on the target Android configuration.
- Every canvas row in `docs/evidence/redesign-screen-matrix.md` is implemented or explicitly marked non-shippable with a product decision.
- No raw backend exception appears in user-visible text.
- No overflow occurs at 320, 360, 390, or 430 logical pixels.
- Core flows remain usable at 200% text scale.
- Service and PIC shells preserve their three destinations and scanner access.
- Invoice and order behavior still passes existing business tests.
- `SubmissionController` retry/idempotency tests still pass.
- Physical camera checks are recorded; widget tests are not treated as physical camera evidence.
