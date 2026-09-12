import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/gateway.dart';

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
