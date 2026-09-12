# Porcelain Service Ledger Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace every shipped Flutter screen’s mixed cobalt/blue styling with the approved Porcelain Service Ledger system while preserving workflows, navigation, role permissions, Indonesian product copy, and gateway behavior.

**Architecture:** Centralize global Material 3 roles in `lib/app/app_theme.dart`; shared widgets consume `ColorScheme`, `TextTheme`, and a small semantic `ThemeExtension` for operational statuses. Migrate screen families in dependency order, removing raw visual constants as each family moves. Finish by deleting web-only source references and rewriting `DESIGN.md` from the verified Flutter result.

**Tech Stack:** Flutter 3.44.8, Dart 3.12.2, Material 3, existing `flutter_test` and `integration_test`, Android emulator/ADB.

## Global Constraints

- Read `.agents/skills/impeccable/reference/craft-floor.md` immediately before the first UI edit.
- Preserve all workflows, navigation destinations, role permissions, gateway calls, and Indonesian product copy; copy changes are limited to demonstrably unclear labels or errors.
- Canvas `#F4F5F6`; surface `#FFFFFF`; Ink `#131517`; Stone `#737577`; Mist `#B3B5B7`; brand action `#CC62D5`.
- A screen or modal exposes at most one filled magenta action. When it is visible, navigation and selection states use Ink tonal treatment.
- Magenta never encodes success, warning, danger, payment, component condition, or connectivity.
- Use Android system Roboto through Material text roles; remove ad hoc `Inter` and `Plus Jakarta Sans` declarations.
- Card radius 20–24dp; button radius 16–20dp; badge radius 4–8dp; all touch targets at least 48×48dp with at least 8dp between independent targets.
- Material 3 controls, system/predictive Back, SafeArea/window insets, IME avoidance, semantic labels, and tooltips remain authoritative.
- The scanner is the only permanently dark surface.
- No new production dependency, remote font, image, gradient surface, dark theme, or web styling runtime.
- Do not change Supabase RPC names, request payloads, models, persistence, cache behavior, or scanner lifecycle.
- Existing tests are changed only when an observable contract intentionally changes. Do not add tests that assert token values, field forwarding, widget plumbing, or source text.

---

### Task 1: Establish the Material theme contract

**Files:**
- Modify: `lib/app/app_theme.dart`
- Modify: `lib/main.dart` only if system-overlay configuration is currently outside the app theme
- Verify: `test/widget_test.dart`

**Interfaces:**
- Produces: `AppTokens`, `OperationalColors`, and `ThemeData maintenanceTheme()`.
- Consumers: every later task through `Theme.of(context)`, `Theme.of(context).colorScheme`, and `Theme.of(context).extension<OperationalColors>()!`.

- [ ] **Step 1: Capture the current baseline**

Run:

```bash
flutter test test/widget_test.dart
```

Expected: existing smoke test passes before the theme migration.

- [ ] **Step 2: Replace visual primitives with semantic roles**

Implement this public shape in `lib/app/app_theme.dart`:

```dart
import 'package:flutter/material.dart';

abstract final class AppTokens {
  static const porcelain = Color(0xFFF4F5F6);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF131517);
  static const graphite = Color(0xFF333537);
  static const stone = Color(0xFF737577);
  static const mist = Color(0xFFB3B5B7);
  static const mistLight = Color(0xFFE3E4E6);
  static const magenta = Color(0xFFCC62D5);
  static const success = Color(0xFF23663A);
  static const successSurface = Color(0xFFE9F6EE);
  static const warning = Color(0xFF8A5A00);
  static const warningSurface = Color(0xFFFFF3D6);
  static const danger = Color(0xFFB42318);
  static const dangerSurface = Color(0xFFFDEBEC);

  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space24 = 24.0;
  static const space32 = 32.0;
  static const cardRadius = 22.0;
  static const controlRadius = 18.0;
  static const badgeRadius = 6.0;
  static const minTouchTarget = 48.0;
  static const maxContentWidth = 640.0;
}

@immutable
class OperationalColors extends ThemeExtension<OperationalColors> {
  const OperationalColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.danger,
    required this.onDanger,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color danger;
  final Color onDanger;

  @override
  OperationalColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? danger,
    Color? onDanger,
  }) =>
      OperationalColors(
        success: success ?? this.success,
        onSuccess: onSuccess ?? this.onSuccess,
        warning: warning ?? this.warning,
        onWarning: onWarning ?? this.onWarning,
        danger: danger ?? this.danger,
        onDanger: onDanger ?? this.onDanger,
      );

  @override
  OperationalColors lerp(OperationalColors? other, double t) {
    if (other == null) return this;
    return OperationalColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
    );
  }
}
```

Define `maintenanceTheme()` with:

- `brightness: Brightness.light`.
- `primary: AppTokens.magenta`, `onPrimary: AppTokens.white`.
- `secondary: AppTokens.ink`, `onSecondary: AppTokens.white`.
- `surface: AppTokens.white`, `onSurface: AppTokens.ink`.
- `surfaceContainerLow: AppTokens.porcelain`, `surfaceContainer: AppTokens.mistLight`.
- `outline: AppTokens.mist`, `outlineVariant: AppTokens.mistLight`.
- `error: AppTokens.danger`, `onError: AppTokens.white`.
- Roboto/system typography expressed only through `TextTheme` roles.
- Global themes for app bars, navigation bars, cards, inputs, chips, snackbars, dialogs, bottom sheets, filled/outlined/text buttons, icon buttons, dividers, progress indicators, and selection controls.
- `VisualDensity.standard`, `MaterialTapTargetSize.padded`, and transparent splash/highlight overrides only if existing press feedback remains visible.

- [ ] **Step 3: Format and analyze the theme**

Run:

```bash
dart format lib/app/app_theme.dart lib/main.dart
flutter analyze lib/app/app_theme.dart lib/main.dart
```

Expected: both commands exit 0; no undefined legacy `AppTokens` members remain in these files.

- [ ] **Step 4: Run the baseline smoke test**

Run:

```bash
flutter test test/widget_test.dart
```

Expected: PASS; application boot behavior is unchanged.

- [ ] **Step 5: Commit the theme contract**

```bash
git add lib/app/app_theme.dart lib/main.dart
git commit -m "feat: establish porcelain material theme"
```

---

### Task 2: Migrate the app shell and shared components

**Files:**
- Modify: `lib/app/app.dart`
- Modify: `lib/shared/bottom_nav_bar.dart`
- Modify: `lib/shared/async_state_view.dart`
- Modify: `lib/shared/pressable.dart`
- Modify: `lib/shared/condition_badge.dart`
- Modify: `lib/features/home/home_skeleton.dart`
- Verify: `test/home_screen_test.dart`
- Verify: `test/admin_mode_switch_test.dart`
- Verify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `AppTokens`, `OperationalColors`, and `maintenanceTheme()` from Task 1.
- Produces: one role-aware Porcelain app shell and shared feedback/status components for every screen family.

- [ ] **Step 1: Run shell behavior tests before editing**

```bash
flutter test test/home_screen_test.dart test/admin_mode_switch_test.dart test/widget_test.dart
```

Expected: PASS.

- [ ] **Step 2: Migrate the root shell**

In `lib/app/app.dart`:

- Keep authentication, session refresh, splash, role routing, navigation indices, `AnimationController`, scanner opening, and Admin mode switching unchanged.
- Replace `Color(0xFFFBFBFB)`, `Color(0xFF18181B)`, cobalt, and repeated text styles with `Theme.of(context)` roles.
- Keep the floating navigation composition only if it satisfies 48dp touch targets and safe-area clearance; otherwise use Material `NavigationBar` without changing destination order.
- Use fade-through semantics for role-mode content switching through `AnimatedSwitcher` with 180ms fade and 4dp vertical transition. If `MediaQuery.disableAnimationsOf(context)` is true, use `Duration.zero` and no translation.
- Ensure visible primary CTAs own magenta; selected navigation uses Ink tonal styling on those screens.

- [ ] **Step 3: Migrate shared widgets**

Apply these contracts:

```dart
final colors = Theme.of(context).colorScheme;
final textTheme = Theme.of(context).textTheme;
final operational = Theme.of(context).extension<OperationalColors>()!;
final disableAnimations = MediaQuery.disableAnimationsOf(context);
```

- `bottom_nav_bar.dart`: use theme roles, preserve all labels and callbacks, keep each destination at least 48dp.
- `async_state_view.dart`: map loading to themed progress, failure to `colors.error`, and retry to an outlined or filled action according to whether it is the only action.
- `pressable.dart`: retain visible pressed feedback and semantics; animation duration is zero when animations are disabled.
- `condition_badge.dart`: map condition meaning to `OperationalColors`; retain text labels.
- `home_skeleton.dart`: use `surfaceContainer` and `outlineVariant`, preserve final layout dimensions, and disable shimmer motion when animations are disabled.

- [ ] **Step 4: Verify shell behavior**

```bash
dart format lib/app/app.dart lib/shared lib/features/home/home_skeleton.dart
flutter analyze lib/app/app.dart lib/shared lib/features/home/home_skeleton.dart
flutter test test/home_screen_test.dart test/admin_mode_switch_test.dart test/widget_test.dart
```

Expected: format and analyze exit 0; all three test files pass.

- [ ] **Step 5: Commit the shared migration**

```bash
git add lib/app/app.dart lib/shared lib/features/home/home_skeleton.dart
git commit -m "feat: migrate shared shell to porcelain system"
```

---

### Task 3: Redesign splash, login, and authenticated entry

**Files:**
- Modify: `lib/features/splash/splash_screen.dart`
- Modify: `lib/features/auth/login_screen.dart`
- Verify: `test/widget_test.dart`
- Verify: `integration_test/app_flow_test.dart`

**Interfaces:**
- Consumes: theme and shell from Tasks 1–2.
- Produces: accessible Porcelain entry states without changing authentication calls or splash completion.

- [ ] **Step 1: Record current login behavior**

```bash
flutter test test/widget_test.dart
```

Expected: PASS, including login rendering and app boot.

- [ ] **Step 2: Migrate splash and login**

- Keep the MGRS icon, Lottie/Rive lifecycle, credentials controllers, password visibility, submit state, `gateway.signIn`, `onSignedIn`, and error messages unchanged.
- Replace the cobalt login background with Porcelain; use a compact Ink brand panel only if it does not reduce field contrast.
- Use one white form surface with a 22dp radius and Mist outline. Remove the heavy drop shadow.
- Use `headlineSmall`, `bodyMedium`, and `labelLarge`; remove every `fontFamily`, direct font size, and repeated raw neutral.
- Make the submit button the single filled magenta action. Password visibility remains an Ink icon button with tooltip and 48dp target.
- Preserve keyboard submission and scrolling above the IME.
- When authentication fails, render the existing message in `dangerSurface`/`danger` and retain the entered username.

- [ ] **Step 3: Verify entry behavior**

```bash
dart format lib/features/splash/splash_screen.dart lib/features/auth/login_screen.dart
flutter analyze lib/features/splash/splash_screen.dart lib/features/auth/login_screen.dart
flutter test test/widget_test.dart
```

Expected: all commands exit 0; login success/failure behavior is unchanged.

- [ ] **Step 4: Commit entry surfaces**

```bash
git add lib/features/splash/splash_screen.dart lib/features/auth/login_screen.dart
git commit -m "feat: redesign authenticated entry surfaces"
```

---

### Task 4: Migrate technician home, scan, assets, and maintenance

**Files:**
- Modify: `lib/features/home/home_screen.dart`
- Modify: `lib/features/scan/scan_screen.dart`
- Modify: `lib/features/components/asset_catalog_screen.dart`
- Modify: `lib/features/components/component_detail_screen.dart`
- Modify: `lib/features/maintenance/action_center_screen.dart`
- Modify: `lib/features/maintenance/checking_screen.dart`
- Modify: `lib/features/history/history_screen.dart`
- Modify: `lib/features/history/history_detail_screen.dart`
- Verify: `test/home_screen_test.dart`
- Verify: `test/flow_screens_test.dart`
- Verify: `test/submission_controller_test.dart`

**Interfaces:**
- Consumes: Task 2 shared shell/status contracts.
- Produces: complete technician workflow from scan/manual lookup through condition/service submission and history.

- [ ] **Step 1: Run technician-flow baselines**

```bash
flutter test test/home_screen_test.dart test/flow_screens_test.dart test/submission_controller_test.dart
```

Expected: PASS.

- [ ] **Step 2: Migrate technician home and action center**

- Preserve all metric loading, upcoming-order reads visible to technicians, refresh behavior, profile sheet, and navigation callbacks.
- Convert headers to `headlineSmall`/`bodyMedium`; white record cards sit directly on Porcelain without nested decorative containers.
- Use inventory-label badges for active period, complete, overdue, service, and condition states through semantic colors.
- Make scan or condition-update the single filled magenta action per viewport; render competing actions outlined or Ink tonal.
- Preserve skeleton geometry and existing empty/error messages.

- [ ] **Step 3: Migrate scanner and manual lookup**

- Keep the live camera view black and preserve controller creation, barcode detection, duplicate suppression, manual entry, component-kind selection, pause/resume, lifecycle handling, and result navigation.
- Retain white scanner framing and use amber only for active scan-mode emphasis.
- Use Material top controls with semantic labels and 48dp targets.
- The manual-entry sheet uses Porcelain/white surfaces; its submit action may use magenta because it is a separate modal.
- Do not apply Porcelain over the camera preview or reduce barcode contrast.

- [ ] **Step 4: Migrate asset catalog and component detail**

- Preserve pagination, filters, search, component loading, history loading, read-only PIC behavior, order-usage history, and action callbacks.
- Use Ink selected filters when a magenta primary action is visible; otherwise one active filter may use magenta.
- Component code is `titleLarge`; kind and last-check metadata use `bodyMedium`/`labelMedium`.
- Condition badges use semantic palette and text. Cards use 22dp radius and Mist outline, with no default shadow.

- [ ] **Step 5: Migrate checking, service, and history**

- Preserve form fields, enums, validation, review/submit sequence, idempotent request behavior, conflict recovery, correction flow, date/activity filters, and RPC calls.
- Use one filled magenta submit action. Review/back/cancel remain outlined or text.
- Keep danger red for damaged/service conditions only where the domain semantics require it; never remap those states to magenta.
- Error, empty, loading, and success states follow the shared contracts.
- Ensure form actions scroll above the keyboard; do not add a fixed overlay above focused fields.

- [ ] **Step 6: Verify technician workflows**

```bash
dart format lib/features/home/home_screen.dart lib/features/scan lib/features/components lib/features/maintenance lib/features/history
flutter analyze lib/features/home/home_screen.dart lib/features/scan lib/features/components lib/features/maintenance lib/features/history
flutter test test/home_screen_test.dart test/flow_screens_test.dart test/submission_controller_test.dart
```

Expected: analyze exits 0; all technician workflow tests pass.

- [ ] **Step 7: Commit technician surfaces**

```bash
git add lib/features/home/home_screen.dart lib/features/scan lib/features/components lib/features/maintenance lib/features/history
git commit -m "feat: redesign technician workflows"
```

---

### Task 5: Migrate schedules, orders, and unit allocation

**Files:**
- Modify: `lib/features/schedule/schedule_screen.dart`
- Modify: `lib/features/schedule/upcoming_orders_screen.dart`
- Modify: `lib/features/schedule/order_detail_screen.dart`
- Modify: `lib/features/schedule/create_order_screen.dart`
- Modify: `lib/features/schedule/component_picker_sheet.dart`
- Modify: `lib/features/schedule/unit_allocation_card.dart`
- Verify: `test/order_cancellation_test.dart`
- Verify: `test/unit_allocation_flow_test.dart`
- Verify: `test/unit_allocation_card_test.dart`
- Verify: `test/component_picker_sheet_test.dart`

**Interfaces:**
- Consumes: theme, shared state, and navigation contracts.
- Produces: Porcelain scheduling/order flow with unchanged order and allocation models/gateway calls.

- [ ] **Step 1: Run schedule and allocation baselines**

```bash
flutter test test/order_cancellation_test.dart test/unit_allocation_flow_test.dart test/unit_allocation_card_test.dart test/component_picker_sheet_test.dart
```

Expected: PASS.

- [ ] **Step 2: Migrate schedule and order lists**

- Preserve tabs/filters, search, pagination, refresh, order grouping, counts, create-order navigation, and order selection.
- Use `headlineSmall` for screen titles, `titleMedium` for event names, and `labelMedium` for dates/PIC/status.
- Use white outlined record cards. Active filters use Ink tonal when “Orderan Baru” is visible as magenta.
- Keep empty and failure actions explicit and reachable.

- [ ] **Step 3: Migrate order creation and detail**

- Preserve controllers, validation, dates, event/location/PIC fields, invoice creation, cancellation confirmation, status transitions, and gateway payloads.
- “Simpan/Buat Orderan” is the sole filled magenta action in creation. Cancellation remains red text/outlined and uses a Material confirmation dialog.
- Replace all hard-coded fonts, neutral colors, blue accents, radii, and ad hoc shadows with theme roles.
- Ensure long event names and locations wrap without covering status or actions.

- [ ] **Step 4: Migrate allocation and component selection**

- Preserve scan/manual allocation, recommended-freshest ordering, clear-selection behavior, partial/complete state, usage counts, and return values.
- Use semantic success for complete, warning for partial, and Stone for optional/unselected.
- The component picker remains a Material bottom sheet with 48dp rows and system Back dismissal.
- Scanner entry is the only filled magenta action in the allocation surface; individual selection indicators use Ink tonal.

- [ ] **Step 5: Verify schedules and allocations**

```bash
dart format lib/features/schedule
flutter analyze lib/features/schedule
flutter test test/order_cancellation_test.dart test/unit_allocation_flow_test.dart test/unit_allocation_card_test.dart test/component_picker_sheet_test.dart
```

Expected: analyze exits 0; all four test files pass.

- [ ] **Step 6: Commit schedule and allocation surfaces**

```bash
git add lib/features/schedule
git commit -m "feat: redesign schedules and allocation"
```

---

### Task 6: Migrate PIC home and invoice lists

**Files:**
- Modify: `lib/features/home/pic_home_screen.dart`
- Modify: `lib/features/invoices/invoice_list_screen.dart`
- Modify: `lib/features/invoices/create_invoice_dialog.dart`
- Verify: `test/pic_flow_test.dart`
- Verify: `test/admin_mode_switch_test.dart`

**Interfaces:**
- Consumes: Task 2 role-aware shell and Task 5 order visuals.
- Produces: coherent PIC/Admin entry, invoice filtering, and invoice creation.

- [ ] **Step 1: Run PIC baselines**

```bash
flutter test test/pic_flow_test.dart test/admin_mode_switch_test.dart
```

Expected: PASS.

- [ ] **Step 2: Migrate PIC home**

- Preserve order loading, upcoming/past grouping, profile sheet, Admin mode switch, order/invoice navigation, refresh, and error states.
- Use the same Porcelain hierarchy as technician home so the mode change feels like a workspace change, not a different product.
- Keep the current mode label visible. Use Ink tonal treatment for the mode selector when a primary action is present.
- Do not invent metrics or claims.

- [ ] **Step 3: Migrate invoice list and creation**

- Preserve invoice loading, automatic/manual source filter, payment filter, search, order preselection, reimbursement path, reference generation, validation, submit, and callbacks.
- Use semantic payment badges: success for paid, warning for partial, danger for cancelled/overdue only when domain data says so, neutral for unpaid when urgency is absent.
- “Invoice” or “Buat Invoice” is the sole filled magenta action. Source/payment filters use Ink or semantic treatments.
- Creation remains a Material dialog on wide layouts and a full-height/bottom-sheet-compatible surface on compact height, without hiding actions behind the keyboard.

- [ ] **Step 4: Verify PIC and invoice entry flows**

```bash
dart format lib/features/home/pic_home_screen.dart lib/features/invoices/invoice_list_screen.dart lib/features/invoices/create_invoice_dialog.dart
flutter analyze lib/features/home/pic_home_screen.dart lib/features/invoices/invoice_list_screen.dart lib/features/invoices/create_invoice_dialog.dart
flutter test test/pic_flow_test.dart test/admin_mode_switch_test.dart
```

Expected: analyze exits 0; both tests pass.

- [ ] **Step 5: Commit PIC surfaces**

```bash
git add lib/features/home/pic_home_screen.dart lib/features/invoices/invoice_list_screen.dart lib/features/invoices/create_invoice_dialog.dart
git commit -m "feat: redesign pic and invoice entry flows"
```

---

### Task 7: Migrate invoice editing, payment, and PDF feedback

**Files:**
- Modify: `lib/features/invoices/invoice_builder_dialog.dart`
- Modify: `lib/features/invoices/invoice_adjustment_editor.dart`
- Modify: `lib/features/invoices/quick_payment_dialog.dart`
- Modify: `lib/features/invoices/pdf/invoice_pdf_dialogs.dart`
- Do not modify: `lib/features/invoices/pdf/invoice_pdf_export_service.dart`
- Do not modify: `lib/features/invoices/pdf/invoice_pdf_download.dart`
- Do not modify: `lib/services/native_pdf_service.dart`
- Verify: `test/invoice_pdf_test.dart`
- Verify: `test/native_pdf_service_test.dart`

**Interfaces:**
- Consumes: invoice list/model behavior and operational payment colors.
- Produces: consistent invoice editing/payment/export UI without altering PDF bytes, filenames, downloads, previews, or sharing.

- [ ] **Step 1: Run invoice/PDF baselines**

```bash
flutter test test/invoice_pdf_test.dart test/native_pdf_service_test.dart
```

Expected: PASS.

- [ ] **Step 2: Migrate builder and adjustment editor**

- Preserve all controllers, calculations, adjustment add/remove, edit/preview mode, save input, selected order, footer actions, and callback behavior.
- Keep the approved 48dp footer action row and 3:2 payment/completion ratio. Translate surfaces to Porcelain/white/Ink/Mist and make only the current primary completion action magenta.
- Download/share remain 48dp icon controls with tooltips; share may keep semantic green because it denotes the external share action, not brand priority.
- Use theme text roles and remove direct `Plus Jakarta Sans` declarations.

- [ ] **Step 3: Migrate payment states**

- Preserve validation, payment status options, paid amount handling, remaining balance calculation, submit, and success/failure messages.
- Paid remains green, partial amber, cancelled/danger red, and unpaid neutral unless the model supplies overdue meaning.
- Save is the sole filled magenta action. Status selectors use semantic or Ink tonal treatment.

- [ ] **Step 4: Migrate PDF progress and completion dialogs**

- Preserve modal progress, non-dismissible processing state, error recovery, saved location, open, share, filename, and native service calls.
- Use standard Material dialog elevation and Porcelain/white/Ink roles.
- Progress uses the themed indicator; success uses semantic green. Open/share/download actions follow one-primary hierarchy without changing callback order.

- [ ] **Step 5: Verify invoice and PDF behavior**

```bash
dart format lib/features/invoices/invoice_builder_dialog.dart lib/features/invoices/invoice_adjustment_editor.dart lib/features/invoices/quick_payment_dialog.dart lib/features/invoices/pdf/invoice_pdf_dialogs.dart
flutter analyze lib/features/invoices
flutter test test/invoice_pdf_test.dart test/native_pdf_service_test.dart
```

Expected: analyze exits 0; both tests pass; PDF generation code remains unchanged.

- [ ] **Step 6: Commit invoice detail surfaces**

```bash
git add lib/features/invoices/invoice_builder_dialog.dart lib/features/invoices/invoice_adjustment_editor.dart lib/features/invoices/quick_payment_dialog.dart lib/features/invoices/pdf/invoice_pdf_dialogs.dart
git commit -m "feat: redesign invoice detail interactions"
```

---

### Task 8: Remove visual-system drift and obsolete references

**Files:**
- Modify: all changed `lib/**/*.dart` files with remaining visual literals
- Remove: `variables.css`
- Remove: `theme.css`
- Remove: `tokens.json`
- Preserve until Task 10: `DESIGN.md`
- Modify: `.gitignore` to add `.superpowers/` if not already ignored

**Interfaces:**
- Consumes: all migrated screen families.
- Produces: one Flutter visual authority with no copied web-token runtime or second visual system.

- [ ] **Step 1: Scan for legacy visual literals**

Use repository search, not a shell regex tool, for:

```text
fontFamily: 'Inter'
fontFamily: 'Plus Jakarta Sans'
0xFF147CC1
0xFF2563EB
0xFF1C3E66
0xFFF4F8FC
```

Expected: each remaining match is classified as an intentional domain semantic, a scanner-only color, or migration debt to remove. No match is ignored because it looks small.

- [ ] **Step 2: Remove remaining presentation literals**

For each migration-debt match:

- Replace neutral/brand colors with `ColorScheme` or `AppTokens` roles.
- Replace semantic status colors with `OperationalColors`.
- Replace font families/sizes with `TextTheme` roles.
- Replace repeated spacing/radii with `AppTokens`.
- Retain raw colors only for bounded data visualization or platform integration where the value is genuinely local and comment the semantic reason.

- [ ] **Step 3: Remove copied web artifacts**

Delete `variables.css`, `theme.css`, and `tokens.json` after confirming no build/config/import references them. They were approved as source references only and are now represented in Dart. Do not delete any Flutter, Android, iOS, Supabase, or documentation asset.

- [ ] **Step 4: Ignore companion session output**

Add this exact line to `.gitignore` if absent:

```gitignore
.superpowers/
```

- [ ] **Step 5: Analyze the clean cutover**

```bash
dart format lib
flutter analyze
```

Expected: exits 0; no unused legacy token imports or undefined theme roles.

- [ ] **Step 6: Commit cleanup**

```bash
git add lib .gitignore
git rm variables.css theme.css tokens.json
git commit -m "refactor: remove legacy visual system drift"
```

---

### Task 9: Run behavioral regression verification

**Files:**
- Modify only tests whose user-observable contract intentionally changed
- Verify: `test/`
- Verify: `integration_test/app_flow_test.dart`

**Interfaces:**
- Consumes: complete migrated application.
- Produces: evidence that visual replacement did not alter product behavior.

- [ ] **Step 1: Run focused screen-family tests**

```bash
flutter test test/home_screen_test.dart test/admin_mode_switch_test.dart test/flow_screens_test.dart test/pic_flow_test.dart test/order_cancellation_test.dart test/unit_allocation_flow_test.dart test/unit_allocation_card_test.dart test/component_picker_sheet_test.dart test/invoice_pdf_test.dart test/native_pdf_service_test.dart test/submission_controller_test.dart
```

Expected: PASS.

- [ ] **Step 2: Run the full static and unit/widget suite**

```bash
flutter analyze
flutter test
```

Expected: both commands exit 0 with no errors and all tests pass.

- [ ] **Step 3: Run the synthetic integration flow**

Start or select the existing Android emulator, then run:

```bash
flutter test integration_test/app_flow_test.dart -d mgrs_phase2_x86_qa
```

Expected: PASS for login, lookup, checking/service submission, schedule, and history paths supported by the synthetic QA gateway. If the emulator ID differs, use the ID reported by `flutter devices`; do not change the test to avoid a device setup problem.

- [ ] **Step 4: Commit only legitimate test contract updates**

If no tests changed, skip the commit. If observable labels/semantics intentionally changed:

```bash
git add test integration_test
git commit -m "test: align ui behavior contracts"
```

---

### Task 10: Perform bounded Android visual verification and document the shipped world

**Files:**
- Create: `.impeccable/review/android-phone.png`
- Create: `.impeccable/review/android-phone-font-130.png`
- Modify: `DESIGN.md`
- Remove or archive outside runtime: copied Glow contents currently in `DESIGN.md`
- Verify: `PRODUCT.md`
- Verify: `docs/superpowers/specs/2026-09-12-porcelain-service-ledger-design.md`

**Interfaces:**
- Consumes: verified application from Task 9.
- Produces: emulator evidence and final durable `DESIGN.md` matching shipped Flutter code.

- [ ] **Step 1: Launch the real application on Android**

```bash
flutter run -d mgrs_phase2_x86_qa --dart-define-from-file=config/development.local.json
```

Expected: app installs and opens on the emulator. Use the actual device ID from `flutter devices` if the recorded emulator name is unavailable.

- [ ] **Step 2: Exercise the visual review matrix once**

Inspect in one bounded pass:

- Login default, loading, and authentication error.
- Technician home, profile, navigation, action center, component catalog, scanner, manual lookup, detail, checking/service form, schedule, and history.
- PIC home, Admin mode switch, order list/detail/create, allocation picker, invoice list/create/edit/payment, and PDF progress/success.
- Loading, empty, failure/retry, destructive confirmation, success, long text, keyboard-open form, and scanner lifecycle states.
- Status/navigation bars, display cutout handling, system Back, 48dp targets, and no content hidden behind the IME.

Record all material defects before editing. Do not fix one screen and recapture repeatedly.

- [ ] **Step 3: Capture the normal-scale phone**

Confirm `adb devices` reports exactly one connected emulator, then run:

```bash
adb exec-out screencap -p > .impeccable/review/android-phone.png
```

Expected: PNG shows the reviewed MGRS surface at the top of the intended screen, with no black frame except the scanner camera surface.

- [ ] **Step 4: Capture font scale 1.3**

With the same sole connected emulator, run:

```bash
adb shell settings put system font_scale 1.3
adb exec-out screencap -p > .impeccable/review/android-phone-font-130.png
adb shell settings put system font_scale 1.0
```

Expected: labels remain readable; controls do not overlap or clip; font scale is restored to 1.0.

- [ ] **Step 5: Apply one batched correction pass**

Fix every material issue found in Steps 2–4 together. Re-run only the targeted tests covering touched screens plus `flutter analyze`. Capture one final confirmation round; stop visual polishing after that second round.

- [ ] **Step 6: Rewrite the durable design contract**

Replace the copied Glow `DESIGN.md` with the shipped Porcelain Service Ledger truth:

- Android/Material 3 scope and Operate mode.
- Exact color roles and semantic restrictions.
- Roboto Material type-role mapping.
- Spacing, shape, elevation, navigation, form, card, badge, dialog, bottom-sheet, scanner, status, motion, accessibility, and responsive rules.
- Paths to `lib/app/app_theme.dart`, shared widgets, representative feature screens, and emulator evidence.
- Explicit bans on crypto/web/iPhone/hero language, magenta status encoding, raw per-screen typography, duplicate visual systems, and unverified production claims.

Do not copy development-only direction prose into runtime source. Ensure `DESIGN.md` describes what shipped rather than what was intended.

- [ ] **Step 7: Final verification**

```bash
flutter analyze
flutter test
```

Expected: both commands exit 0; all tests pass after the correction batch and documentation update.

- [ ] **Step 8: Commit the finished world and evidence**

```bash
git add DESIGN.md lib .impeccable/review/android-phone.png .impeccable/review/android-phone-font-130.png
git commit -m "feat: complete porcelain service ledger redesign"
```

Physical camera/barcode testing, production deployment, signing, real QA accounts, and cross-application interoperability remain release gates; emulator evidence does not close them.
