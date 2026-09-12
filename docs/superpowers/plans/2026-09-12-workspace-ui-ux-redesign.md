# Workspace UI/UX Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current mixed Flutter navigation and liquid-glass visual system with two role-aware Android workspaces: PIC MGRS for orderan/invoice and Tim Lapangan for maintenance, field context, and installation confirmation.

**Architecture:** Keep the existing `MaintenanceGateway`, Supabase contracts, authentication, and submission semantics as the data boundary. Replace the single `MaintenanceHome` shell with a role-derived workspace shell that owns navigation and delegates domain screens; introduce a semantic Material 3 token/component layer; then migrate existing screens to consume that layer and remove obsolete custom navigation. Add installation confirmation only after the live gateway contract is identified; if no authorized operation exists, expose the read-only context and an explicit unavailable state rather than inventing a write path.

**Tech Stack:** Flutter 3/Dart 3.12, Material 3, Supabase Flutter, `mobile_scanner`, existing gateway and domain models, Flutter widget/unit tests, Android emulator smoke verification.

## Global Constraints

- Use `C:\Users\ogi\Downloads\DESIGN-apple.md` as visual direction only; do not copy marketing-gallery or iOS/web-only patterns.
- Apply globally installed `antislop`, `antislop-ui`, `antislop-human`, and `antislop-layoutmobile` during every UI task.
- Product has exactly two workspaces: `PIC MGRS` and `Tim Lapangan`.
- Admin can access both workspaces; PIC MGRS can access only PIC MGRS; Tim Lapangan can access only Tim Lapangan.
- Workspace switching changes visible navigation, never server authorization or authenticated actor identity.
- PIC MGRS navigation is `Beranda`, `Orderan`, `Invoice`, `Profil`.
- Tim Lapangan navigation is `Scan`, `Berkala`, `Komponen`, `Riwayat`; pemeriksaan and servis are contextual actions.
- Preserve existing authenticated session, gateway contracts, atomic writes, idempotency, conflict handling, and history behavior.
- Do not silently migrate persisted role values; legacy role mapping must be explicit and verified before release.
- Use Material `NavigationBar` on compact widths and `NavigationRail` or drawer on expanded widths.
- Every interactive target is at least 48dp with at least 8dp separation and an accessible label.
- Support light/dark theme, edge-to-edge insets, IME resize, system Back, predictive Back, and 1.3 text scale without clipping primary actions.
- No fabricated metrics, names, avatars, statuses, invoice values, maintenance defaults, or example data in initial form values.
- Checking forms begin with no condition/usability selected; service forms begin empty; example copy belongs only in hint text.
- Every data view exposes loading, empty, error, retry, and permission states; forms expose idle, validation, saving, success, conflict, uncertain, and discard states.
- Run only focused tests during each task; run the complete analyzer/test/build verification once at the final checkpoint.

---

## File Map and Ownership

### Shell and shared UI

- Modify `lib/app/app.dart`: role/workspace routing, workspace selection, shell lifecycle, system back behavior.
- Modify `lib/app/gateway.dart`: product-facing role/workspace derivation only; preserve legacy persisted values and existing RPC behavior.
- Modify `lib/app/app_theme.dart`: semantic Material 3 light/dark tokens, text roles, component defaults, 48dp minimums.
- Create `lib/shared/mgrs_app_shell.dart`: adaptive shell, top app bar, navigation, workspace switcher, selected destination semantics.
- Create `lib/shared/mgrs_components.dart`: shared cards, state views, search/filter controls, form sections, save action bar, discard dialog.
- Modify `lib/shared/async_state_view.dart`: consistent loading/error/empty/retry/permission states and theme tokens.
- Modify `lib/shared/condition_badge.dart`: text-first semantic status rendering.
- Remove usage of `lib/shared/bottom_nav_bar.dart`; delete it only after all callers are migrated.
- Modify `lib/shared/pressable.dart`: replace scale/haptic decoration with accessible Material-compatible feedback and reduced-motion behavior.

### PIC MGRS workspace

- Modify `lib/features/home/pic_home_screen.dart`: order/invoice landing, real data only, no bento/marketing metrics.
- Modify `lib/features/schedule/upcoming_orders_screen.dart` and `lib/features/schedule/order_detail_screen.dart`: PIC order list/detail navigation and field-context entry.
- Modify `lib/features/schedule/create_order_screen.dart`, `unit_allocation_card.dart`, and `component_picker_sheet.dart`: preserve existing order/allocation actions while migrating controls and spacing.
- Modify `lib/features/invoices/invoice_list_screen.dart` plus invoice dialogs/editors: PIC-only invoice surface with explicit loading/error/empty and 48dp controls.

### Tim Lapangan workspace

- Modify `lib/features/scan/scan_screen.dart`: scanner-first entry, manual fallback, lifecycle cleanup, accessible controls, no decorative lens dock.
- Modify `lib/features/schedule/schedule_screen.dart`: periodic work destination and task state separation.
- Modify `lib/features/components/asset_catalog_screen.dart` and `component_detail_screen.dart`: component browsing, identity, condition, maintenance actions, and relevant order/pasangan context.
- Modify `lib/features/maintenance/checking_screen.dart` and `action_center_screen.dart`: honest empty forms, explicit review/save/conflict/retry flow.
- Modify `lib/features/history/history_screen.dart` and `history_detail_screen.dart`: history destination with real pagination/state handling.
- Create `lib/features/field/installation_confirmation_screen.dart` only after an authorized backend operation is verified; otherwise create a read-only unavailable state in the relevant detail screen and record the missing contract.

### Verification and docs

- Modify/add focused tests under `test/` for role/workspace selection, adaptive navigation, form defaults, and installation-unit selection semantics.
- Use `integration_test/` only for the final Android smoke path if the existing harness supports it.
- Update `DESIGN.md` only if shipped implementation decisions materially differ from the current contract.

---

### Task 1: Establish role and workspace contracts

**Files:**
- Modify: `lib/app/gateway.dart:18-87`
- Modify: `lib/app/app.dart:146-349`
- Create: `test/unit_workspace_access_test.dart`

**Interfaces:**
- Produces `enum MgrsWorkspace { pic, field }`.
- Produces `UserProfile.productRole`, `UserProfile.allowedWorkspaces`, and `UserProfile.defaultWorkspace` without changing raw `role` values.
- Produces `WorkspaceSelection` behavior: Admin has two choices; PIC MGRS has only PIC; Tim Lapangan has only field.
- Later shell tasks consume `MgrsWorkspace` and `UserProfile.allowedWorkspaces`.

- [ ] **Step 1: Write failing contract tests**

```dart
void main() {
  test('admin can use exactly two product workspaces', () {
    const user = UserProfile('1', 'Admin');
    expect(user.allowedWorkspaces, {
      MgrsWorkspace.pic,
      MgrsWorkspace.field,
    });
  });

  test('legacy field roles resolve to Tim Lapangan without rewriting raw role', () {
    const user = UserProfile('1', 'Tim Service');
    expect(user.role, 'Tim Service');
    expect(user.productRole, ProductRole.timLapangan);
    expect(user.allowedWorkspaces, {MgrsWorkspace.field});
  });

  test('PIC MGRS cannot enter Tim Lapangan workspace', () {
    const user = UserProfile('1', 'PIC Pemasangan');
    expect(user.productRole, ProductRole.picMgrs);
    expect(user.allowedWorkspaces, {MgrsWorkspace.pic});
    expect(user.defaultWorkspace, MgrsWorkspace.pic);
  });
}
```

- [ ] **Step 2: Run focused tests and verify failure**

Run: `flutter test test/unit_workspace_access_test.dart`
Expected: FAIL because `MgrsWorkspace`, `ProductRole`, and the derived properties do not exist.

- [ ] **Step 3: Implement the smallest role/workspace model**

Add product-facing enums and derived properties in `gateway.dart`:

```dart
enum MgrsWorkspace { pic, field }
enum ProductRole { admin, picMgrs, timLapangan }

extension ProductRoleLabel on ProductRole {
  String get label => switch (this) {
    ProductRole.admin => 'Admin',
    ProductRole.picMgrs => 'PIC MGRS',
    ProductRole.timLapangan => 'Tim Lapangan',
  };
}
```

Map `Admin` to both workspaces, `PIC Pemasangan` to PIC MGRS, and both `Tim Service`/`Tim Pemasangan` to Tim Lapangan. Keep `UserProfile.role` unchanged and make unknown roles return an empty workspace set.

- [ ] **Step 4: Make app startup derive a safe initial workspace**

Replace the old `AdminAppMode`-driven startup decision in `app.dart` with `MgrsWorkspace` state. Reject an invalid persisted/selected workspace by falling back to `defaultWorkspace`; do not grant access through UI state.

- [ ] **Step 5: Run focused tests and analyzer**

Run: `flutter test test/unit_workspace_access_test.dart`
Expected: PASS.

Run: `flutter analyze lib/app/gateway.dart lib/app/app.dart test/unit_workspace_access_test.dart`
Expected: no new diagnostics in modified files.

- [ ] **Step 6: Commit**

```bash
git add lib/app/gateway.dart lib/app/app.dart test/unit_workspace_access_test.dart
git commit -m "feat: define product workspace access contract"
```

### Task 2: Replace theme and shared primitives

**Files:**
- Modify: `lib/app/app_theme.dart`
- Create: `lib/shared/mgrs_app_shell.dart`
- Create: `lib/shared/mgrs_components.dart`
- Modify: `lib/shared/async_state_view.dart`
- Modify: `lib/shared/condition_badge.dart`
- Modify: `lib/shared/pressable.dart`
- Create: `test/widget_shared_components_test.dart`

**Interfaces:**
- `MGRSAppShell({required MgrsWorkspace workspace, required UserProfile user, required int selectedIndex, required ValueChanged<int> onDestinationSelected, required Widget child, ValueChanged<MgrsWorkspace>? onWorkspaceChanged})`.
- `AdaptiveNavigation` switches between `NavigationBar` and `NavigationRail` based on available width.
- `AsyncStateView` gains explicit `empty`, `error`, and `permission` builders while retaining existing call compatibility until migration is complete.
- `SaveActionBar` owns disabled/submitting/retry presentation; forms remain responsible for submission semantics.

- [ ] **Step 1: Add token/theme tests**

```dart
testWidgets('theme gives primary controls a 48dp minimum', (tester) async {
  await tester.pumpWidget(MaterialApp(
    theme: maintenanceTheme(),
    home: FilledButton(onPressed: () {}, child: const Text('Simpan')),
  ));
  final size = tester.getSize(find.byType(FilledButton));
  expect(size.height, greaterThanOrEqualTo(48));
});
```

- [ ] **Step 2: Run the focused widget test before implementation**

Run: `flutter test test/widget_shared_components_test.dart`
Expected: FAIL because the test file and new shared contract are not implemented.

- [ ] **Step 3: Replace `AppTokens` and `ThemeData`**

Use semantic roles from `DESIGN.md`: canvas `#FFFFFF`, subtle canvas `#F5F5F7`, ink `#1D1D1F`, muted ink `#6E6E73`, divider `#E0E0E0`, Action Blue `#0066CC`, focus blue `#0071E3`, success `#2E7D32`, warning `#956400`, danger `#B42318`. Define both `ThemeMode.light` and `ThemeMode.dark`; use `ColorScheme.fromSeed` only as a base, then override semantic roles. Configure text styles through `ThemeData.textTheme`, fields, cards, snackbars, chips, dialogs, and minimum button sizes.

- [ ] **Step 4: Implement adaptive shell and shared primitives**

Build flat Material components with one responsibility each. Use `LayoutBuilder` to choose compact `NavigationBar` versus expanded `NavigationRail`; make the active workspace and destination available to semantics. Add `WorkspaceSwitcher` with exactly two labels for Admin. Do not carry over BackdropFilter, drag-to-scrub, chromatic lens, gradients, or floating dock behavior.

- [ ] **Step 5: Normalize state components and press feedback**

Add explicit loading/empty/error/permission/conflict views. Use `Semantics`, `Tooltip`, and native `InkWell`/Material states. `PressableScale` must not scale when reduced motion is enabled and must not be used as a substitute for a button semantic role.

- [ ] **Step 6: Run focused tests**

Run: `flutter test test/widget_shared_components_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/app/app_theme.dart lib/shared test/widget_shared_components_test.dart
git commit -m "feat: add material workspace design system"
```

### Task 3: Wire the two adaptive workspace shells

**Files:**
- Modify: `lib/app/app.dart`
- Modify: `lib/features/home/home_screen.dart`
- Modify: `lib/features/home/pic_home_screen.dart`
- Modify: `lib/features/auth/login_screen.dart`
- Create: `test/widget_workspace_shell_test.dart`

**Interfaces:**
- App shell receives `MgrsWorkspace` and returns only that workspace’s destination list.
- PIC destination indices are `home`, `orders`, `invoices`, `profile`.
- Field destination indices are `scan`, `periodic`, `components`, `history`.
- Existing feature screens are passed the same `MaintenanceGateway` and `UserProfile`; no domain data is duplicated in the shell.

- [ ] **Step 1: Write shell isolation tests**

```dart
testWidgets('PIC shell does not expose field navigation', (tester) async {
  await tester.pumpWidget(testShell(user: picUser, workspace: MgrsWorkspace.pic));
  expect(find.text('Orderan'), findsOneWidget);
  expect(find.text('Invoice'), findsOneWidget);
  expect(find.text('Berkala'), findsNothing);
  expect(find.text('Komponen'), findsNothing);
});

testWidgets('Admin switcher exposes exactly two workspaces', (tester) async {
  await tester.pumpWidget(testShell(user: adminUser, workspace: MgrsWorkspace.pic));
  await tester.tap(find.text('PIC MGRS'));
  await tester.pumpAndSettle();
  expect(find.text('PIC MGRS'), findsOneWidget);
  expect(find.text('Tim Lapangan'), findsOneWidget);
  expect(find.text('Tim Service'), findsNothing);
});
```

- [ ] **Step 2: Implement shell routing and startup defaults**

Remove the old single list of mixed tabs and route each workspace to its own destination list. On workspace switch, reset selected index to the new workspace landing destination. Preserve `sessionRevision`, logout, lifecycle reload, and `MaintenanceGateway` injection.

- [ ] **Step 3: Migrate landing screens**

Make `PicHomeScreen` the PIC landing surface and simplify `HomeScreen` into the Tim Lapangan landing/scan entry or remove it if the shell directly hosts `ScanScreen`. Delete current bento metrics, invented “live” claims, avatar assumptions, and decorative painters. Keep only values returned by gateway calls and explicit loading/empty/error states.

- [ ] **Step 4: Run shell tests**

Run: `flutter test test/widget_workspace_shell_test.dart`
Expected: PASS; PIC has no field destinations, field has no invoice destination, Admin switcher has exactly two choices.

- [ ] **Step 5: Commit**

```bash
git add lib/app/app.dart lib/features/home lib/features/auth/login_screen.dart test/widget_workspace_shell_test.dart
git commit -m "feat: split app into role-aware workspaces"
```

### Task 4: Rebuild PIC MGRS order and invoice surfaces

**Files:**
- Modify: `lib/features/home/pic_home_screen.dart`
- Modify: `lib/features/schedule/upcoming_orders_screen.dart`
- Modify: `lib/features/schedule/order_detail_screen.dart`
- Modify: `lib/features/schedule/create_order_screen.dart`
- Modify: `lib/features/schedule/unit_allocation_card.dart`
- Modify: `lib/features/schedule/component_picker_sheet.dart`
- Modify: `lib/features/invoices/invoice_list_screen.dart`
- Modify: `lib/features/invoices/create_invoice_dialog.dart`
- Modify: `lib/features/invoices/invoice_builder_dialog.dart`
- Modify: `lib/features/invoices/invoice_adjustment_editor.dart`
- Modify: `lib/features/invoices/quick_payment_dialog.dart`
- Create: `test/widget_pic_workspace_test.dart`

**Interfaces:**
- Order and invoice widgets consume existing `OrderanSewa` and `InvoiceRecord` models.
- No Tim Lapangan primary navigation appears in PIC screens.
- A field-status context link may open a read-only relevant context, but it must not add maintenance navigation to PIC.

- [ ] **Step 1: Write tests for real-state PIC rendering**

```dart
testWidgets('PIC empty order state is explicit', (tester) async {
  await tester.pumpWidget(picOrdersWithData(const []));
  await tester.pumpAndSettle();
  expect(find.text('Belum ada orderan'), findsOneWidget);
  expect(find.text('24 mesin aktif dipantau'), findsNothing);
});

testWidgets('invoice controls remain at least 48dp', (tester) async {
  await tester.pumpWidget(picInvoiceWithOneRecord());
  final delete = find.byTooltip('Hapus invoice');
  expect(tester.getSize(delete).shortestSide, greaterThanOrEqualTo(48));
});
```

- [ ] **Step 2: Migrate order surfaces to shared primitives**

Replace custom decorative cards with typography-led sections: current context, orders needing attention, order detail, allocation action, and invoice entry. Keep gateway calls and order models intact. Preserve order creation/allocation behavior; only change presentation, routing, and explicit state handling.

- [ ] **Step 3: Migrate invoice surfaces**

Keep create, builder, payment, adjustment, and delete flows. Replace local fake pagination delays with the gateway’s actual loading contract where available; otherwise retain behavior but expose the state honestly and document the boundary in code comments only where needed. Ensure destructive actions use 48dp controls, confirmation copy, disabled saving state, and error retry.

- [ ] **Step 4: Run focused PIC tests**

Run: `flutter test test/widget_pic_workspace_test.dart`
Expected: PASS for empty/loaded/error invoice/order states and target sizes.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/pic_home_screen.dart lib/features/schedule lib/features/invoices test/widget_pic_workspace_test.dart
git commit -m "feat: redesign pic order and invoice workspace"
```

### Task 5: Rebuild Tim Lapangan scanner and component entry

**Files:**
- Modify: `lib/features/scan/scan_screen.dart`
- Modify: `lib/features/components/asset_catalog_screen.dart`
- Modify: `lib/features/components/component_detail_screen.dart`
- Modify: `lib/features/components/component.dart`
- Create: `test/widget_field_entry_test.dart`

**Interfaces:**
- Scanner continues using `MobileScannerController` and existing gateway lookup.
- Component detail remains the source of contextual `Catat Pemeriksaan` and `Catat Servis` actions.
- Field workspace never exposes invoice as a destination.

- [ ] **Step 1: Write scanner behavior tests**

```dart
testWidgets('manual code entry remains available when camera is unavailable', (tester) async {
  await tester.pumpWidget(scanWithCameraFailure());
  await tester.pumpAndSettle();
  expect(find.text('Masukkan kode manual'), findsOneWidget);
  expect(find.byTooltip('Coba lagi'), findsOneWidget);
});

testWidgets('component detail exposes maintenance actions without recording on open', (tester) async {
  final gateway = RecordingGateway(component: sampleComponent);
  await tester.pumpWidget(componentDetail(gateway));
  await tester.pumpAndSettle();
  expect(find.text('Catat Pemeriksaan'), findsOneWidget);
  expect(find.text('Catat Servis'), findsOneWidget);
  expect(gateway.maintenanceWrites, isEmpty);
});
```

- [ ] **Step 2: Remove decorative scanner chrome**

Use a clear scanner entry card, native camera surface, manual code field, and explicit camera permission/error state. Remove focus/lens controls that are below target size or do not provide product value. Stop camera on result, route leave, pause, and dispose. Retain duplicate-frame protection.

- [ ] **Step 3: Rebuild catalog/detail hierarchy**

Use search/filter controls with visible labels, component identity card, condition summary, history preview, and contextual maintenance actions. Render missing values explicitly. Ensure all icon-only controls have tooltip/semantic labels and 48dp hit areas.

- [ ] **Step 4: Run focused field tests**

Run: `flutter test test/widget_field_entry_test.dart`
Expected: PASS; camera failure leaves manual lookup usable and opening detail performs no write.

- [ ] **Step 5: Commit**

```bash
git add lib/features/scan lib/features/components test/widget_field_entry_test.dart
git commit -m "feat: redesign field scan and component entry"
```

### Task 6: Correct maintenance forms and submission states

**Files:**
- Modify: `lib/features/maintenance/checking_screen.dart`
- Modify: `lib/features/maintenance/action_center_screen.dart`
- Modify: `lib/features/maintenance/submission_controller.dart`
- Modify: `lib/shared/mgrs_components.dart`
- Create: `test/widget_maintenance_forms_test.dart`

**Interfaces:**
- Existing `SubmissionController` states remain `idle`, `submitting`, `succeeded`, `conflict`, `uncertain`, `failed`.
- Forms call `SubmissionController.submit` with the existing command shape and never change actor identity.
- `SaveActionBar` consumes `locked`, `SubmissionState`, retry/recover callbacks, and form validity.

- [ ] **Step 1: Write tests that expose fabricated defaults**

```dart
testWidgets('checking form starts without condition or usability', (tester) async {
  await tester.pumpWidget(checkingForm());
  expect(find.byKey(const ValueKey('condition-empty')), findsOneWidget);
  expect(find.text('OK'), findsNothing);
  expect(find.text('Ya'), findsNothing);
});

testWidgets('service form starts empty and preserves input after failure', (tester) async {
  final gateway = FailingMaintenanceGateway();
  await tester.pumpWidget(serviceForm(gateway));
  await tester.enterText(find.byKey(const ValueKey('problem-field')), 'Pompa macet');
  await tester.tap(find.text('Simpan'));
  await tester.pumpAndSettle();
  expect(find.text('Pompa macet'), findsOneWidget);
  expect(find.text('Gagal menyimpan'), findsOneWidget);
});
```

- [ ] **Step 2: Remove default values and move examples into hints**

Initialize condition/usability as null. Initialize service problem/action/notes as empty. Add Indonesian hint text without writing hint values into the command. Require explicit review before save.

- [ ] **Step 3: Implement review/save/discard states**

Disable save while submitting/uncertain, preserve input on failed/uncertain results, show conflict with current data and review action, and show discard confirmation when dirty. Keep existing RPC names and idempotency request IDs unchanged.

- [ ] **Step 4: Run focused maintenance tests**

Run: `flutter test test/widget_maintenance_forms_test.dart`
Expected: PASS; no fabricated initial values, failed save preserves text, locked state blocks duplicate submit.

- [ ] **Step 5: Commit**

```bash
git add lib/features/maintenance lib/shared/mgrs_components.dart test/widget_maintenance_forms_test.dart
git commit -m "fix: make maintenance forms explicit and recoverable"
```

### Task 7: Rebuild periodic and history destinations

**Files:**
- Modify: `lib/features/schedule/schedule_screen.dart`
- Modify: `lib/features/history/history_screen.dart`
- Modify: `lib/features/history/history_detail_screen.dart`
- Modify: `lib/features/schedule/component_picker_sheet.dart`
- Create: `test/widget_periodic_history_test.dart`

**Interfaces:**
- Periodic task status remains separate from component condition.
- Existing schedule gateway calls and pagination cursor semantics remain unchanged.
- History list/detail uses the shared explicit state components and preserves event type, actor, timestamp, before/after values.

- [ ] **Step 1: Write boundary/state tests**

```dart
testWidgets('damaged component can be completed without showing healthy state', (tester) async {
  await tester.pumpWidget(periodicTask(condition: 'Rusak Berat', completed: true));
  expect(find.text('Selesai diperiksa'), findsOneWidget);
  expect(find.text('Kondisi baik'), findsNothing);
});

testWidgets('history empty state is distinct from loading', (tester) async {
  await tester.pumpWidget(historyWithData(const []));
  expect(find.text('Belum ada riwayat'), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsNothing);
});
```

- [ ] **Step 2: Migrate periodic screen**

Use period header, status summary, filters, task cards, and explicit pagination. Do not use a 30-day assumption or treat scan/detail as completion. Keep late status labels visible as text.

- [ ] **Step 3: Migrate history screens**

Use event cards and detail sections with server timestamps, actor, event type, before/after values, and missing-data placeholders. Add retry and permission states without inventing historical values.

- [ ] **Step 4: Run focused tests and commit**

Run: `flutter test test/widget_periodic_history_test.dart`
Expected: PASS.

```bash
git add lib/features/schedule/schedule_screen.dart lib/features/history lib/features/schedule/component_picker_sheet.dart test/widget_periodic_history_test.dart
git commit -m "feat: redesign periodic work and history destinations"
```

### Task 8: Resolve order/pasangan context and installation confirmation boundary

**Files:**
- Modify: `lib/features/schedule/order_detail_screen.dart`
- Modify: `lib/features/schedule/upcoming_orders_screen.dart`
- Modify: `lib/app/gateway.dart` only if an existing authorized read/write contract is confirmed
- Create: `lib/features/field/installation_confirmation_screen.dart` only if an authorized operation exists
- Create: `test/widget_installation_confirmation_test.dart`

**Interfaces:**
- Read context is available to Tim Lapangan without exposing PIC workspace navigation.
- Installation confirmation accepts `orderId`, `pasanganId`, and nullable `unitId` only when the authorized gateway contract supports those fields.
- UI must visibly distinguish order identity, pasangan context, selected unit, and “unit tidak dipilih”.

- [ ] **Step 1: Inspect existing gateway/model contracts before adding any write**

Search `gateway.dart`, order models, and Supabase service references for an existing authorized order/pasangan/installation operation. Do not add an RPC name or payload based only on the PRD. If no operation exists, implement only the read-only context card and a disabled/unavailable explanation.

- [ ] **Step 2: Write tests for the supported boundary**

If a write contract exists:

```dart
testWidgets('installation review shows explicit omitted unit', (tester) async {
  await tester.pumpWidget(installationConfirmation(unitId: null));
  expect(find.text('Unit tidak dipilih'), findsOneWidget);
  expect(find.text('Konfirmasi pemasangan'), findsOneWidget);
});
```

If no write contract exists:

```dart
testWidgets('installation confirmation is unavailable without backend contract', (tester) async {
  await tester.pumpWidget(orderContextWithoutInstallationContract());
  expect(find.text('Konfirmasi pemasangan belum tersedia'), findsOneWidget);
  expect(find.text('Simpan'), findsNothing);
});
```

- [ ] **Step 3: Implement only the verified path**

For a verified operation, require explicit review and nullable unit selection; disable submit during saving and map success/conflict/failure/uncertain states. For an unverified operation, do not create a fake save button, fake status, or local-only success.

- [ ] **Step 4: Run focused test and commit**

Run: `flutter test test/widget_installation_confirmation_test.dart`
Expected: PASS for the verified or explicit unavailable boundary.

```bash
git add lib/features/schedule lib/features/field test/widget_installation_confirmation_test.dart lib/app/gateway.dart
git commit -m "feat: expose verified field installation context"
```

### Task 9: Remove obsolete navigation and finish responsive accessibility pass

**Files:**
- Modify: all migrated files from Tasks 2–8
- Delete: `lib/shared/bottom_nav_bar.dart` after references reach zero
- Modify: `android/app/src/main/AndroidManifest.xml` only if required for verified edge-to-edge/IME behavior
- Create: `test/widget_accessibility_layout_test.dart`

**Interfaces:**
- No caller imports `bottom_nav_bar.dart`.
- All destinations use `MGRSAppShell` and shared Material primitives.
- No icon-only control lacks a semantic label.

- [ ] **Step 1: Write accessibility/layout tests**

```dart
testWidgets('expanded shell uses rail and compact shell uses navigation bar', (tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  await tester.pumpWidget(fieldShell());
  expect(find.byType(NavigationBar), findsOneWidget);

  await tester.binding.setSurfaceSize(const Size(1200, 800));
  await tester.pumpWidget(fieldShell());
  expect(find.byType(NavigationRail), findsOneWidget);
});

testWidgets('large text keeps primary action visible', (tester) async {
  await tester.pumpWidget(MediaQuery(
    data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
    child: fieldDetailScreen(),
  ));
  expect(find.text('Catat Pemeriksaan'), findsOneWidget);
});
```

- [ ] **Step 2: Remove obsolete custom navigation**

Delete `bottom_nav_bar.dart` only after a repository search confirms zero imports/references. Remove obsolete `AdminAppMode`, old mixed-tab comments, liquid-glass painters, drag-to-scrub state, and dead callbacks.

- [ ] **Step 3: Verify semantics, target sizes, and theme modes**

Use `SemanticsTester` for navigation/workspace labels; inspect every icon-only action with `Tooltip`; verify 48dp bounds; pump light and dark themes; pump portrait, landscape, compact, expanded, and 1.3 text scale.

- [ ] **Step 4: Run focused accessibility test and commit**

Run: `flutter test test/widget_accessibility_layout_test.dart`
Expected: PASS with no clipped primary controls.

```bash
git add lib android test/widget_accessibility_layout_test.dart
git rm lib/shared/bottom_nav_bar.dart
git commit -m "refactor: remove obsolete navigation chrome"
```

### Task 10: Final verification and implementation handoff

**Files:**
- Modify: `DESIGN.md` only for verified shipped deviations
- Modify: `PRD.md` only for verified contract/status updates
- Modify: `docs/superpowers/specs/2026-09-12-workspace-ui-ux-redesign-design.md` only for verified implementation boundary notes

- [ ] **Step 1: Run focused regression tests for changed contracts**

Run:

```bash
flutter test test/unit_workspace_access_test.dart test/widget_shared_components_test.dart test/widget_workspace_shell_test.dart test/widget_pic_workspace_test.dart test/widget_field_entry_test.dart test/widget_maintenance_forms_test.dart test/widget_periodic_history_test.dart test/widget_installation_confirmation_test.dart test/widget_accessibility_layout_test.dart
```

Expected: all listed tests pass.

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze`
Expected: no new diagnostics in `lib/`; existing unrelated test warnings must be separately identified rather than hidden.

- [ ] **Step 3: Build the Android artifact**

Run: `flutter build apk --debug`
Expected: debug APK builds successfully.

- [ ] **Step 4: Run Android smoke scenario**

Launch the debug APK on an Android emulator and verify:

1. Admin login shows exactly `PIC MGRS` and `Tim Lapangan` workspace choices.
2. PIC MGRS lands on Orderan and does not show field navigation or invoice outside PIC.
3. Tim Lapangan lands on Scan, manual fallback works, and camera stops after leaving.
4. Component detail does not write on open; maintenance actions open forms.
5. Checking/service forms have no fabricated values; failed save preserves input.
6. Periodic task completion does not imply healthy condition.
7. Relevant order/pasangan context shows installation boundary and never silently selects a unit.
8. Dark mode, 1.3 font scale, landscape, system Back, and keyboard do not hide primary actions.

- [ ] **Step 5: Run final anti-slop gate**

Review every changed screen against the purpose test: remove any decorative effect without a product purpose; remove dead controls; confirm all copy describes real data; confirm empty/loading/error/conflict/retry states are perceivable; confirm compact/medium/expanded layouts.

- [ ] **Step 6: Commit verified documentation only**

```bash
git add DESIGN.md PRD.md docs/superpowers/specs/2026-09-12-workspace-ui-ux-redesign-design.md
git commit -m "docs: record verified workspace redesign boundaries"
```

## Self-Review Checklist

- Product model covered: Tasks 1, 3, 4, 5, 8.
- Native Material adaptive navigation covered: Tasks 2, 3, 9.
- Apple reference and anti-slop purpose gate covered: Tasks 2, 4, 5, 9, 10.
- PIC MGRS order/invoice coverage: Task 4.
- Tim Lapangan scan/maintenance/periodic/component/history coverage: Tasks 5–7.
- Installation confirmation with optional unit and no fabricated backend: Task 8.
- Form defaults and recovery states: Task 6.
- Accessibility, dark mode, font scale, responsive behavior: Tasks 2, 9, 10.
- Existing auth, gateway, atomicity, idempotency, and conflict behavior: Tasks 1, 6, 8, 10.
- No implementation placeholders: every task names files, interfaces, test behavior, commands, and expected results.
- Backend uncertainty is handled as an explicit read-only/unavailable boundary, not a guessed RPC or local fake success.
