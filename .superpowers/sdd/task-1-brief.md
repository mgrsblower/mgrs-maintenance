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
