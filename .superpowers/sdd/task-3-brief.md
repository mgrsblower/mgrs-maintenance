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

