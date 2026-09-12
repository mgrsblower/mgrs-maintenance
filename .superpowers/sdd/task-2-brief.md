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

